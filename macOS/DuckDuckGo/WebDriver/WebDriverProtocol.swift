//
//  WebDriverProtocol.swift
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

// MARK: - W3C WebDriver Protocol Types

/// W3C WebDriver error codes
/// See: https://www.w3.org/TR/webdriver2/#errors
enum WebDriverErrorCode: String, Codable {
    case elementClickIntercepted = "element click intercepted"
    case elementNotInteractable = "element not interactable"
    case insecureCertificate = "insecure certificate"
    case invalidArgument = "invalid argument"
    case invalidCookieDomain = "invalid cookie domain"
    case invalidElementState = "invalid element state"
    case invalidSelector = "invalid selector"
    case invalidSessionId = "invalid session id"
    case javascriptError = "javascript error"
    case moveTargetOutOfBounds = "move target out of bounds"
    case noSuchAlert = "no such alert"
    case noSuchCookie = "no such cookie"
    case noSuchElement = "no such element"
    case noSuchFrame = "no such frame"
    case noSuchWindow = "no such window"
    case noSuchShadowRoot = "no such shadow root"
    case scriptTimeout = "script timeout"
    case sessionNotCreated = "session not created"
    case staleElementReference = "stale element reference"
    case detachedShadowRoot = "detached shadow root"
    case timeout = "timeout"
    case unableToSetCookie = "unable to set cookie"
    case unableToCaptureScreen = "unable to capture screen"
    case unexpectedAlertOpen = "unexpected alert open"
    case unknownCommand = "unknown command"
    case unknownError = "unknown error"
    case unknownMethod = "unknown method"
    case unsupportedOperation = "unsupported operation"

    var httpStatusCode: Int {
        switch self {
        case .elementClickIntercepted, .elementNotInteractable, .invalidElementState:
            return 400
        case .insecureCertificate:
            return 400
        case .invalidArgument, .invalidCookieDomain, .invalidSelector:
            return 400
        case .invalidSessionId:
            return 404
        case .javascriptError:
            return 500
        case .moveTargetOutOfBounds:
            return 500
        case .noSuchAlert, .noSuchCookie, .noSuchElement, .noSuchFrame, .noSuchWindow, .noSuchShadowRoot:
            return 404
        case .scriptTimeout, .timeout:
            return 500
        case .sessionNotCreated:
            return 500
        case .staleElementReference, .detachedShadowRoot:
            return 404
        case .unableToSetCookie, .unableToCaptureScreen:
            return 500
        case .unexpectedAlertOpen:
            return 500
        case .unknownCommand:
            return 404
        case .unknownError:
            return 500
        case .unknownMethod:
            return 405
        case .unsupportedOperation:
            return 500
        }
    }
}

/// W3C WebDriver error response
struct WebDriverError: Error, Codable {
    let error: WebDriverErrorCode
    let message: String
    let stacktrace: String

    init(_ code: WebDriverErrorCode, message: String, stacktrace: String = "") {
        self.error = code
        self.message = message
        self.stacktrace = stacktrace
    }

    static func invalidSessionId(_ sessionId: String) -> WebDriverError {
        WebDriverError(.invalidSessionId, message: "Session \(sessionId) does not exist")
    }

    static func noSuchElement(using: String, value: String) -> WebDriverError {
        WebDriverError(.noSuchElement, message: "Unable to locate element using \(using): \(value)")
    }

    static func staleElementReference(_ elementId: String) -> WebDriverError {
        WebDriverError(.staleElementReference, message: "Element \(elementId) is no longer attached to the DOM")
    }

    static func invalidArgument(_ message: String) -> WebDriverError {
        WebDriverError(.invalidArgument, message: message)
    }

    static func unknownCommand(_ path: String) -> WebDriverError {
        WebDriverError(.unknownCommand, message: "Unknown command: \(path)")
    }

    static func unknownMethod(_ method: String) -> WebDriverError {
        WebDriverError(.unknownMethod, message: "Method \(method) not allowed")
    }

    static func sessionNotCreated(_ message: String) -> WebDriverError {
        WebDriverError(.sessionNotCreated, message: message)
    }

    static func javascriptError(_ message: String) -> WebDriverError {
        WebDriverError(.javascriptError, message: message)
    }

    static func timeout(_ message: String) -> WebDriverError {
        WebDriverError(.timeout, message: message)
    }

    static func noSuchWindow(_ handle: String) -> WebDriverError {
        WebDriverError(.noSuchWindow, message: "Window \(handle) does not exist")
    }

    static func elementNotInteractable(_ elementId: String) -> WebDriverError {
        WebDriverError(.elementNotInteractable, message: "Element \(elementId) is not interactable")
    }
}

// MARK: - Request/Response Types

/// Generic W3C WebDriver response wrapper
struct WebDriverResponse<T: Encodable>: Encodable {
    let value: T
}

/// Empty response value (for commands that don't return data)
struct WebDriverNull: Codable {
    static let instance = WebDriverNull()
}

/// Session capabilities requested by client
struct WebDriverCapabilities: Codable {
    var browserName: String?
    var browserVersion: String?
    var platformName: String?
    var acceptInsecureCerts: Bool?
    var pageLoadStrategy: PageLoadStrategy?
    var proxy: WebDriverProxy?
    var timeouts: WebDriverTimeouts?
    var strictFileInteractability: Bool?
    var unhandledPromptBehavior: UnhandledPromptBehavior?

