//
//  WebExtensionManager.swift
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
import os.log
import WebKit

/// Manages web extensions including installation, loading, and lifecycle.
/// Platform-specific behavior is delegated to the windowTabProvider and lifecycleDelegate.
@available(macOS 15.4, iOS 18.4, *)
open class WebExtensionManager: NSObject, WebExtensionManaging {

    // MARK: - Dependencies

    public let installationStore: InstalledWebExtensionStoring
    public let storageProvider: WebExtensionStorageProviding
    public let loader: WebExtensionLoading
    public let controller: WKWebExtensionController
    public var eventsListener: WebExtensionEventsListening

    /// Platform-specific window/tab operations.
    public let windowTabProvider: WebExtensionWindowTabProviding

    /// Platform-specific lifecycle hooks.
    public private(set) weak var lifecycleDelegate: WebExtensionLifecycleDelegate?

    /// Optional internal site handler for platform-specific URL handling.
    public private(set) var internalSiteHandler: (any WebExtensionInternalSiteHandling)?

    // MARK: - Native Messaging Ports
    // Stores active message ports for bidirectional communication with extensions
    private var messagePorts: [String: WKWebExtension.MessagePort] = [:]

    /// Send a message to a connected extension via its MessagePort
    /// - Parameters:
    ///   - message: The message to send (will be serialized to JSON)
    ///   - extensionContext: The extension context to send to
    /// - Returns: true if message was queued, false if no port is connected
    @discardableResult
    func sendMessageToExtension(_ message: [String: Any], for extensionContext: WKWebExtensionContext) -> Bool {
        let identifier = extensionContext.uniqueIdentifier
        let extensionName = extensionContext.webExtension.displayName ?? identifier

        guard let port = messagePorts[identifier] else {
            Logger.webExtensions.warning("⚠️ No message port for extension: \(extensionName)")
            return false
        }

        Logger.webExtensions.log("📤 Sending message TO extension '\(extensionName)': \(message)")
        port.sendMessage(message) { error in
            if let error = error {
                Logger.webExtensions.error("❌ Failed to send message to '\(extensionName)': \(error.localizedDescription)")
            }
        }
        return true
    }

    /// Send a message to all connected extensions
    func broadcastMessageToExtensions(_ message: [String: Any]) {
        for context in contexts {
            sendMessageToExtension(message, for: context)
        }
    }

    // MARK: - AsyncStream

    private var continuation: AsyncStream<Void>.Continuation?
    public private(set) lazy var extensionUpdates = AsyncStream<Void> { [weak self] continuation in
        self?.continuation = continuation
    }

    // MARK: - Init

    @MainActor
    public init(configuration: WebExtensionConfigurationProviding,
                windowTabProvider: WebExtensionWindowTabProviding,
                storageProvider: WebExtensionStorageProviding,
                installationStore: InstalledWebExtensionStoring = InstalledWebExtensionStore(),
                loader: WebExtensionLoading? = nil,
                eventsListener: WebExtensionEventsListening = WebExtensionEventsListener(),
                lifecycleDelegate: WebExtensionLifecycleDelegate? = nil,
                internalSiteHandler: (any WebExtensionInternalSiteHandling)? = nil) {
        let controllerConfiguration = WKWebExtensionController.Configuration.default()
        controllerConfiguration.webViewConfiguration.applicationNameForUserAgent = configuration.applicationNameForUserAgent
        self.controller = WKWebExtensionController(configuration: controllerConfiguration)

        self.windowTabProvider = windowTabProvider
        self.storageProvider = storageProvider
        self.installationStore = installationStore
        self.loader = loader ?? WebExtensionLoader(storageProvider: storageProvider)
        self.eventsListener = eventsListener
        self.lifecycleDelegate = lifecycleDelegate
        self.internalSiteHandler = internalSiteHandler

        super.init()

        controller.delegate = self
    }

    // MARK: - Computed Properties

    public var contexts: [WKWebExtensionContext] {
        Array(controller.extensionContexts)
    }

