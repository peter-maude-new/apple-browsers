//
//  AIChatUserScriptHandling.swift
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

import AIChat
import AppKit
import Combine
import Common
import CryptoKit
import DDGSync
import Foundation
import PixelKit
import UserScript
import OSLog

protocol AIChatMetricReportingHandling {
    func didReportMetric(_ metric: AIChatMetric, completion: (() -> Void)?)
}

protocol AIChatUserScriptHandling {
    @MainActor func openAIChatSettings(params: Any, message: UserScriptMessage) async -> Encodable?
    func getAIChatNativeConfigValues(params: Any, message: UserScriptMessage) async -> Encodable?
    func closeAIChat(params: Any, message: UserScriptMessage) async -> Encodable?
    func getAIChatNativePrompt(params: Any, message: UserScriptMessage) async -> Encodable?
    @MainActor func openAIChat(params: Any, message: UserScriptMessage) async -> Encodable?
    func getAIChatNativeHandoffData(params: Any, message: UserScriptMessage) -> Encodable?
    func recordChat(params: Any, message: UserScriptMessage) -> Encodable?
    func restoreChat(params: Any, message: UserScriptMessage) -> Encodable?
    func removeChat(params: Any, message: UserScriptMessage) -> Encodable?
    @MainActor func openSummarizationSourceLink(params: Any, message: UserScriptMessage) async -> Encodable?
    @MainActor func openTranslationSourceLink(params: Any, message: UserScriptMessage) async -> Encodable?
    var aiChatNativePromptPublisher: AnyPublisher<AIChatNativePrompt, Never> { get }

    func getAIChatPageContext(params: Any, message: UserScriptMessage) -> Encodable?
    var pageContextPublisher: AnyPublisher<AIChatPageContextData?, Never> { get }
    var pageContextRequestedPublisher: AnyPublisher<Void, Never> { get }
    var chatRestorationDataPublisher: AnyPublisher<AIChatRestorationData?, Never> { get }

    var messageHandling: AIChatMessageHandling { get }
    func submitAIChatNativePrompt(_ prompt: AIChatNativePrompt)
    func submitAIChatPageContext(_ pageContext: AIChatPageContextData?)

    func togglePageContextTelemetry(params: Any, message: UserScriptMessage) -> Encodable?
    func reportMetric(params: Any, message: UserScriptMessage) async -> Encodable?
    func storeMigrationData(params: Any, message: UserScriptMessage) -> Encodable?
    func getMigrationDataByIndex(params: Any, message: UserScriptMessage) -> Encodable?
    func getMigrationInfo(params: Any, message: UserScriptMessage) -> Encodable?
    func clearMigrationData(params: Any, message: UserScriptMessage) -> Encodable?
    func getSyncStatus(params: Any, message: UserScriptMessage) -> Encodable?
    func getScopedSyncAuthToken(params: Any, message: UserScriptMessage) async -> Encodable?
    func encryptWithSyncMasterKey(params: Any, message: UserScriptMessage) -> Encodable?
    func decryptWithSyncMasterKey(params: Any, message: UserScriptMessage) -> Encodable?
    @MainActor func sendToSyncSettings(params: Any, message: UserScriptMessage) async -> Encodable?
    @MainActor func sendToSetupSync(params: Any, message: UserScriptMessage) async -> Encodable?
}

final class AIChatUserScriptHandler: AIChatUserScriptHandling {
    public let messageHandling: AIChatMessageHandling
    public let aiChatNativePromptPublisher: AnyPublisher<AIChatNativePrompt, Never>
    public let pageContextPublisher: AnyPublisher<AIChatPageContextData?, Never>
    public let pageContextRequestedPublisher: AnyPublisher<Void, Never>
    public let chatRestorationDataPublisher: AnyPublisher<AIChatRestorationData?, Never>

