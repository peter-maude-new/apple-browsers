//
//  AutomationServer.swift
//  DuckDuckGo
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
import WebKit

extension Logger {
    static var automationServer = { Logger(subsystem: Bundle.main.bundleIdentifier ?? "DuckDuckGo", category: "Automation Server") }()
}

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

enum AutomationServerError: Error {
    case noWindow
    case invalidWindowHandle
    case tabNotFound
    case jsonEncodingFailed
    case unsupportedOSVersion
    case unknownMethod
    case invalidURL
    case scriptExecutionFailed
}

typealias ConnectionResult = Result<String, AutomationServerError>
typealias ConnectionResultWithPath = (String, ConnectionResult)

actor PerConnectionQueue {
    private var isProcessing = false
    private var queue: [Data] = []

    func enqueue(
        content: Data,
        processor: @escaping (Data) async -> ConnectionResultWithPath,
        responder: @escaping (ConnectionResultWithPath) -> Void
    ) async {
        queue.append(content)

        guard !isProcessing else { return } // Prevent duplicate loops
        isProcessing = true

        while !queue.isEmpty {
            let request = queue.removeFirst()
            let connectionResultWithPath = await processor(request) // Process request
            responder(connectionResultWithPath)
        }

        isProcessing = false
    }
}

func encodeToJsonString(_ value: Any?) -> String {
    do {
        guard let value else {
            return "null"
        }
        if let encodableValue = value as? Encodable {
            let jsonData = try JSONEncoder().encode(AnyEncodable(encodableValue))
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } else if JSONSerialization.isValidJSONObject(value) {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } else {
            Logger.automationServer.error("Have value that can't be encoded: \(String(describing: value))")
            return "{\"error\": \"Value is not a valid JSON object\"}"
        }
    } catch {
        Logger.automationServer.error("Failed to encode: \(String(describing: value))")
        return "{\"error\": \"JSON encoding failed: \(error)\"}"
    }
}

@MainActor
final class AutomationServer {
    let listener: NWListener
    let windowControllersManager: WindowControllersManager
    // Store queues per connection
    var connectionQueues: [ObjectIdentifier: PerConnectionQueue] = [:]

    init(windowControllersManager: WindowControllersManager, port: Int?) {
        let port = port ?? 8788
        self.windowControllersManager = windowControllersManager
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
        // Output server started
        Logger.automationServer.info("Automation server started on port \(port)")
    }

    private var activeMainViewController: MainViewController? {
        windowControllersManager.lastKeyMainWindowController?.mainViewController
    }

    private var activeTabCollectionViewModel: TabCollectionViewModel? {
        activeMainViewController?.tabCollectionViewModel
    }

    private var currentTab: Tab? {
        activeTabCollectionViewModel?.selectedTab
    }

    private var currentWebView: WKWebView? {
        currentTab?.webView
    }