    public var webExtensionIdentifiers: [String] {
        installationStore.installedExtensions.map(\.uniqueIdentifier)
    }

    public var hasInstalledExtensions: Bool {
        !installationStore.installedExtensions.isEmpty
    }

    public var loadedExtensions: Set<WKWebExtensionContext> {
        controller.extensionContexts
    }

    // MARK: - Install/Uninstall

    public func installExtension(from sourceURL: URL) async throws {
        Logger.webExtensions.debug("🔄 Installing extension from: \(sourceURL.path)")

        let identifier = UUID().uuidString

        _ = try storageProvider.copyExtension(from: sourceURL, identifier: identifier)
        Logger.webExtensions.debug("🔄 Extension stored with identifier: \(identifier)")

        do {
            let loadResult = try await loader.loadWebExtension(identifier: identifier, into: controller)

            let installedExtension = await InstalledWebExtension(
                uniqueIdentifier: identifier,
                filename: sourceURL.lastPathComponent,
                name: loadResult.context.webExtension.displayName,
                version: loadResult.context.webExtension.version
            )

            installationStore.add(installedExtension)
            Logger.webExtensions.info("✅ Successfully installed extension \(installedExtension.filename) (\(identifier))")
        } catch {
            Logger.webExtensions.error("❌ Failed to load extension '\(identifier)': \(error.localizedDescription)")
            try? storageProvider.removeExtension(identifier: identifier)
            throw WebExtensionError.failedToLoadWebExtension(error)
        }

        notifyUpdate()
    }

    public func uninstallExtension(identifier: String) throws {
        Logger.webExtensions.debug("🔄 Uninstalling extension '\(identifier)'")

        installationStore.remove(uniqueIdentifier: identifier)

        do {
            try loader.unloadExtension(identifier: identifier, from: controller)
            Logger.webExtensions.debug("✅ Unloaded extension '\(identifier)' from memory")
        } catch {
            Logger.webExtensions.debug("⚠️ Extension '\(identifier)' was not loaded in memory: \(error.localizedDescription)")
        }

        do {
            try storageProvider.removeExtension(identifier: identifier)
        } catch {
            Logger.webExtensions.error("❌ Failed to remove extension files for '\(identifier)': \(error.localizedDescription)")
            throw WebExtensionError.failedToRemoveWebExtension(error)
        }

        Logger.webExtensions.info("✅ Successfully uninstalled extension '\(identifier)'")
        notifyUpdate()
    }

    @discardableResult
    public func uninstallAllExtensions() -> [Result<Void, Error>] {
        let identifiers = installationStore.installedExtensions.map(\.uniqueIdentifier)
        Logger.webExtensions.debug("🔄 Uninstalling all extensions (count: \(identifiers.count))")

        let results: [Result<Void, Error>] = identifiers.map { identifier in
            do {
                try uninstallExtension(identifier: identifier)
                return .success(())
            } catch {
                return .failure(error)
            }
        }

        let successCount = results.filter { if case .success = $0 { return true } else { return false } }.count
        let failureCount = results.count - successCount
        if failureCount > 0 {
            Logger.webExtensions.error("❌ Uninstall all completed with errors: \(successCount) succeeded, \(failureCount) failed")
        } else {
            Logger.webExtensions.info("✅ Uninstall all completed: \(successCount) extensions removed")
        }

        storageProvider.cleanupOrphanedExtensions(keeping: [])

        return results
    }

    // MARK: - Loading

