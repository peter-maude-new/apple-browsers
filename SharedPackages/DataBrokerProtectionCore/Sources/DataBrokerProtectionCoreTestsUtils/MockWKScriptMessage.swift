//
//  MockWKScriptMessage.swift
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

import WebKit

public class MockWKScriptMessage: WKScriptMessage {

    let mockedName: String
    let mockedBody: Any
    let mockedWebView: WKWebView?

    public override var name: String {
        return mockedName
    }

    public override var body: Any {
        return mockedBody
    }

    public override var webView: WKWebView? {
        return mockedWebView
    }

    public init(name: String = "", body: Any = "", webView: WKWebView? = nil) {
        self.mockedName = name
        self.mockedBody = body
        self.mockedWebView = webView
        super.init()
    }
} 
