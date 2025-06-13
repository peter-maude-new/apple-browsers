//
//  FloatingWindowController.swift
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

import SwiftUI
import BrowserServicesKit

// Custom switch style with icons inside
struct IconSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 64, height: 36)

            // Knob
            Circle()
                .frame(width: 32, height: 32)
                .foregroundColor(.white)
                .padding(2)
                .animation(.easeInOut(duration: 0.2), value: isOn)

            // Track icons (always visible)
            HStack {
                Image("AIChat")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(isOn ? .white : .blue)
                    .padding(.leading, 10)
                Spacer()
                Image("Find-Search")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(isOn ? .blue : .white)
                    .padding(.trailing, 10)
            }
            .frame(width: 64, height: 36)
        }
        .onTapGesture { configuration.isOn.toggle() }
    }
}

final class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }
}

// Add this new class (could be moved to its own file later)
final class FloatingWindowController: NSWindowController {

    private let aiChatTabOpener: AIChatTabOpening

    init(aiChatTabOpener: AIChatTabOpening) {
        self.aiChatTabOpener = aiChatTabOpener

        let viewController = NSViewController()
        let window = FloatingWindow(contentViewController: viewController)

        let contentView = NSHostingView(rootView: FloatingSearchBar(onCommit: { query in
            aiChatTabOpener.openAIChatTab(query, target: .newTabSelected)
            window.cancelOperation(nil)
        }))
        viewController.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 50))
        viewController.view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])

        window.styleMask = [.borderless]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isOpaque = false

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct FloatingSearchBar: View {
    enum FloatingMode {
        case chat, search
    }

    var onCommit: (String) -> Void
    @State private var query: String = ""
    @State private var mode: FloatingMode = .chat

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding<Bool>(
                get: { mode == .search },
                set: { mode = $0 ? .search : .chat }
            ))
            .toggleStyle(IconSwitchToggleStyle())
            .labelsHidden()

            TextField(
                mode == .chat ? "Ask anything" : "Search or enter address",
                text: $query,
                onCommit: {
                    onCommit(query)
                    query = ""
                }
            )
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 16))

            Spacer()

            Image(systemName: "location.north.circle")
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.systemBlue), lineWidth: 2)
        )
        .padding(4)
    }
}