    @MainActor
    public func loadInstalledExtensions() async {
        eventsListener.controller = controller

        lifecycleDelegate?.webExtensionManagerWillLoadExtensions(self)

        let extensions = installationStore.installedExtensions
        Logger.webExtensions.debug("🔄 Loading installed extensions (count: \(extensions.count))")

        let identifiers = extensions.map(\.uniqueIdentifier)
        let results = await loader.loadWebExtensions(identifiers: identifiers, into: controller)

        var failedIdentifiers: [String] = []
        var successCount = 0
        for (installedExtension, result) in zip(extensions, results) {
            switch result {
            case .success:
                Logger.webExtensions.debug("✅ Loaded extension \(installedExtension.filename) (\(installedExtension.uniqueIdentifier))")
                successCount += 1
            case .failure(let failure):
                Logger.webExtensions.error("❌ Failed to load web extension \(installedExtension.filename) (\(installedExtension.uniqueIdentifier)): \(failure.localizedDescription)")
                failedIdentifiers.append(installedExtension.uniqueIdentifier)
            }
        }

        for identifier in failedIdentifiers {
            do {
                try uninstallExtension(identifier: identifier)
            } catch {
                Logger.webExtensions.error("❌ Failed to uninstall broken extension '\(identifier)': \(error.localizedDescription)")
            }
        }

        if failedIdentifiers.isEmpty {
            Logger.webExtensions.info("✅ Extension loading completed: \(successCount) loaded")
        } else {
            Logger.webExtensions.error("❌ Extension loading completed with errors: \(successCount) loaded, \(failedIdentifiers.count) failed and removed")
        }

        let knownIdentifiers = Set(installationStore.installedExtensions.map(\.uniqueIdentifier))
        storageProvider.cleanupOrphanedExtensions(keeping: knownIdentifiers)

        notifyUpdate()
    }

    // MARK: - Lookups

    public func extensionName(for identifier: String) -> String? {
        contexts.first { $0.uniqueIdentifier == identifier }?.webExtension.displayName
    }

    public func extensionContext(for url: URL) -> WKWebExtensionContext? {
        contexts.first { url.absoluteString.hasPrefix($0.baseURL.absoluteString) }
    }

    public func context(for identifier: String) -> WKWebExtensionContext? {
        contexts.first { $0.uniqueIdentifier == identifier }
    }

    private func notifyUpdate() {
        continuation?.yield()
        lifecycleDelegate?.webExtensionManagerDidUpdateExtensions(self)
    }
}

// MARK: - WKWebExtensionControllerDelegate

