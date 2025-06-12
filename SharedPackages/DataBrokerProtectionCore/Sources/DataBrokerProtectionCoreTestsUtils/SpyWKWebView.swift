//
//  SpyWKWebView.swift
//
//  Created for test spying purposes.
//
//  This spy replaces the real WKWebView in tests so we can assert that
//  the UserScriptMessageBroker actually pushed messages into the web
//  context without executing any JavaScript.
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

import WebKit

/// A light-weight spy that records JavaScript passed to `evaluateJavaScript(…)` so that
/// unit-tests can assert that native code actually attempted to post a message into
/// the page.  **Do not** call this outside of test targets.
@MainActor
public final class SpyWKWebView: WKWebView {

    /// The last JavaScript string passed to any variant of `evaluateJavaScript`.
    public private(set) var lastEvaluatedJavaScript: String?
    /// Number of times any `evaluateJavaScript` variant has been invoked.
    public private(set) var evaluateJavaScriptCallCount: Int = 0

    public init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Legacy API
    public override func evaluateJavaScript(_ javaScriptString: String,
                                            completionHandler: ((Any?, Error?) -> Void)? = nil) {
        recordEvaluation(of: javaScriptString)
        completionHandler?(nil, nil)
    }

    // MARK: - Helpers
    private func recordEvaluation(of script: String) {
        evaluateJavaScriptCallCount += 1
        lastEvaluatedJavaScript = script
    }
} 