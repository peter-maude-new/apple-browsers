//
//  AutomationServerCore.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
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

import Foundation
import Network
import os.log

public extension Logger {
    static var automationServer = { Logger(subsystem: Bundle.main.bundleIdentifier ?? "DuckDuckGo", category: "Automation Server") }()
}

public typealias ConnectionResult = Result<String, AutomationServerError>
public typealias ConnectionResultWithPath = (String, ConnectionResult)

/// Actor for managing per-connection request queues to ensure sequential processing
public actor PerConnectionQueue {
    private var isProcessing = false
    private var queue: [Data] = []

    public init() {}

    public func enqueue(
        content: Data,
        processor: @escaping (Data) async -> ConnectionResultWithPath,
        responder: @escaping (ConnectionResultWithPath) -> Void
    ) async {
        queue.append(content)

        guard !isProcessing else { return }
        isProcessing = true

        while !queue.isEmpty {
            let request = queue.removeFirst()
            let connectionResultWithPath = await processor(request)
            responder(connectionResultWithPath)
        }

        isProcessing = false
    }
}

/// Core automation server implementation that handles HTTP connections and routes requests.
/// Uses a BrowserAutomationProvider for platform-specific browser operations.
@MainActor
public final class AutomationServerCore {
    public let listener: NWListener
    public let provider: BrowserAutomationProvider
    public var connectionQueues: [ObjectIdentifier: PerConnectionQueue] = [:]

