//
//  WebDriverServer.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if DEBUG

import Foundation
import Network
import os.log

/// HTTP server implementing the W3C WebDriver protocol
/// Only available in DEBUG builds for security
@MainActor
final class WebDriverServer {

    // MARK: - Properties

    private let port: UInt16
    private let router: WebDriverRouter
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: WebDriverConnection] = [:]

    private(set) var isRunning: Bool = false

    // MARK: - Initialization

    init(port: UInt16 = 4444, sessionManager: WebDriverSessionManager) {
        self.port = port
        self.router = WebDriverRouter(sessionManager: sessionManager)
    }

    // MARK: - Server Lifecycle

    func start() throws {
        guard !isRunning else {
            Logger.webDriver.warning("WebDriver server already running")
            return
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw WebDriverServerError.invalidPort(port)
        }

        do {
            listener = try NWListener(using: parameters, on: nwPort)
        } catch {
            throw WebDriverServerError.failedToCreateListener(error)
        }

        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleListenerStateUpdate(state)
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.handleNewConnection(connection)
            }
        }

        listener?.start(queue: .main)
        isRunning = true
        Logger.webDriver.info("WebDriver server started on port \(self.port)")
    }

    func stop() {
        guard isRunning else { return }

        listener?.cancel()
        listener = nil

        for connection in connections.values {
            connection.cancel()
        }
        connections.removeAll()

        isRunning = false
        Logger.webDriver.info("WebDriver server stopped")
    }

    // MARK: - Connection Handling

    private func handleListenerStateUpdate(_ state: NWListener.State) {
        switch state {
        case .ready:
            Logger.webDriver.info("WebDriver server ready on port \(self.port)")
        case .failed(let error):
            Logger.webDriver.error("WebDriver server failed: \(error.localizedDescription)")
            isRunning = false
        case .cancelled:
            Logger.webDriver.info("WebDriver server cancelled")
            isRunning = false
        default:
            break
        }
    }

    private func handleNewConnection(_ nwConnection: NWConnection) {
        let connection = WebDriverConnection(connection: nwConnection, router: router)
        let id = ObjectIdentifier(connection)
        connections[id] = connection

        connection.onClose = { [weak self] in
            Task { @MainActor in
                self?.connections.removeValue(forKey: id)
            }
        }

        connection.start()
    }
}

// MARK: - WebDriverConnection

/// Handles a single HTTP connection
@MainActor
final class WebDriverConnection {
    private let connection: NWConnection
    private let router: WebDriverRouter
    var onClose: (() -> Void)?

    init(connection: NWConnection, router: WebDriverRouter) {
        self.connection = connection
        self.router = router
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleStateUpdate(state)
            }
        }
        connection.start(queue: .main)
    }

    func cancel() {
        connection.cancel()
    }

    private func handleStateUpdate(_ state: NWConnection.State) {
        switch state {
        case .ready:
            receiveRequest()
        case .failed(let error):
            Logger.webDriver.error("Connection failed: \(error.localizedDescription)")
            cleanup()
        case .cancelled:
            cleanup()
        default:
            break
        }
    }

    private func cleanup() {
        onClose?()
    }

    private func receiveRequest() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    Logger.webDriver.error("Receive error: \(error.localizedDescription)")
                    self.cleanup()
                    return
                }

                if let data = data, !data.isEmpty {
                    self.handleReceivedData(data)
                }

                if isComplete {
                    self.cleanup()
                }
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        guard let request = parseHTTPRequest(from: data) else {
            sendErrorResponse(statusCode: 400, message: "Bad Request")
            return
        }

        Task {
            let response = await router.route(request)
            sendHTTPResponse(response)
        }
    }

    private func parseHTTPRequest(from data: Data) -> HTTPRequest? {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }

        let requestParts = requestLine.split(separator: " ", maxSplits: 2)
        guard requestParts.count >= 2,
              let method = HTTPMethod(rawValue: String(requestParts[0])) else {
            return nil
        }

        let path = String(requestParts[1])

        // Find the body (after the empty line)
        var body: Data?
        if let emptyLineIndex = lines.firstIndex(of: "") {
            let bodyLines = lines.dropFirst(emptyLineIndex + 1)
            let bodyString = bodyLines.joined(separator: "\r\n")
            if !bodyString.isEmpty {
                body = bodyString.data(using: .utf8)
            }
        }

        return HTTPRequest(method: method, path: path, body: body)
    }

    private func sendHTTPResponse(_ response: HTTPResponse) {
        var responseString = "HTTP/1.1 \(response.statusCode) \(statusMessage(for: response.statusCode))\r\n"
        for (key, value) in response.headers {
            responseString += "\(key): \(value)\r\n"
        }
        responseString += "Content-Length: \(response.body.count)\r\n"
        responseString += "Connection: close\r\n"
        responseString += "\r\n"

        var responseData = responseString.data(using: .utf8) ?? Data()
        responseData.append(response.body)

        connection.send(content: responseData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                Logger.webDriver.error("Send error: \(error.localizedDescription)")
            }
            self?.connection.cancel()
        })
    }

    private func sendErrorResponse(statusCode: Int, message: String) {
        let response = HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "text/plain"],
            body: message.data(using: .utf8) ?? Data()
        )
        sendHTTPResponse(response)
    }

    private func statusMessage(for code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

// MARK: - Errors

enum WebDriverServerError: Error, LocalizedError {
    case invalidPort(UInt16)
    case failedToCreateListener(Error)

    var errorDescription: String? {
        switch self {
        case .invalidPort(let port):
            return "Invalid port: \(port)"
        case .failedToCreateListener(let error):
            return "Failed to create listener: \(error.localizedDescription)"
        }
    }
}

// MARK: - Logger Extension

extension Logger {
    static let webDriver = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.duckduckgo.macos.browser",
                                  category: "WebDriver")
}

#endif