    // DuckDuckGo-specific capabilities
    var `duckduckgo:options`: DuckDuckGoOptions?

    enum CodingKeys: String, CodingKey {
        case browserName
        case browserVersion
        case platformName
        case acceptInsecureCerts
        case pageLoadStrategy
        case proxy
        case timeouts
        case strictFileInteractability
        case unhandledPromptBehavior
        case `duckduckgo:options`
    }
}

struct DuckDuckGoOptions: Codable {
    var automaticInspection: Bool?
    var automaticProfiling: Bool?
}

enum PageLoadStrategy: String, Codable {
    case none
    case eager
    case normal
}

enum UnhandledPromptBehavior: String, Codable {
    case dismiss
    case accept
    case dismissAndNotify = "dismiss and notify"
    case acceptAndNotify = "accept and notify"
    case ignore
}

struct WebDriverProxy: Codable {
    var proxyType: String?
    var proxyAutoconfigUrl: String?
    var ftpProxy: String?
    var httpProxy: String?
    var noProxy: [String]?
    var sslProxy: String?
    var socksProxy: String?
    var socksVersion: Int?
}

struct WebDriverTimeouts: Codable {
    var script: Int?      // milliseconds, default 30000
    var pageLoad: Int?    // milliseconds, default 300000
    var implicit: Int?    // milliseconds, default 0

    static let `default` = WebDriverTimeouts(script: 30000, pageLoad: 300000, implicit: 0)
}

/// New session request body
struct NewSessionRequest: Codable {
    var capabilities: NewSessionCapabilities?
    var desiredCapabilities: WebDriverCapabilities? // Legacy JSONWireProtocol

    struct NewSessionCapabilities: Codable {
        var alwaysMatch: WebDriverCapabilities?
        var firstMatch: [WebDriverCapabilities]?
    }
}

/// New session response
struct NewSessionResponse: Codable {
    let sessionId: String
    let capabilities: WebDriverCapabilities
}

/// Navigate to URL request
struct NavigateRequest: Codable {
    let url: String
}

/// Find element request
struct FindElementRequest: Codable {
    let using: ElementLocatorStrategy
    let value: String
}

enum ElementLocatorStrategy: String, Codable {
    case cssSelector = "css selector"
    case linkText = "link text"
    case partialLinkText = "partial link text"
    case tagName = "tag name"
    case xpath
}

/// Element reference (W3C format)
struct WebDriverElement: Codable {
    static let elementIdentifierKey = "element-6066-11e4-a52e-4f735466cecf"

    let elementId: String

    enum CodingKeys: String, CodingKey {
        case elementId = "element-6066-11e4-a52e-4f735466cecf"
    }

    init(elementId: String) {
        self.elementId = elementId
    }
}

/// Send keys request
struct SendKeysRequest: Codable {
    let text: String
}

/// Execute script request
struct ExecuteScriptRequest: Codable {
    let script: String
    let args: [AnyCodable]?
}

/// Window rect
struct WindowRect: Codable {
    var x: Int?
    var y: Int?
    var width: Int?
    var height: Int?
}

/// Window handle response
struct WindowHandleResponse: Codable {
    let handle: String
}

/// Cookie
struct WebDriverCookie: Codable {
    let name: String
    let value: String
    var path: String?
    var domain: String?
    var secure: Bool?
    var httpOnly: Bool?
    var expiry: Int?
    var sameSite: String?
}

// MARK: - AnyCodable for flexible JSON handling

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - HTTP Helpers

enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
    case PUT
}

struct HTTPRequest {
    let method: HTTPMethod
    let path: String
    let pathComponents: [String]
    let queryParameters: [String: String]
    let body: Data?

    init(method: HTTPMethod, path: String, body: Data? = nil) {
        self.method = method
        self.body = body

        // Parse path and query string
        let urlComponents = URLComponents(string: path)
        self.path = urlComponents?.path ?? path

        var pathComps = (urlComponents?.path ?? path).split(separator: "/").map(String.init)
        if pathComps.first?.isEmpty == true {
            pathComps.removeFirst()
        }
        self.pathComponents = pathComps

        var queryParams: [String: String] = [:]
        urlComponents?.queryItems?.forEach { item in
            queryParams[item.name] = item.value ?? ""
        }
        self.queryParameters = queryParams
    }

    func decodeBody<T: Decodable>(as type: T.Type) throws -> T {
        guard let body = body else {
            throw WebDriverError.invalidArgument("Request body is required")
        }
        do {
            return try JSONDecoder().decode(type, from: body)
        } catch {
            throw WebDriverError.invalidArgument("Invalid JSON body: \(error.localizedDescription)")
        }
    }
}

struct HTTPResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data

    static func json<T: Encodable>(_ value: T, statusCode: Int = 200) -> HTTPResponse {
        let response = WebDriverResponse(value: value)
        let data = (try? JSONEncoder().encode(response)) ?? Data()
        return HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "application/json; charset=utf-8"],
            body: data
        )
    }

    static func error(_ error: WebDriverError) -> HTTPResponse {
        let data = (try? JSONEncoder().encode(WebDriverResponse(value: error))) ?? Data()
        return HTTPResponse(
            statusCode: error.error.httpStatusCode,
            headers: ["Content-Type": "application/json; charset=utf-8"],
            body: data
        )
    }

    static func null(statusCode: Int = 200) -> HTTPResponse {
        json(WebDriverNull.instance, statusCode: statusCode)
    }
}

#endif