    private let aiChatNativePromptSubject = PassthroughSubject<AIChatNativePrompt, Never>()
    private let pageContextSubject = PassthroughSubject<AIChatPageContextData?, Never>()
    private let pageContextRequestedSubject = PassthroughSubject<Void, Never>()
    private let chatRestorationDataSubject = PassthroughSubject<AIChatRestorationData?, Never>()
    private let storage: AIChatPreferencesStorage
    private let windowControllersManager: WindowControllersManagerProtocol
    private let notificationCenter: NotificationCenter
    private let pixelFiring: PixelFiring?
    private let statisticsLoader: StatisticsLoader?
    private let migrationStore = AIChatMigrationStore()
    private let syncService: DDGSyncing?
    private let tokenExchangeSession: URLSession

    init(
        storage: AIChatPreferencesStorage,
        messageHandling: AIChatMessageHandling = AIChatMessageHandler(),
        windowControllersManager: WindowControllersManagerProtocol,
        pixelFiring: PixelFiring?,
        statisticsLoader: StatisticsLoader?,
        notificationCenter: NotificationCenter = .default,
        syncService: DDGSyncing? = nil,
        tokenExchangeSession: URLSession = .shared
    ) {
        self.storage = storage
        self.messageHandling = messageHandling
        self.windowControllersManager = windowControllersManager
        self.pixelFiring = pixelFiring
        self.statisticsLoader = statisticsLoader
        self.notificationCenter = notificationCenter
        self.aiChatNativePromptPublisher = aiChatNativePromptSubject.eraseToAnyPublisher()
        self.pageContextPublisher = pageContextSubject.eraseToAnyPublisher()
        self.pageContextRequestedPublisher = pageContextRequestedSubject.eraseToAnyPublisher()
        self.chatRestorationDataPublisher = chatRestorationDataSubject.eraseToAnyPublisher()
        self.syncService = syncService
        self.tokenExchangeSession = tokenExchangeSession
    }

    enum AIChatKeys {
        static let aiChatPayload = "aiChatPayload"
        static let serializedChatData = "serializedChatData"
    }

    @MainActor public func openAIChatSettings(params: Any, message: UserScriptMessage) async -> Encodable? {
        windowControllersManager.showTab(with: .settings(pane: .aiChat))
        return nil
    }

    public func getAIChatNativeConfigValues(params: Any, message: UserScriptMessage) async -> Encodable? {
        messageHandling.getDataForMessageType(.nativeConfigValues)
    }

    func closeAIChat(params: Any, message: UserScriptMessage) async -> Encodable? {
        let isSidebar = await message.messageWebView?.url?.hasAIChatSidebarPlacementParameter == true

        if isSidebar {
            await windowControllersManager.mainWindowController?.mainViewController.aiChatSidebarPresenter.collapseSidebar(withAnimation: true)
        } else {
            await windowControllersManager.mainWindowController?.mainViewController.closeTab(nil)
        }
        return nil
    }

    func getAIChatNativePrompt(params: Any, message: UserScriptMessage) async -> Encodable? {
        messageHandling.getDataForMessageType(.nativePrompt)
    }

    func getAIChatPageContext(params: Any, message: any UserScriptMessage) -> Encodable? {
        guard let payload: GetPageContext = DecodableHelper.decode(from: params) else {
            return nil
        }

        let pageContext = messageHandling.getDataForMessageType(.pageContext) as? AIChatPageContextData

        if pageContext == nil, payload.reason == "userAction" {
            pageContextRequestedSubject.send()
        }

        return PageContextResponse(pageContext: pageContext)
    }

    @MainActor
    func openAIChat(params: Any, message: UserScriptMessage) async -> Encodable? {
        var payload: AIChatPayload?
        if let paramsDict = params as? AIChatPayload {
            payload = paramsDict[AIChatKeys.aiChatPayload] as? AIChatPayload
        }

        notificationCenter.post(name: .aiChatNativeHandoffData, object: payload, userInfo: nil)
        return nil
    }

    public func getAIChatNativeHandoffData(params: Any, message: UserScriptMessage) -> Encodable? {
       messageHandling.getDataForMessageType(.nativeHandoffData)
    }

