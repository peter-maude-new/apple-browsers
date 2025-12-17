//
//  WebKitMocks.swift
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
import Navigation
import WebKit

#if _FRAME_HANDLE_ENABLED
public typealias TestFrameHandle = FrameHandle
#else
public struct TestFrameHandle: Hashable {
    public let rawValue: UInt64
}

public extension TestFrameHandle {
    static var fallbackMainFrameHandle: TestFrameHandle {
        TestFrameHandle(rawValue: 4)
    }

    static var fallbackNonMainFrameHandle: TestFrameHandle {
        TestFrameHandle(rawValue: 9)
    }
}
#endif

/// Workaround mocks for WebKit classes that can crash during test teardown in Xcode 26.
@objcMembers
public final class WKSecurityOriginMock: WKSecurityOrigin {

    public var _protocol: String!
    public override var `protocol`: String { _protocol }
    public var _host: String!
    public override var host: String { _host }
    public var _port: Int!
    public override var port: Int { _port }

    public func set(url: URL) {
        self._protocol = url.scheme ?? ""
        self._host = url.host ?? ""
        self._port = url.port ?? url.navigationalScheme?.defaultPort ?? 0
    }

    public func set(host: String, scheme: String = "https", port: Int = 0) {
        self._protocol = scheme
        self._host = host
        self._port = port
    }

    public class func new(url: URL) -> WKSecurityOriginMock {
        let mock = (self.perform(NSSelectorFromString("alloc")).takeUnretainedValue() as? WKSecurityOriginMock)!
        mock.set(url: url)
        return mock
    }

    public class func new(host: String, scheme: String = "https", port: Int = 0) -> WKSecurityOriginMock {
        let mock = (self.perform(NSSelectorFromString("alloc")).takeUnretainedValue() as? WKSecurityOriginMock)!
        mock.set(host: host, scheme: scheme, port: port)
        return mock
    }

}

@objcMembers
public final class WKFrameInfoMock: WKFrameInfo {
    public var _isMainFrame: Bool!
    public override var isMainFrame: Bool { _isMainFrame }
    public var _request: URLRequest!
    public override var request: URLRequest { _request }
    public var _securityOrigin: WKSecurityOrigin!
    public override var securityOrigin: WKSecurityOrigin { _securityOrigin }
    public weak var _webView: WKWebView?
    public override var webView: WKWebView? { _webView }

    private let handleValue: TestFrameHandle

    public var frameInfo: WKFrameInfo { self }

    public init(webView: WKWebView?, securityOrigin: WKSecurityOrigin, request: URLRequest, isMainFrame: Bool, handle: TestFrameHandle? = nil) {
        self._webView = webView
        self._securityOrigin = securityOrigin
        self._request = request
        self._isMainFrame = isMainFrame
        self.handleValue = handle ?? (isMainFrame ? .fallbackMainFrameHandle : .fallbackNonMainFrameHandle)
    }

    public convenience init(isMainFrame: Bool, request: URLRequest, securityOrigin: WKSecurityOrigin, webView: WKWebView?, handle: TestFrameHandle? = nil) {
        self.init(webView: webView, securityOrigin: securityOrigin, request: request, isMainFrame: isMainFrame, handle: handle)
    }

    public override func value(forKey key: String) -> Any? {
        if key == "handle" {
            return handleValue
        }
        return super.value(forKey: key)
    }
}

/// Prevents WebKit teardown crashes in tests by swapping out `dealloc`.
public extension WKScriptMessage {

    private static var isSwizzled = false
    private static let originalDealloc = { class_getInstanceMethod(WKScriptMessage.self, NSSelectorFromString("dealloc"))! }()
    private static let swizzledDealloc = { class_getInstanceMethod(WKScriptMessage.self, #selector(swizzled_dealloc))! }()

    static func swizzleDealloc() {
        guard !Self.isSwizzled else { return }
        Self.isSwizzled = true
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    static func restoreDealloc() {
        guard Self.isSwizzled else { return }
        Self.isSwizzled = false
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    @objc
    func swizzled_dealloc() { }
}

public extension WKNavigationResponse {

    private static var isSwizzled = false
    private static let originalDealloc = { class_getInstanceMethod(WKNavigationResponse.self, NSSelectorFromString("dealloc"))! }()
    private static let swizzledDealloc = { class_getInstanceMethod(WKNavigationResponse.self, #selector(swizzled_dealloc))! }()

    static func swizzleDealloc() {
        guard !Self.isSwizzled else { return }
        Self.isSwizzled = true
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    static func restoreDealloc() {
        guard Self.isSwizzled else { return }
        Self.isSwizzled = false
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    @objc
    func swizzled_dealloc() { }
}

public extension WKNavigation {

    private static var isSwizzled = false
    private static let originalDealloc = { class_getInstanceMethod(WKNavigation.self, NSSelectorFromString("dealloc"))! }()
    private static let swizzledDealloc = { class_getInstanceMethod(WKNavigation.self, #selector(swizzled_dealloc))! }()

    static func swizzleDealloc() {
        guard !Self.isSwizzled else { return }
        Self.isSwizzled = true
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    static func restoreDealloc() {
        guard Self.isSwizzled else { return }
        Self.isSwizzled = false
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    @objc
    func swizzled_dealloc() { }
}

public extension WKContentRuleList {

    private static var isSwizzled = false
    private static let originalDealloc = { class_getInstanceMethod(WKContentRuleList.self, NSSelectorFromString("dealloc"))! }()
    private static let swizzledDealloc = { class_getInstanceMethod(WKContentRuleList.self, #selector(swizzled_dealloc))! }()

    static func swizzleDealloc() {
        guard !Self.isSwizzled else { return }
        Self.isSwizzled = true
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    static func restoreDealloc() {
        guard Self.isSwizzled else { return }
        Self.isSwizzled = false
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    @objc
    func swizzled_dealloc() { }
}