    public init(provider: BrowserAutomationProvider, port: Int?) {
        let port = port ?? 8788
        self.provider = provider
        Logger.automationServer.info("Starting automation server on port \(port)")
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: UInt16(port)))
        } catch {
            Logger.automationServer.error("Failed to start listener: \(error)")
            fatalError("Failed to start automation listener: \(error)")
        }
        listener.newConnectionHandler = { connection in
            Task { @MainActor in
                connection.start(queue: .main)
                self.receive(from: connection)
            }
        }

        listener.start(queue: .main)
        Logger.automationServer.info("Automation server started on port \(port)")
    }

    public func receive(from connection: NWConnection) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: connection.maximumDatagramSize
        ) { (content: Data?, _: NWConnection.ContentContext?, isComplete: Bool, error: NWError?) in
            guard connection.state == .ready else {
                Logger.automationServer.info("Receive aborted as connection is no longer ready.")
                return
            }
            Logger.automationServer.info("Received request - Content: \(String(describing: content)) isComplete: \(isComplete) Error: \(String(describing: error))")

            if let error {
                Logger.automationServer.error("Error in request: \(error)")
                return
            }

            if let content {
                Logger.automationServer.info("Handling content")
                let queue = self.connectionQueues[ObjectIdentifier(connection)] ?? PerConnectionQueue()
                self.connectionQueues[ObjectIdentifier(connection)] = queue
                Task { @MainActor in
                    await queue.enqueue(
                        content: content,
                        processor: { data in
                            return await self.processContentWhenReady(content: data)
                        },
                        responder: { connectionResultWithPath in
                            self.respond(on: connection, connectionResultWithPath: connectionResultWithPath)
                        })
                }
            }
            if isComplete {
                Logger.automationServer.info("Connection marked complete. Cancelling connection.")
                connection.cancel()
                return
            }

            if connection.state == .ready {
                Logger.automationServer.info("Handling not complete, continuing receive.")
                Task { @MainActor in
                    self.receive(from: connection)
                }
            } else {
                Logger.automationServer.info("Connection is no longer ready, stopping receive.")
            }
        }
    }

    public func processContentWhenReady(content: Data) async -> ConnectionResultWithPath {
        while provider.isLoading {
            Logger.automationServer.info("Still loading, waiting...")
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        return await handleConnection(content)
    }

    public func handleConnection(_ content: Data) async -> ConnectionResultWithPath {
        Logger.automationServer.info("Handling request:")
        let stringContent = String(bytes: content, encoding: .utf8) ?? ""

        if let firstLine = stringContent.components(separatedBy: CharacterSet.newlines).first {
            Logger.automationServer.info("First line: \(firstLine)")
        }

        guard let pathString = extractPath(from: stringContent) else {
            return ("unknown", .failure(.unknownMethod))
        }
        Logger.automationServer.info("Path: \(pathString)")

        guard let url = URLComponents(string: pathString) else {
            Logger.automationServer.error("Invalid URL: \(pathString)")
            return ("unknown", .failure(.invalidURL))
        }
        return (url.path, await handlePath(url))
    }

    private func extractPath(from httpRequest: String) -> String? {
        let pattern = "^(GET|POST) (\\/[^ ]*) HTTP"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: httpRequest, options: [], range: NSRange(httpRequest.startIndex..., in: httpRequest)),
              let pathRange = Range(match.range(at: 2), in: httpRequest) else {
            return nil
        }
        return String(httpRequest[pathRange])
    }

    public func handlePath(_ url: URLComponents) async -> ConnectionResult {
        switch url.path {
        case "/navigate":
            return navigate(url: url)
        case "/execute":
            return await execute(url: url)
        case "/getUrl":
            return .success(provider.currentURL?.absoluteString ?? "")
        case "/getWindowHandles":
            return getWindowHandles(url: url)
        case "/closeWindow":
            return closeWindow(url: url)
        case "/switchToWindow":
            return switchToWindow(url: url)
        case "/newWindow":
            return newWindow(url: url)
        case "/getWindowHandle":
            return getWindowHandle(url: url)
        case "/shutdown":
            return shutdown()
        case "/screenshot":
            return await takeScreenshot(url: url)
        case "/contentBlockerReady":
            return contentBlockerReady()
        default:
            return .failure(.unknownMethod)
        }
    }

    /// Cleanly shut down the automation server and terminate the app.
    /// This allows the webdriver to close the app without triggering a crash dialog.
    public func shutdown() -> ConnectionResult {
        Logger.automationServer.info("Shutdown requested - stopping automation server and terminating app")

        // Cancel the listener to stop accepting new connections
        listener.cancel()

        // Clear connection queues
        connectionQueues.removeAll()

        Logger.automationServer.info("Automation server shut down, scheduling app termination")

        // Schedule app termination after a short delay to allow this response to be sent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Logger.automationServer.info("Terminating app via exit(0)")
            // Use exit(0) for clean termination without crash dialogs
            // This is safe because we've already cleaned up the automation server
            exit(0)
        }

        return .success("shutdown")
    }

    // MARK: - Route Handlers

    public func navigate(url: URLComponents) -> ConnectionResult {
        let navigateUrlString = getQueryStringParameter(url: url, param: "url") ?? ""
        guard let navigateUrl = URL(string: navigateUrlString) else {
            return .failure(.invalidURL)
        }
        provider.navigate(to: navigateUrl)
        return .success("done")
    }

    public func execute(url: URLComponents) async -> ConnectionResult {
        let script = getQueryStringParameter(url: url, param: "script") ?? ""
        var args: [String: String] = [:]

        if let argsString = getQueryStringParameter(url: url, param: "args") {
            guard let argsData = argsString.data(using: .utf8) else {
                return .failure(.jsonEncodingFailed)
            }
            do {
                let jsonDecoder = JSONDecoder()
                args = try jsonDecoder.decode([String: String].self, from: argsData)
            } catch {
                Logger.automationServer.error("Failed to decode args: \(error)")
                return .failure(.jsonEncodingFailed)
            }
        }
        return await executeScript(script, args: args)
    }

    public func getWindowHandle(url: URLComponents) -> ConnectionResult {
        guard let handle = provider.currentTabHandle else {
            return .failure(.noWindow)
        }
        return .success(handle)
    }

    public func getWindowHandles(url: URLComponents) -> ConnectionResult {
        let handles = provider.getAllTabHandles()

        if let jsonData = try? JSONEncoder().encode(handles),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return .success(jsonString)
        } else {
            return .failure(.jsonEncodingFailed)
        }
    }

    public func closeWindow(url: URLComponents) -> ConnectionResult {
        guard provider.currentTabHandle != nil else {
            return .failure(.noWindow)
        }
        provider.closeCurrentTab()
        return .success("done")
    }

    public func switchToWindow(url: URLComponents) -> ConnectionResult {
        guard let handleString = getQueryStringParameter(url: url, param: "handle") else {
            return .failure(.invalidWindowHandle)
        }
        Logger.automationServer.info("Switch to window \(handleString)")

        if provider.switchToTab(handle: handleString) {
            return .success("done")
        }
        return .failure(.tabNotFound)
    }

    public func newWindow(url: URLComponents) -> ConnectionResult {
        guard let handle = provider.newTab() else {
            return .failure(.noWindow)
        }

        let response: [String: String] = ["handle": handle, "type": "tab"]
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return .success(jsonString)
        } else {
            return .failure(.jsonEncodingFailed)
        }
    }

    public func takeScreenshot(url: URLComponents) async -> ConnectionResult {
        // Parse optional rect parameter for element screenshots
        var rect: CGRect?
        if let rectString = getQueryStringParameter(url: url, param: "rect"),
           let rectData = rectString.data(using: .utf8),
           let rectDict = try? JSONDecoder().decode([String: CGFloat].self, from: rectData),
           let x = rectDict["x"],
           let y = rectDict["y"],
           let width = rectDict["width"],
           let height = rectDict["height"] {
            rect = CGRect(x: x, y: y, width: width, height: height)
        }

        guard let screenshotData = await provider.takeScreenshot(rect: rect) else {
            return .failure(.screenshotFailed)
        }
        return .success(screenshotData.base64EncodedString())
    }

    /// Check if the content blocker rules have been compiled and are ready
    /// WebDriver should wait for this before considering the browser ready for testing
    public func contentBlockerReady() -> ConnectionResult {
        let isReady = provider.isContentBlockerReady
        Logger.automationServer.info("Content blocker ready: \(isReady)")
        return .success(isReady ? "true" : "false")
    }

    public func executeScript(_ script: String, args: [String: Any]) async -> ConnectionResult {
        Logger.automationServer.info("Script: \(script), Args: \(args)")

        let result = await provider.executeScript(script, args: args)

        switch result {
        case .success(let value):
            Logger.automationServer.info("Have result to execute script: \(String(describing: value))")
            let jsonString = encodeToJsonString(value)
            return .success(jsonString)
        case .failure(let error):
            Logger.automationServer.error("Error executing script: \(error)")
            return .failure(.scriptExecutionFailed)
        }
    }

    // MARK: - Response Handling

    public func responseToString(_ connectionResultWithPath: ConnectionResultWithPath) -> String {
        let (requestPath, responseData) = connectionResultWithPath
        struct Response: Codable {
            var message: String
            var requestPath: String
        }
        var errorCode = 200
        let responseStruct: Response
        switch responseData {
        case .success(let result):
            responseStruct = Response(message: result, requestPath: requestPath)
        case .failure(let error):
            errorCode = 400
            Logger.automationServer.error("Connection Handling Error: \(error) path: \(requestPath)")
            responseStruct = Response(message: encodeToJsonString(["error": error.localizedDescription]), requestPath: requestPath)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        var responseString = ""
        do {
            let data = try encoder.encode(responseStruct)
            responseString = String(data: data, encoding: .utf8) ?? ""
        } catch {
            Logger.automationServer.error("Got error encoding JSON: \(error)")
        }
        let responseHeader = """
        HTTP/1.1 \(errorCode) OK
        Content-Type: application/json
        Connection: close

        """
        return responseHeader + "\r\n" + responseString
    }

    public func respond(on connection: NWConnection, connectionResultWithPath: ConnectionResultWithPath) {
        let responseString = responseToString(connectionResultWithPath)
        connection.send(
            content: responseString.data(using: .utf8),
            completion: .contentProcessed({ error in
                if let error = error {
                    Logger.automationServer.error("Error sending response: \(error)")
                }
                connection.cancel()
            })
        )
    }

    // MARK: - Helpers

    public func getQueryStringParameter(url: URLComponents, param: String) -> String? {
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}