    func receive(from connection: NWConnection) {
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

    func processContentWhenReady(content: Data) async -> ConnectionResultWithPath {
        // Check if loading
        while currentTab?.isLoading ?? false {
            Logger.automationServer.info("Still loading, waiting...")
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }

        // Proceed when loading is complete
        return await handleConnection(content)
    }

    func getQueryStringParameter(url: URLComponents, param: String) -> String? {
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    func handleConnection(_ content: Data) async -> (String, ConnectionResult) {
        Logger.automationServer.info("Handling request:")
        let stringContent = String(bytes: content, encoding: .utf8) ?? ""
        // Log first line of string:
        if let firstLine = stringContent.components(separatedBy: CharacterSet.newlines).first {
            Logger.automationServer.info("First line: \(firstLine)")
        }

        // Get url parameter from path
        // GET / HTTP/1.1
        let path = /^(GET|POST) (\/[^ ]*) HTTP/
        guard let match = stringContent.firstMatch(of: path) else {
            return ("unknown", .failure(.unknownMethod))
        }
        Logger.automationServer.info("Path: \(match.2)")
        // Convert the path into a URL object
        guard let url = URLComponents(string: String(match.2)) else {
            Logger.automationServer.error("Invalid URL: \(match.2)")
            return ("unknown", .failure(.invalidURL))
        }
        return (url.path, await handlePath(url))
    }

    func handlePath(_ url: URLComponents) async -> ConnectionResult {
        return switch url.path {
        case "/navigate":
            self.navigate(url: url)
        case "/execute":
            await self.execute(url: url)
        case "/getUrl":
            .success(self.currentWebView?.url?.absoluteString ?? "")
        case "/getWindowHandles":
            self.getWindowHandles(url: url)
        case "/closeWindow":
            self.closeWindow(url: url)
        case "/switchToWindow":
            self.switchToWindow(url: url)
        case "/newWindow":
            self.newWindow(url: url)
        case "/getWindowHandle":
            self.getWindowHandle(url: url)
        default:
            .failure(.unknownMethod)
        }
    }

    func navigate(url: URLComponents) -> ConnectionResult {
        let navigateUrlString = getQueryStringParameter(url: url, param: "url") ?? ""
        guard let navigateUrl = URL(string: navigateUrlString) else {
            return .failure(.invalidURL)
        }
        currentTab?.setContent(.contentFromURL(navigateUrl, source: .userEntered(navigateUrlString, downloadRequested: false)))
        return .success("done")
    }

    func execute(url: URLComponents) async -> ConnectionResult {
        let script = getQueryStringParameter(url: url, param: "script") ?? ""
        var args: [String: String] = [:]
        // json decode args if present
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
        return await self.executeScript(script, args: args)
    }

    func getWindowHandle(url: URLComponents) -> ConnectionResult {
        guard let tab = currentTab else {
            return .failure(.noWindow)
        }
        return .success(tab.uuid)
    }

    func getWindowHandles(url: URLComponents) -> ConnectionResult {
        var handles: [String] = []

        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel
            for tab in tabCollectionViewModel.tabs {
                handles.append(tab.uuid)
            }
        }

        if let jsonData = try? JSONEncoder().encode(handles),
           let jsonString = String(data: jsonData, encoding: .utf8) {
           return .success(jsonString)
        } else {
            return .failure(.jsonEncodingFailed)
        }
    }

    func closeWindow(url: URLComponents) -> ConnectionResult {
        guard let tab = currentTab,
              let tabCollectionViewModel = activeTabCollectionViewModel else {
            return .failure(.noWindow)
        }
        tabCollectionViewModel.remove(at: .unpinned(tabCollectionViewModel.tabCollection.tabs.firstIndex(of: tab) ?? 0))
        return .success("done")
    }

    func switchToWindow(url: URLComponents) -> ConnectionResult {
        guard let handleString = getQueryStringParameter(url: url, param: "handle") else {
            return .failure(.invalidWindowHandle)
        }
        Logger.automationServer.info("Switch to window \(handleString)")

        // Search for the tab across all windows
        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel
            if let index = tabCollectionViewModel.tabCollection.tabs.firstIndex(where: { $0.uuid == handleString }) {
                // Found the tab - make this window key and select the tab
                windowController.window?.makeKeyAndOrderFront(nil)
                tabCollectionViewModel.select(at: .unpinned(index))
                return .success("done")
            }
        }

        return .failure(.tabNotFound)
    }

    func newWindow(url: URLComponents) -> ConnectionResult {
        guard let tabCollectionViewModel = activeTabCollectionViewModel else {
            return .failure(.noWindow)
        }

        tabCollectionViewModel.appendNewTab(with: .newtab, selected: true)

        guard let newTab = tabCollectionViewModel.selectedTab else {
            return .failure(.noWindow)
        }

        // Response {handle: "", type: "tab"}
        let response: [String: String] = ["handle": newTab.uuid, "type": "tab"]
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return .success(jsonString)
        } else {
            return .failure(.jsonEncodingFailed)
        }
    }

    func executeScript(_ script: String, args: [String: Any]) async -> ConnectionResult {
        Logger.automationServer.info("Script: \(script), Args: \(args)")

        guard let webView = currentWebView else {
            return .failure(.noWindow)
        }

        do {
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: args,
                in: nil,
                contentWorld: .page
            )
            Logger.automationServer.info("Have result to execute script: \(String(describing: result))")
            let jsonString = encodeToJsonString(result)
            return .success(jsonString)
        } catch {
            Logger.automationServer.error("Error executing script: \(error)")
            return .failure(.scriptExecutionFailed)
        }
    }

    func responseToString(_ connectionResultWithPath: ConnectionResultWithPath) -> String {
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

    func respond(on connection: NWConnection, connectionResultWithPath: ConnectionResultWithPath) {
        let (requestPath, responseData) = connectionResultWithPath
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
}