    public func getSyncStatus(params: Any, message: UserScriptMessage) -> Encodable? {
        let syncSetupEnabled = syncService != nil
        let syncEnabled = syncService?.account != nil

        guard let syncService else {
            Logger.aiChat.error("getSyncStatus: missingSyncService")
            return SyncStatusResponse(ok: false, reason: "internal error")
        }

        let account = syncService.account
        Logger.aiChat.info("getSyncStatus: syncEnabled=\(syncEnabled, privacy: .public), syncSetupEnabled=\(syncSetupEnabled, privacy: .public)")

        let payload = SyncStatusPayload(
            syncEnabled: syncEnabled,
            syncSetupEnabled: syncSetupEnabled,
            userId: account?.userId,
            deviceId: account?.deviceId,
            deviceName: account?.deviceName,
            deviceType: account?.deviceType
        )
        return SyncStatusResponse(payload: payload)
    }

    public func getScopedSyncAuthToken(params: Any, message: UserScriptMessage) async -> Encodable? {
        guard let syncService else {
            Logger.aiChat.error("getScopedSyncAuthToken: missingSyncService")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        guard let account = syncService.account else {
            Logger.aiChat.error("getScopedSyncAuthToken: noSyncAccount")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        guard let baseToken = account.token else {
            Logger.aiChat.error("getScopedSyncAuthToken: noBaseToken")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        guard let exchangeURL = makeTokenExchangeURL(for: syncService.serverEnvironment) else {
            Logger.aiChat.error("getScopedSyncAuthToken: unableToBuildURL")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        var request = URLRequest(url: exchangeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(baseToken)", forHTTPHeaderField: "Authorization")

        let body = ScopedTokenExchangeRequest(scope: "ai_chats")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            Logger.aiChat.error("getScopedSyncAuthToken: encodeFailed \(error.localizedDescription, privacy: .public)")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        let scopedTokenValue: String
        do {
            let (data, response) = try await tokenExchangeSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.aiChat.error("getScopedSyncAuthToken: invalidHTTPResponse")
                return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                Logger.aiChat.error("getScopedSyncAuthToken: status=\(httpResponse.statusCode, privacy: .public)")
                return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
            }

            let exchangeResponse = try JSONDecoder().decode(ScopedTokenExchangeResponse.self, from: data)
            scopedTokenValue = exchangeResponse.token
        } catch {
            Logger.aiChat.error("getScopedSyncAuthToken: requestFailed \(error.localizedDescription, privacy: .public)")
            return ScopedSyncAuthTokenResponse(ok: false, reason: "token unavailable")
        }

        Logger.aiChat.info("getScopedSyncAuthToken: success")
        return ScopedSyncAuthTokenResponse(token: scopedTokenValue)
    }

    public func encryptWithSyncMasterKey(params: Any, message: UserScriptMessage) -> Encodable? {
        guard let payload = SyncChatCrypto.extractString(from: params) else {
            Logger.aiChat.error("encryptWithSyncMasterKey: missing data")
            return SyncEncryptedDataResponse(ok: false, reason: "encryption failed")
        }
        guard syncService != nil else {
            Logger.aiChat.error("encryptWithSyncMasterKey: missingSyncService")
            return SyncEncryptedDataResponse(ok: false, reason: "sync disabled")
        }
        guard let account = syncService?.account else {
            Logger.aiChat.error("encryptWithSyncMasterKey: noSyncAccount")
            return SyncEncryptedDataResponse(ok: false, reason: "sync off")
        }
        do {
            let encrypted = try SyncChatCryptoEncoder.encrypt(payload: payload, masterKey: account.secretKey)
            return SyncEncryptedDataResponse(encryptedData: encrypted)
        } catch {
            Logger.aiChat.error("encryptWithSyncMasterKey: failed \(error.localizedDescription, privacy: .public)")
            return SyncEncryptedDataResponse(ok: false, reason: "encryption failed")
        }
    }

    public func decryptWithSyncMasterKey(params: Any, message: UserScriptMessage) -> Encodable? {
        guard let payload = SyncChatCrypto.extractString(from: params) else {
            Logger.aiChat.error("decryptWithSyncMasterKey: missing data")
            return SyncDecryptedDataResponse(ok: false, reason: "decryption failed")
        }
        guard syncService != nil else {
            Logger.aiChat.error("decryptWithSyncMasterKey: missingSyncService")
            return SyncDecryptedDataResponse(ok: false, reason: "sync disabled")
        }
        guard let account = syncService?.account else {
            Logger.aiChat.error("decryptWithSyncMasterKey: noSyncAccount")
            return SyncDecryptedDataResponse(ok: false, reason: "sync off")
        }
        do {
            let decrypted = try SyncChatCryptoEncoder.decrypt(encrypted: payload, masterKey: account.secretKey)
            return SyncDecryptedDataResponse(decryptedData: decrypted)
        } catch {
            Logger.aiChat.error("decryptWithSyncMasterKey: failed \(error.localizedDescription, privacy: .public)")
            return SyncDecryptedDataResponse(ok: false, reason: "decryption failed")
        }
    }

    @MainActor public func sendToSyncSettings(params: Any, message: UserScriptMessage) async -> Encodable? {
        Logger.aiChat.debug("sendToSyncSettings: opening sync settings pane")
        windowControllersManager.showTab(with: .settings(pane: .sync))
        return SyncSettingsResponse(ok: true)
    }

    @MainActor public func sendToSetupSync(params: Any, message: UserScriptMessage) async -> Encodable? {
        Logger.aiChat.debug("sendToSetupSync: starting setup flow")

        // Check if sync is already enabled
        if let syncService, syncService.account != nil {
            Logger.aiChat.error("sendToSetupSync: alreadySynced")
            return SyncSettingsResponse(ok: false, reason: "sync already enabled")
        }

        // Trigger the "Sync and Backup This Device" flow
        if let coordinator = DeviceSyncCoordinator() {
            windowControllersManager.showTab(with: .settings(pane: .sync))
            await coordinator.syncWithServerPressed()
            Logger.aiChat.info("sendToSetupSync: syncFlowStarted")
            return SyncSettingsResponse(ok: true)
        } else {
            Logger.aiChat.error("sendToSetupSync: failedToCreateCoordinator")
            return SyncSettingsResponse(ok: false, reason: "setup disabled")
        }
    }

    public func recordChat(params: Any, message: any UserScriptMessage) -> (any Encodable)? {
        guard let params = params as? [String: String],
              let data = params[AIChatKeys.serializedChatData]
        else { return nil }

        messageHandling.setData(data, forMessageType: .chatRestorationData)
        chatRestorationDataSubject.send(data)
        return nil
    }

    public func restoreChat(params: Any, message: any UserScriptMessage) -> (any Encodable)? {
        guard let data = messageHandling.getDataForMessageType(.chatRestorationData) as? String
        else { return nil }

        return [AIChatKeys.serializedChatData: data]
    }

    public func removeChat(params: Any, message: any UserScriptMessage) -> (any Encodable)? {
        messageHandling.setData(nil, forMessageType: .chatRestorationData)
        chatRestorationDataSubject.send(nil)
        return nil
    }

    @MainActor func openSummarizationSourceLink(params: Any, message: any UserScriptMessage) async -> (any Encodable)? {
        guard let openLinkParams: OpenLink = DecodableHelper.decode(from: params), let url = openLinkParams.url.url
        else { return nil }

        let isSidebar = message.messageWebView?.url?.hasAIChatSidebarPlacementParameter == true

        switch openLinkParams.target {
        case .sameTab where isSidebar == false: // for same tab outside of sidebar we force opening new tab to keep the AI chat tab
            windowControllersManager.show(url: url, source: .switchToOpenTab, newTab: true, selected: true)
        default:
            windowControllersManager.open(url, source: .link, target: nil, event: NSApp.currentEvent)
        }
        pixelFiring?.fire(AIChatPixel.aiChatSummarizeSourceLinkClicked, frequency: .dailyAndStandard)
        return nil
    }

    @MainActor func openTranslationSourceLink(params: Any, message: any UserScriptMessage) async -> (any Encodable)? {
        guard let openLinkParams: OpenLink = DecodableHelper.decode(from: params), let url = openLinkParams.url.url
        else { return nil }

        let isSidebar = message.messageWebView?.url?.hasAIChatSidebarPlacementParameter == true

        switch openLinkParams.target {
        case .sameTab where isSidebar == false: // for same tab outside of sidebar we force opening new tab to keep the AI chat tab
            windowControllersManager.show(url: url, source: .switchToOpenTab, newTab: true, selected: true)
        default:
            windowControllersManager.open(url, source: .link, target: nil, event: NSApp.currentEvent)
        }
        pixelFiring?.fire(AIChatPixel.aiChatTranslationSourceLinkClicked, frequency: .dailyAndStandard)
        return nil
    }

    func submitAIChatNativePrompt(_ prompt: AIChatNativePrompt) {
        aiChatNativePromptSubject.send(prompt)
    }

    func submitAIChatPageContext(_ pageContext: AIChatPageContextData?) {
        pageContextSubject.send(pageContext)
    }

    func reportMetric(params: Any, message: UserScriptMessage) async -> Encodable? {
        if let paramsDict = params as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: paramsDict, options: []) {

            let decoder = JSONDecoder()
            do {
                let metric = try decoder.decode(AIChatMetric.self, from: jsonData)
                didReportMetric(metric, completion: nil)
            } catch {
                Logger.aiChat.debug("Failed to decode metric JSON in AIChatUserScript: \(error)")
            }
        }
        return nil
    }

    func togglePageContextTelemetry(params: Any, message: UserScriptMessage) -> Encodable? {
        guard let payload: TogglePageContextTelemetry = DecodableHelper.decode(from: params) else {
            return nil
        }
        let pixel: PixelKitEvent = {
            if payload.enabled {
                return AIChatPixel.aiChatPageContextAdded(automaticEnabled: storage.shouldAutomaticallySendPageContext)
            }
            return AIChatPixel.aiChatPageContextRemoved(automaticEnabled: storage.shouldAutomaticallySendPageContext)
        }()
        pixelFiring?.fire(pixel, frequency: .dailyAndStandard)
        return nil
    }

    func storeMigrationData(params: Any, message: UserScriptMessage) -> Encodable? {
        guard let dict = params as? [String: Any] else {
            return AIChatErrorResponse(reason: "invalid_params")
        }
        guard dict.keys.contains(AIChatMigrationParamKeys.serializedMigrationFile) else {
            return AIChatErrorResponse(reason: "invalid_params")
        }
        let serialized = dict[AIChatMigrationParamKeys.serializedMigrationFile] as? String
        return migrationStore.store(serialized)
    }

    func getMigrationDataByIndex(params: Any, message: UserScriptMessage) -> Encodable? {
        guard let dict = params as? [String: Any] else {
            return migrationStore.item(at: nil)
        }
        let index = dict[AIChatMigrationParamKeys.index] as? Int
        return migrationStore.item(at: index)
    }

    func getMigrationInfo(params: Any, message: UserScriptMessage) -> Encodable? {
        return migrationStore.info()
    }

    func clearMigrationData(params: Any, message: UserScriptMessage) -> Encodable? {
        return migrationStore.clear()
    }
}

extension NSNotification.Name {
    static let aiChatNativeHandoffData: NSNotification.Name = Notification.Name(rawValue: "com.duckduckgo.notification.aiChatNativeHandoffData")
}

private enum SyncChatCryptoEncoder {

    enum Error: Swift.Error {
        case invalidMasterKeyLength
        case invalidCiphertextLength
        case invalidInputEncoding
    }

    private static let requiredKeyLength = 32
    private static let ivLength = 12
    private static let tagLength = 16

    /// Encrypts base64url-encoded binary data using AES-256-GCM
    /// Input: base64url-encoded plaintext bytes
    /// Output: base64url(IV || ciphertext || tag)
    static func encrypt(payload: String, masterKey: Data) throws -> String {
        guard masterKey.count == requiredKeyLength else {
            throw Error.invalidMasterKeyLength
        }
        
        // Decode the base64url input to get raw bytes
        guard let plaintextData = payload.base64URLDecodedData() else {
            throw Error.invalidInputEncoding
        }
        
        let symmetricKey = SymmetricKey(data: masterKey)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintextData, using: symmetricKey, nonce: nonce)

        // Concatenate: IV (12 bytes) || ciphertext || tag (16 bytes)
        var combined = Data()
        combined.append(contentsOf: nonce)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined.base64URLEncodedString()
    }

    /// Decrypts base64url(IV || ciphertext || tag) format
    /// Input: base64url-encoded (IV || ciphertext || tag)
    /// Output: base64url-encoded plaintext bytes
    static func decrypt(encrypted: String, masterKey: Data) throws -> String {
        guard masterKey.count == requiredKeyLength else {
            throw Error.invalidMasterKeyLength
        }
        
        // Decode the base64url input
        guard let combinedData = encrypted.base64URLDecodedData() else {
            throw Error.invalidInputEncoding
        }
        
        // Must have at least IV + tag (12 + 16 = 28 bytes)
        guard combinedData.count >= ivLength + tagLength else {
            throw Error.invalidCiphertextLength
        }
        
        // Parse: first 12 bytes = IV, last 16 bytes = tag, middle = ciphertext
        let ivData = combinedData.prefix(ivLength)
        let tagData = combinedData.suffix(tagLength)
        let ciphertextData = combinedData.dropFirst(ivLength).dropLast(tagLength)
        
        let symmetricKey = SymmetricKey(data: masterKey)
        let nonce = try AES.GCM.Nonce(data: ivData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)
        let plaintextData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        // Return as base64url-encoded bytes
        return plaintextData.base64URLEncodedString()
    }
}

private struct SyncChatCrypto {
    static func extractString(from params: Any) -> String? {
        if let string = params as? String {
            return string
        }
        if let dict = params as? [String: Any] {
            if let string = dict["data"] as? String {
                return string
            }
            if let string = dict["payload"] as? String {
                return string
            }
        }
        return nil
    }
}

private extension Data {

    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}

private extension String {
    func base64URLDecodedData() -> Data? {
        var base64 = self.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - (base64.count % 4)) % 4
        if padding > 0 {
            base64.append(String(repeating: "=", count: padding))
        }
        return Data(base64Encoded: base64)
    }
}

private extension AES.GCM.Nonce {
    var data: Data {
        withUnsafeBytes { Data($0) }
    }
}

extension AIChatUserScriptHandler {