@available(macOS 15.4, iOS 18.4, *)
extension WebExtensionManager: WKWebExtensionControllerDelegate {

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       openWindowsFor extensionContext: WKWebExtensionContext) -> [any WKWebExtensionWindow] {
        windowTabProvider.openWindows(for: extensionContext)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       focusedWindowFor extensionContext: WKWebExtensionContext) -> (any WKWebExtensionWindow)? {
        windowTabProvider.focusedWindow(for: extensionContext)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       openNewWindowUsing configuration: WKWebExtension.WindowConfiguration,
                                       for extensionContext: WKWebExtensionContext) async throws -> (any WKWebExtensionWindow)? {
        try await windowTabProvider.openNewWindow(using: configuration, for: extensionContext)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       openNewTabUsing configuration: WKWebExtension.TabConfiguration,
                                       for extensionContext: WKWebExtensionContext) async throws -> (any WKWebExtensionTab)? {
        try await windowTabProvider.openNewTab(using: configuration, for: extensionContext)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       openOptionsPageFor extensionContext: WKWebExtensionContext) async throws {
        throw WebExtensionControllerDelegateError.notSupported
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       presentActionPopup action: WKWebExtension.Action,
                                       for extensionContext: WKWebExtensionContext) async throws {
        try await windowTabProvider.presentPopup(action, for: extensionContext)
    }

    // MARK: - Permissions (sensible defaults)

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       promptForPermissions permissions: Set<WKWebExtension.Permission>,
                                       in tab: (any WKWebExtensionTab)?,
                                       for extensionContext: WKWebExtensionContext) async -> (Set<WKWebExtension.Permission>, Date?) {
        (permissions, nil)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       promptForPermissionToAccess urls: Set<URL>,
                                       in tab: (any WKWebExtensionTab)?,
                                       for extensionContext: WKWebExtensionContext) async -> (Set<URL>, Date?) {
        (urls, nil)
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
                                       in tab: (any WKWebExtensionTab)?,
                                       for extensionContext: WKWebExtensionContext) async -> (Set<WKWebExtension.MatchPattern>, Date?) {
        (matchPatterns, nil)
    }

    // MARK: - Native Messaging API (Web Extension → Native)

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       sendMessage message: Any,
                                       toApplicationWithIdentifier applicationIdentifier: String?,
                                       for extensionContext: WKWebExtensionContext) async throws -> Any? {

        let extensionName = extensionContext.webExtension.displayName ?? "Unknown"

        // Log the received message from web extension
        if let messageDict = message as? [String: Any] {
            let messageType = messageDict["type"] as? String ?? "unknown"
            let userMessage = messageDict["message"] as? String ?? ""

            Logger.webExtensions.log("📩 RECEIVED from web extension '\(extensionName)':")
            Logger.webExtensions.log("   Type: \(messageType)")
            Logger.webExtensions.log("   Message: \(userMessage)")
            Logger.webExtensions.log("   Full payload: \(messageDict)")

            return [
                "status": "received",
                "nativeTimestamp": Date().timeIntervalSince1970
            ]
        } else {
            Logger.webExtensions.log("📩 RECEIVED from web extension (raw): \(String(describing: message))")
            return ["status": "received"]
        }
    }

    public func webExtensionController(_ controller: WKWebExtensionController,
                                       connectUsing port: WKWebExtension.MessagePort,
                                       for extensionContext: WKWebExtensionContext) async throws {
        let extensionName = extensionContext.webExtension.displayName ?? "Unknown"
        let identifier = extensionContext.uniqueIdentifier

        Logger.webExtensions.log("🔌 Native messaging port CONNECTED from extension: \(extensionName)")

        // Store the port for later use
        messagePorts[identifier] = port

        // Set up handler for messages FROM the extension
        port.messageHandler = { [weak self] message, error in
            if let error = error {
                Logger.webExtensions.error("❌ Port message error: \(error.localizedDescription)")
                return
            }

            guard let message = message else { return }

            Logger.webExtensions.log("📩 RECEIVED via MessagePort from '\(extensionName)':")
            Logger.webExtensions.log("   Payload: \(String(describing: message))")

            // Handle the message - you can add custom logic here
            if let messageDict = message as? [String: Any],
               let type = messageDict["type"] as? String {
                Logger.webExtensions.log("   Type: \(type)")

                if let userMessage = messageDict["message"] as? String {
                    Logger.webExtensions.log("   Message: \(userMessage)")
                }
            }
        }

        // Set up disconnect handler
        port.disconnectHandler = { [weak self] error in
            Logger.webExtensions.log("🔌 Native messaging port DISCONNECTED from extension: \(extensionName)")
            self?.messagePorts.removeValue(forKey: identifier)

            if let error = error {
                Logger.webExtensions.error("   Disconnect error: \(error.localizedDescription)")
            }
        }

        // Send a welcome message to the extension
        Logger.webExtensions.log("📤 Sending welcome message to '\(extensionName)'...")
        port.sendMessage([
            "type": "connected",
            "message": "Hello from DuckDuckGo native layer!",
            "timestamp": Date().timeIntervalSince1970
        ], completionHandler: { error in
            if let error = error {
                Logger.webExtensions.error("❌ Failed to send welcome message: \(error.localizedDescription)")
            } else {
                Logger.webExtensions.log("✅ Welcome message sent successfully")
            }
        })
    }
}

// MARK: - WebExtensionInternalSiteHandlerDataSource

@available(macOS 15.4, iOS 18.4, *)
extension WebExtensionManager: WebExtensionInternalSiteHandlerDataSource {

    public func webExtensionContext(for url: URL) -> WKWebExtensionContext? {
        extensionContext(for: url)
    }
}

// MARK: - Errors

@available(macOS 15.4, iOS 18.4, *)
public enum WebExtensionControllerDelegateError: Error {
    case notSupported
}
