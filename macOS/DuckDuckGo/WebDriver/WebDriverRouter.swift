//
//  WebDriverRouter.swift
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
import os.log

/// Routes incoming HTTP requests to appropriate WebDriver command handlers
@MainActor
final class WebDriverRouter {

    private let sessionManager: WebDriverSessionManager

    init(sessionManager: WebDriverSessionManager) {
        self.sessionManager = sessionManager
    }

    /// Route an HTTP request to the appropriate handler
    func route(_ request: HTTPRequest) async -> HTTPResponse {
        Logger.webDriver.debug("Request: \(request.method.rawValue) \(request.path)")

        do {
            return try await handleRequest(request)
        } catch let error as WebDriverError {
            Logger.webDriver.error("WebDriver error: \(error.message)")
            return HTTPResponse.error(error)
        } catch {
            Logger.webDriver.error("Unexpected error: \(error.localizedDescription)")
            return HTTPResponse.error(WebDriverError(.unknownError, message: error.localizedDescription))
        }
    }

    private func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let components = request.pathComponents

        // Root status endpoint
        if components.isEmpty || (components.count == 1 && components[0] == "status") {
            return try await handleStatus(request)
        }

        // Session endpoints
        guard components.first == "session" else {
            throw WebDriverError.unknownCommand(request.path)
        }

        // POST /session - Create new session
        if components.count == 1 && request.method == .POST {
            return try await handleNewSession(request)
        }

        // Remaining endpoints require a session ID
        guard components.count >= 2 else {
            throw WebDriverError.unknownCommand(request.path)
        }

        let sessionId = components[1]

        // DELETE /session/{sessionId} - Delete session
        if components.count == 2 && request.method == .DELETE {
            return try await handleDeleteSession(sessionId)
        }

        // GET /session/{sessionId} - Get session info (non-standard but useful)
        if components.count == 2 && request.method == .GET {
            return try await handleGetSession(sessionId)
        }

        // Route to session-specific commands
        guard components.count >= 3 else {
            throw WebDriverError.unknownCommand(request.path)
        }

        let session = try sessionManager.getSession(sessionId)
        let subCommand = components[2]

