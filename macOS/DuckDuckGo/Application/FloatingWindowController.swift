//
//  FloatingWindowController.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import AppKit
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
final class FloatingWindowController: NSWindowController, NSWindowDelegate {

    private let aiChatTabOpener: AIChatTabOpening
    private var hostViewController: NSViewController!
    private var contentHostingView: NSHostingView<FloatingSearchBar>?

    init(aiChatTabOpener: AIChatTabOpening) {
        self.aiChatTabOpener = aiChatTabOpener

        let viewController = NSViewController()
        self.hostViewController = viewController
        let window = FloatingWindow(contentViewController: viewController)

        viewController.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 50))

        window.styleMask = [.borderless]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isOpaque = false

        super.init(window: window)
        window.delegate = self

        setupContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Sets up or re-creates the SwiftUI content to reset @State
    private func setupContentView() {
        // Remove existing hosting view if present
        contentHostingView?.removeFromSuperview()

        // Create a fresh hosting view with a commit handler
        let hostingView = NSHostingView(rootView: FloatingSearchBar(onCommit: { [weak self] query in
            self?.didCommit(query)
        }))
        contentHostingView = hostingView

        // Add the new hosting view to the controller's view
        let container = hostViewController.view
        container.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }

    // Called when the user presses Enter: opens a new AI chat tab, resets the UI, and hides the window
    private func didCommit(_ query: String) {
        aiChatTabOpener.openAIChatTab(query, target: .newTabSelected)
        setupContentView()
        window?.cancelOperation(nil)
    }
}

struct FloatingSearchBar: View {
    enum FloatingMode {
        case chat, search
    }

    var onCommit: (String) -> Void
    @State private var query: String = ""
    // Currently selected context app
    @State private var selectedApp: NSRunningApplication?
    // Whether the app-selection popover is shown
    @State private var showAppMenu = false
    // List of running user applications
    private var apps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
    }
    @State private var mode: FloatingMode = .chat

    var body: some View {
        HStack(spacing: 12) {
            Image("AIChat")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.greyText)

            TextField(
                mode == .chat ? "Ask anything" : "Search or enter address",
                text: $query,
                onCommit: {
                    let committed = self.query
                    self.query = ""
                    DispatchQueue.main.async {
                        onCommit(committed)
                    }
                }
            )
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 16))

//            Spacer()

            // Context selection controls: plus/pill and dropdown via popover
//            HStack(spacing: 4) {
//                if let app = selectedApp {
//                    // Selected app pill
//                    HStack(spacing: 4) {
//                        Image(nsImage: app.icon ?? NSImage())
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 16, height: 16)
//                        Text(app.localizedName ?? "")
//                            .font(.system(size: 12))
//                            .foregroundColor(.primary)
//                        Button(action: { selectedApp = nil }) {
//                            Image(systemName: "xmark")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 8, height: 36)
//                                .foregroundColor(.gray)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                    .padding(.vertical, 2)
//                    .padding(.horizontal, 6)
//                    .background(Color.white)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                    )
//                    .cornerRadius(8)
//                    .onTapGesture { showAppMenu.toggle() }
//                    .frame(height: 36)
//                }
//                if selectedApp == nil {
//                    // Dropdown arrow button
//                    Button(action: { showAppMenu.toggle() }) {
//                        Image(systemName: "plus")
//                            .foregroundColor(Color(NSColor.systemBlue))
//                            .padding(4)
//                            .background(Color.white)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .frame(width: 36, height: 36)
//                    // Show popover with app list
//                    .popover(isPresented: $showAppMenu, arrowEdge: .bottom) {
//                        VStack(alignment: .leading, spacing: 0) {
//                            ForEach(apps, id: \.bundleIdentifier) { app in
//                                Button(action: {
//                                    selectedApp = app
//                                    showAppMenu = false
//                                }) {
//                                    HStack {
//                                        Image(nsImage: app.icon ?? NSImage())
//                                            .resizable()
//                                            .frame(width: 16, height: 16)
//                                        Text(app.localizedName ?? "")
//                                    }
//                                    .padding(6)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                }
//                                .buttonStyle(PlainButtonStyle())
//                            }
//                        }
//                        .frame(width: 200)
//                    }
//                }
//            }
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

// Helper to find nested NSTextField in a view hierarchy
private extension NSView {
    func findTextField() -> NSTextField? {
        if let tf = self as? NSTextField { return tf }
        for subview in subviews {
            if let found = subview.findTextField() { return found }
        }
        return nil
    }
}

// MARK: - NSWindowDelegate
extension FloatingWindowController {
    func windowDidBecomeKey(_ notification: Notification) {
        // Focus the SwiftUI text field when the window becomes active
        guard let hosting = contentHostingView,
              let textField = hosting.findTextField() else { return }
        window?.makeFirstResponder(textField)
    }
}