    struct OpenLink: Codable, Equatable {
        let url: String
        let target: OpenTarget

        enum OpenTarget: String, Codable, Equatable {
            case sameTab = "same-tab"
            case newTab = "new-tab"
            case newWindow = "new-window"
        }
    }

    struct GetPageContext: Codable, Equatable {
        let reason: String
    }

    struct TogglePageContextTelemetry: Codable, Equatable {
        let enabled: Bool
    }
}

private struct ScopedTokenExchangeRequest: Encodable {
    let scope: String
}

private struct ScopedTokenExchangeResponse: Decodable {
    let token: String

    enum CodingKeys: String, CodingKey {
        case token
        case accessToken
    }

    init(token: String) {
        self.token = token
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let token = try container.decodeIfPresent(String.self, forKey: .token) {
            self.token = token
        } else if let token = try container.decodeIfPresent(String.self, forKey: .accessToken) {
            self.token = token
        } else {
            throw DecodingError.keyNotFound(CodingKeys.token, DecodingError.Context(codingPath: decoder.codingPath,
                                                                                    debugDescription: "token value missing in response"))
        }
    }
}

private func makeTokenExchangeURL(for environment: ServerEnvironment) -> URL? {
    let baseURLString: String
    switch environment {
    case .development:
        baseURLString = "https://sync-staging.duckduckgo.com"
    case .production:
        baseURLString = "https://sync.duckduckgo.com"
    }
    return URL(string: baseURLString)?.appendingPathComponent("sync/token/rescope")
}

extension AIChatUserScriptHandler: AIChatMetricReportingHandling {

    func didReportMetric(_ metric: AIChatMetric, completion: (() -> Void)? = nil) {
        switch metric.metricName {
        case .userDidSubmitFirstPrompt, .userDidSubmitPrompt:

            notificationCenter.post(name: .aiChatUserDidSubmitPrompt, object: nil)

            DispatchQueue.main.async { [self] in
                refreshAtbs(completion: completion)
            }
        default:
            completion?()
            return
        }
    }

    private func refreshAtbs(completion: (() -> Void)? = nil) {
        statisticsLoader?.refreshRetentionAtbOnDuckAiPromptSubmition {
            completion?()
        }
    }

}