        switch subCommand {
        // Navigation
        case "url":
            return try await handleURL(request, session: session)
        case "title":
            return try await handleTitle(request, session: session)
        case "back":
            return try await handleBack(request, session: session)
        case "forward":
            return try await handleForward(request, session: session)
        case "refresh":
            return try await handleRefresh(request, session: session)

        // Timeouts
        case "timeouts":
            return try await handleTimeouts(request, session: session)

        // Window
        case "window":
            return try await handleWindow(request, session: session, components: Array(components.dropFirst(3)))

        // Elements
        case "element":
            return try await handleElement(request, session: session, components: Array(components.dropFirst(3)))
        case "elements":
            return try await handleElements(request, session: session)

        // Document
        case "source":
            return try await handleSource(request, session: session)
        case "execute":
            return try await handleExecute(request, session: session, components: Array(components.dropFirst(3)))

        // Screenshot
        case "screenshot":
            return try await handleScreenshot(request, session: session)

        // Cookies
        case "cookie":
            return try await handleCookie(request, session: session, components: Array(components.dropFirst(3)))

        // Actions
        case "actions":
            return try await handleActions(request, session: session)

        default:
            throw WebDriverError.unknownCommand(request.path)
        }
    }

    // MARK: - Status

    private func handleStatus(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard request.method == .GET else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        struct StatusResponse: Codable {
            let ready: Bool
            let message: String
        }

        return HTTPResponse.json(StatusResponse(
            ready: true,
            message: "DuckDuckGo WebDriver is ready"
        ))
    }

    // MARK: - Session Management

    private func handleNewSession(_ request: HTTPRequest) async throws -> HTTPResponse {
        let requestBody = try? request.decodeBody(as: NewSessionRequest.self)

        let capabilities = requestBody?.capabilities?.alwaysMatch
            ?? requestBody?.capabilities?.firstMatch?.first
            ?? requestBody?.desiredCapabilities
            ?? WebDriverCapabilities()

        let session = try await sessionManager.createSession(with: capabilities)

        let response = NewSessionResponse(
            sessionId: session.id,
            capabilities: session.capabilities
        )

        return HTTPResponse.json(response)
    }

    private func handleDeleteSession(_ sessionId: String) async throws -> HTTPResponse {
        try await sessionManager.deleteSession(sessionId)
        return HTTPResponse.null()
    }

    private func handleGetSession(_ sessionId: String) async throws -> HTTPResponse {
        let session = try sessionManager.getSession(sessionId)
        return HTTPResponse.json(session.capabilities)
    }

    // MARK: - Navigation

    private func handleURL(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        switch request.method {
        case .GET:
            let url = await session.getCurrentURL()
            return HTTPResponse.json(url ?? "")

        case .POST:
            let body = try request.decodeBody(as: NavigateRequest.self)
            guard let url = URL(string: body.url) else {
                throw WebDriverError.invalidArgument("Invalid URL: \(body.url)")
            }
            try await session.navigateTo(url)
            return HTTPResponse.null()

        default:
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }
    }

    private func handleTitle(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .GET else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        let title = await session.getTitle()
        return HTTPResponse.json(title)
    }

    private func handleBack(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .POST else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        await session.goBack()
        return HTTPResponse.null()
    }

    private func handleForward(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .POST else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        await session.goForward()
        return HTTPResponse.null()
    }

    private func handleRefresh(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .POST else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        await session.refresh()
        return HTTPResponse.null()
    }

    // MARK: - Timeouts

    private func handleTimeouts(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        switch request.method {
        case .GET:
            return HTTPResponse.json(session.timeouts)

        case .POST:
            let body = try request.decodeBody(as: WebDriverTimeouts.self)
            session.updateTimeouts(body)
            return HTTPResponse.null()

        default:
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }
    }

    // MARK: - Window

    private func handleWindow(_ request: HTTPRequest, session: WebDriverSession, components: [String]) async throws -> HTTPResponse {
        if components.isEmpty {
            switch request.method {
            case .GET:
                // Get current window handle
                let handle = await session.getWindowHandle()
                return HTTPResponse.json(handle)

            case .POST:
                // Switch to window
                struct SwitchWindowRequest: Codable {
                    let handle: String
                }
                let body = try request.decodeBody(as: SwitchWindowRequest.self)
                try await session.switchToWindow(body.handle)
                return HTTPResponse.null()

            case .DELETE:
                // Close current window
                try await session.closeWindow()
                let handles = await session.getWindowHandles()
                return HTTPResponse.json(handles)

            default:
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
        }

        switch components[0] {
        case "handles":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let handles = await session.getWindowHandles()
            return HTTPResponse.json(handles)

        case "new":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            struct NewWindowRequest: Codable {
                var type: String? // "tab" or "window"
            }
            let body = try? request.decodeBody(as: NewWindowRequest.self)
            let handle = try await session.createNewWindow(type: body?.type ?? "tab")

            struct NewWindowResponse: Codable {
                let handle: String
                let type: String
            }
            return HTTPResponse.json(NewWindowResponse(handle: handle, type: body?.type ?? "tab"))

        case "rect":
            switch request.method {
            case .GET:
                let rect = await session.getWindowRect()
                return HTTPResponse.json(rect)

            case .POST:
                let body = try request.decodeBody(as: WindowRect.self)
                let newRect = await session.setWindowRect(body)
                return HTTPResponse.json(newRect)

            default:
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }

        case "maximize":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let rect = await session.maximizeWindow()
            return HTTPResponse.json(rect)

        case "minimize":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let rect = await session.minimizeWindow()
            return HTTPResponse.json(rect)

        case "fullscreen":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let rect = await session.fullscreenWindow()
            return HTTPResponse.json(rect)

        default:
            throw WebDriverError.unknownCommand(request.path)
        }
    }

    // MARK: - Elements

    private func handleElement(_ request: HTTPRequest, session: WebDriverSession, components: [String]) async throws -> HTTPResponse {
        // POST /session/{id}/element - Find single element
        if components.isEmpty && request.method == .POST {
            let body = try request.decodeBody(as: FindElementRequest.self)
            let element = try await session.findElement(using: body.using, value: body.value)
            return HTTPResponse.json(element)
        }

        // Element-specific commands: /session/{id}/element/{elementId}/...
        guard !components.isEmpty else {
            throw WebDriverError.unknownCommand(request.path)
        }

        let elementId = components[0]

        if components.count == 1 {
            throw WebDriverError.unknownCommand(request.path)
        }

        let subCommand = components[1]

        switch subCommand {
        case "click":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            try await session.clickElement(elementId)
            return HTTPResponse.null()

        case "clear":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            try await session.clearElement(elementId)
            return HTTPResponse.null()

        case "value":
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let body = try request.decodeBody(as: SendKeysRequest.self)
            try await session.sendKeysToElement(elementId, text: body.text)
            return HTTPResponse.null()

        case "text":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let text = try await session.getElementText(elementId)
            return HTTPResponse.json(text)

        case "name":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let name = try await session.getElementTagName(elementId)
            return HTTPResponse.json(name)

        case "attribute":
            guard request.method == .GET, components.count >= 3 else {
                throw WebDriverError.unknownCommand(request.path)
            }
            let attributeName = components[2]
            let value = try await session.getElementAttribute(elementId, name: attributeName)
            return HTTPResponse.json(AnyCodable(value ?? NSNull()))

        case "property":
            guard request.method == .GET, components.count >= 3 else {
                throw WebDriverError.unknownCommand(request.path)
            }
            let propertyName = components[2]
            let value = try await session.getElementProperty(elementId, name: propertyName)
            return HTTPResponse.json(AnyCodable(value ?? NSNull()))

        case "css":
            guard request.method == .GET, components.count >= 3 else {
                throw WebDriverError.unknownCommand(request.path)
            }
            let propertyName = components[2]
            let value = try await session.getElementCSSValue(elementId, propertyName: propertyName)
            return HTTPResponse.json(value)

        case "rect":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let rect = try await session.getElementRect(elementId)
            return HTTPResponse.json(rect)

        case "enabled":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let enabled = try await session.isElementEnabled(elementId)
            return HTTPResponse.json(enabled)

        case "selected":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let selected = try await session.isElementSelected(elementId)
            return HTTPResponse.json(selected)

        case "displayed":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let displayed = try await session.isElementDisplayed(elementId)
            return HTTPResponse.json(displayed)

        case "element":
            // Find element from element
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let body = try request.decodeBody(as: FindElementRequest.self)
            let element = try await session.findElementFromElement(elementId, using: body.using, value: body.value)
            return HTTPResponse.json(element)

        case "elements":
            // Find elements from element
            guard request.method == .POST else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let body = try request.decodeBody(as: FindElementRequest.self)
            let elements = try await session.findElementsFromElement(elementId, using: body.using, value: body.value)
            return HTTPResponse.json(elements)

        case "screenshot":
            guard request.method == .GET else {
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
            let screenshot = try await session.takeElementScreenshot(elementId)
            return HTTPResponse.json(screenshot)

        default:
            throw WebDriverError.unknownCommand(request.path)
        }
    }

    private func handleElements(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .POST else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        let body = try request.decodeBody(as: FindElementRequest.self)
        let elements = try await session.findElements(using: body.using, value: body.value)
        return HTTPResponse.json(elements)
    }

    // MARK: - Document

    private func handleSource(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .GET else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        let source = try await session.getPageSource()
        return HTTPResponse.json(source)
    }

    private func handleExecute(_ request: HTTPRequest, session: WebDriverSession, components: [String]) async throws -> HTTPResponse {
        guard request.method == .POST else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        guard !components.isEmpty else {
            throw WebDriverError.unknownCommand(request.path)
        }

        let body = try request.decodeBody(as: ExecuteScriptRequest.self)
        let args = body.args?.map(\.value) ?? []

        switch components[0] {
        case "sync":
            let result = try await session.executeScript(body.script, args: args)
            return HTTPResponse.json(AnyCodable(result ?? NSNull()))

        case "async":
            let result = try await session.executeAsyncScript(body.script, args: args)
            return HTTPResponse.json(AnyCodable(result ?? NSNull()))

        default:
            throw WebDriverError.unknownCommand(request.path)
        }
    }

    // MARK: - Screenshot

    private func handleScreenshot(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        guard request.method == .GET else {
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }

        let screenshot = try await session.takeScreenshot()
        return HTTPResponse.json(screenshot)
    }

    // MARK: - Cookies

    private func handleCookie(_ request: HTTPRequest, session: WebDriverSession, components: [String]) async throws -> HTTPResponse {
        if components.isEmpty {
            switch request.method {
            case .GET:
                let cookies = try await session.getAllCookies()
                return HTTPResponse.json(cookies)

            case .POST:
                struct AddCookieRequest: Codable {
                    let cookie: WebDriverCookie
                }
                let body = try request.decodeBody(as: AddCookieRequest.self)
                try await session.addCookie(body.cookie)
                return HTTPResponse.null()

            case .DELETE:
                try await session.deleteAllCookies()
                return HTTPResponse.null()

            default:
                throw WebDriverError.unknownMethod(request.method.rawValue)
            }
        }

        let cookieName = components[0]

        switch request.method {
        case .GET:
            let cookie = try await session.getCookie(named: cookieName)
            return HTTPResponse.json(cookie)

        case .DELETE:
            try await session.deleteCookie(named: cookieName)
            return HTTPResponse.null()

        default:
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }
    }

    // MARK: - Actions

    private func handleActions(_ request: HTTPRequest, session: WebDriverSession) async throws -> HTTPResponse {
        switch request.method {
        case .POST:
            struct ActionsRequest: Codable {
                let actions: [AnyCodable]
            }
            let body = try request.decodeBody(as: ActionsRequest.self)
            try await session.performActions(body.actions.map(\.value))
            return HTTPResponse.null()

        case .DELETE:
            await session.releaseActions()
            return HTTPResponse.null()

        default:
            throw WebDriverError.unknownMethod(request.method.rawValue)
        }
    }
}

#endif
