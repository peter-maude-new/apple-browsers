//
//  AIChatNativeViewController.swift
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

import AppKit
import AIChat
import Combine

/// Native LLM view controller using Foundation Model Framework
final class AIChatNativeViewController: NSViewController {

    private let burnerMode: BurnerMode
    private let payload: AIChatPayload?

    init(payload: AIChatPayload?, burnerMode: BurnerMode) {
        self.payload = payload
        self.burnerMode = burnerMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // TODO: Set up native LLM UI using Foundation Model Framework

        self.view = container
    }
}
