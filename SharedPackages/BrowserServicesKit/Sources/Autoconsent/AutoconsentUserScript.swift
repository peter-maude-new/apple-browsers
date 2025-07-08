//
//  AutoconsentUserScript.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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
import Common
import UserScript
import PrivacyDashboard
import PixelKit
import os.log

// MARK: - Protocols

/// Protocol for handling autoconsent user script events
public protocol AutoconsentUserScriptDelegate: AnyObject {
    func autoconsentUserScript(consentStatus: CookieConsentInfo)
}

/// Protocol for user scripts that support autoconsent
public protocol UserScriptWithAutoconsent: UserScript {
    var delegate: AutoconsentUserScriptDelegate? { get set }
}

/// Protocol for providing autoconsent preferences
public protocol AutoconsentPreferencesProvider {
    var isAutoconsentEnabled: Bool { get }
}

/// Protocol for handling autoconsent notifications
public protocol AutoconsentNotificationHandler {
    func handlePopupFound(for url: URL)
    func handleAutoconsentDone(for url: URL, isCosmetic: Bool)
    func handleOptOutFailed(for url: URL)
    func handleSelfTestResult(for url: URL, result: Bool)
}



/// Protocol for providing autoconsent configuration
public protocol AutoconsentConfigurationProvider {
    func isFeatureEnabled(for domain: String?) -> Bool
    func getRemoteConfig() -> [String: Any]
    func isFilterListEnabled(for domain: String?) -> Bool
}

// MARK: - Message Types

public enum AutoconsentMessageName: String, CaseIterable {
    case `init`
    case cmpDetected
    case eval
    case popupFound
    case optOutResult
    case optInResult
    case selfTestResult
    case autoconsentDone
    case autoconsentError
    case report
}

public struct AutoconsentInitMessage: Codable {
    public let type: String
    public let url: String
}

public struct AutoconsentCmpDetectedMessage: Codable {
    public let type: String
    public let cmp: String
    public let url: String
}

public struct AutoconsentEvalMessage: Codable {
    public let type: String
    public let id: String
    public let code: String
}

public struct AutoconsentPopupFoundMessage: Codable {
    public let type: String
    public let cmp: String
    public let url: String
}

public struct AutoconsentOptOutResultMessage: Codable {
    public let type: String
    public let cmp: String
    public let result: Bool
    public let scheduleSelfTest: Bool
    public let url: String
}

public struct AutoconsentOptInResultMessage: Codable {
    public let type: String
    public let cmp: String
    public let result: Bool
    public let scheduleSelfTest: Bool
    public let url: String
}

public struct AutoconsentSelfTestResultMessage: Codable {
    public let type: String
    public let cmp: String
    public let result: Bool
    public let url: String
}

public struct AutoconsentDoneMessage: Codable {
    public let type: String
    public let cmp: String
    public let url: String
    public let isCosmetic: Bool
}

public struct AutoconsentReportState: Codable {
    public let lifecycle: String
    public let detectedCmps: [String]
    public let heuristicPatterns: [String]
    public let heuristicSnippets: [String]
}

public struct AutoconsentReportMessage: Codable {
    public let type: String
    public let instanceId: String
    public let state: AutoconsentReportState
}

// MARK: - Base AutoconsentUserScript

open class AutoconsentUserScript: NSObject, WKScriptMessageHandlerWithReply, UserScriptWithAutoconsent {
    
    // MARK: - Constants
    
    private struct Constants {
        static let filterListCmpName = "filterList"
    }
    
    // MARK: - Properties
    
    public var injectionTime: WKUserScriptInjectionTime { .atDocumentStart }
    public var forMainFrameOnly: Bool { false }
    public var messageNames: [String] { AutoconsentMessageName.allCases.map(\.rawValue) }
    public let source: String
    
    public weak var delegate: AutoconsentUserScriptDelegate?
    
    // Internal properties for subclasses
    internal var topUrl: URL?
    internal weak var selfTestWebView: WKWebView?
    internal weak var selfTestFrameInfo: WKFrameInfo?
    private let management = AutoconsentManagement.shared
    
    // Platform-specific dependencies
    private let preferencesProvider: AutoconsentPreferencesProvider
    private let configurationProvider: AutoconsentConfigurationProvider
    private let notificationHandler: AutoconsentNotificationHandler?
    
    // MARK: - Initialization
    
    public init(source: String,
                preferencesProvider: AutoconsentPreferencesProvider,
                configurationProvider: AutoconsentConfigurationProvider,
                notificationHandler: AutoconsentNotificationHandler? = nil) {
        self.source = source
        self.preferencesProvider = preferencesProvider
        self.configurationProvider = configurationProvider
        self.notificationHandler = notificationHandler
        
        super.init()
        
        Logger.autoconsent.debug("Initialising autoconsent userscript")
    }
    
    // MARK: - WKScriptMessageHandler
    
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        // Legacy support - this is never used because macOS <11 is not supported by autoconsent
    }
    
    @MainActor
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage,
                                      replyHandler: @escaping (Any?, String?) -> Void) {
        handleMessage(replyHandler: replyHandler, message: message)
    }
    
    // MARK: - Dashboard State Management
    
    @MainActor
    public func refreshDashboardState(consentManaged: Bool, cosmetic: Bool?, optoutFailed: Bool?, selftestFailed: Bool?) {
        let consentStatus = CookieConsentInfo(
            consentManaged: consentManaged,
            cosmetic: cosmetic,
            optoutFailed: optoutFailed,
            selftestFailed: selftestFailed
        )
        Logger.autoconsent.debug("Refreshing dashboard state: \(String(describing: consentStatus))")
        self.delegate?.autoconsentUserScript(consentStatus: consentStatus)
    }
    
    // MARK: - Message Handling
    
    @MainActor
    private func handleMessage(replyHandler: @escaping (Any?, String?) -> Void,
                               message: WKScriptMessage) {
        guard let messageName = AutoconsentMessageName(rawValue: message.name) else {
            replyHandler(nil, "Unknown message type")
            return
        }
        
        switch messageName {
        case .`init`:
            handleInit(message: message, replyHandler: replyHandler)
        case .eval:
            handleEval(message: message, replyHandler: replyHandler)
        case .popupFound:
            handlePopupFound(message: message, replyHandler: replyHandler)
        case .optOutResult:
            handleOptOutResult(message: message, replyHandler: replyHandler)
        case .optInResult:
            handleOptInResult(message: message, replyHandler: replyHandler)
        case .cmpDetected:
            handleCmpDetected(message: message, replyHandler: replyHandler)
        case .selfTestResult:
            handleSelfTestResult(message: message, replyHandler: replyHandler)
        case .autoconsentDone:
            handleAutoconsentDone(message: message, replyHandler: replyHandler)
        case .autoconsentError:
            handleAutoconsentError(message: message, replyHandler: replyHandler)
        case .report:
            handleReport(message: message, replyHandler: replyHandler)
        }
    }
    
    // MARK: - Message Decoding
    
    internal func decodeMessageBody<Input: Any, Target: Codable>(from message: Input) -> Target? {
        do {
            let json = try JSONSerialization.data(withJSONObject: message)
            return try JSONDecoder().decode(Target.self, from: json)
        } catch {
            Logger.autoconsent.error("Error decoding message body: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    // MARK: - Domain Matching
    
    internal func matchDomainList(domain: String?, domainsList: [String]) -> Bool {
        guard let domain = domain else { return false }
        let trimmedDomains = domainsList.filter { !$0.trimmingWhitespace().isEmpty }
        
        var tempDomain = domain
        while tempDomain.contains(".") {
            if trimmedDomains.contains(tempDomain) {
                return true
            }
            
            let comps = tempDomain.split(separator: ".")
            tempDomain = comps.dropFirst().joined(separator: ".")
        }
        
        return false
    }
    
    // MARK: - Message Handlers
    
    @MainActor
    private func handleInit(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentInitMessage = decodeMessageBody(from: message.body),
              let url = URL(string: messageData.url) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        // Check for valid HTTP/HTTPS schemes
        if !url.isHttp && !url.isHttps {
            Logger.autoconsent.debug("Ignoring special URL scheme: \(messageData.url)")
            replyHandler([ "type": "ok" ], nil)
            return
        }
        
        // Check if autoconsent is enabled
        guard preferencesProvider.isAutoconsentEnabled else {
            replyHandler([ "type": "ok" ], nil)
            return
        }
        
        // Check if feature is enabled for this domain
        let topURLDomain = message.webView?.url?.host
        guard configurationProvider.isFeatureEnabled(for: topURLDomain) else {
            Logger.autoconsent.info("disabled for site: \(String(describing: url.absoluteString))")
            replyHandler([ "type": "ok" ], nil)
            fireEvent(event: .disabledForSite)
            return
        }
        
        // Initialize state for main frame
        if message.frameInfo.isMainFrame {
            topUrl = url
            refreshDashboardState(
                consentManaged: management.sitesNotifiedCache.contains(url.host ?? ""),
                cosmetic: nil,
                optoutFailed: nil,
                selftestFailed: nil
            )
            fireEvent(event: .acInit)
        }
        
        // Get remote configuration
        let remoteConfig = configurationProvider.getRemoteConfig()
        let disabledCMPs = remoteConfig["disabledCMPs"] as? [String] ?? []
        let enableFilterList = configurationProvider.isFilterListEnabled(for: topURLDomain)
        
        let autoconsentConfig = [
            "type": "initResp",
            "rules": [
                "compact": remoteConfig["compactRuleList"] ?? nil
            ],
            "config": [
                "enabled": true,
                "autoAction": preferencesProvider.isAutoconsentEnabled ? "optOut" : nil,
                "disabledCmps": disabledCMPs,
                "enablePrehide": true,
                "enableCosmeticRules": true,
                "detectRetries": 20,
                "isMainWorld": false,
                "enableFilterList": enableFilterList,
                "enableHeuristicDetection": true
            ] as [String: Any?]
        ] as [String: Any?]
        
        replyHandler(autoconsentConfig, nil)
    }
    
    @MainActor
    private func handleEval(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentEvalMessage = decodeMessageBody(from: message.body) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        let script = """
        (() => {
        try {
            return !!(\(messageData.code));
        } catch (e) {
          return;
        }
        })();
        """
        
        guard let webView = message.webView else {
            replyHandler(nil, "missing frame target")
            return
        }
        
        webView.evaluateJavaScript(script, in: message.frameInfo, in: WKContentWorld.page) { result in
            switch result {
            case .failure(let error):
                replyHandler(nil, "Error snippet: \(error)")
            case .success(let value):
                replyHandler([
                    "type": "evalResp",
                    "id": messageData.id,
                    "result": value
                ], nil)
            }
        }
    }
    
    @MainActor
    private func handlePopupFound(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentPopupFoundMessage = decodeMessageBody(from: message.body),
              let url = URL(string: messageData.url) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        Logger.autoconsent.debug("Cookie popup found: \(String(describing: messageData))")
        fireEvent(event: .popupFound)
        
        // Handle cosmetic filter list matches
        if messageData.cmp == Constants.filterListCmpName {
            refreshDashboardState(consentManaged: true, cosmetic: true, optoutFailed: false, selftestFailed: nil)
            notificationHandler?.handlePopupFound(for: url)
        }
        
        replyHandler([ "type": "ok" ], nil)
    }
    
    @MainActor
    private func handleOptOutResult(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentOptOutResultMessage = decodeMessageBody(from: message.body) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        Logger.autoconsent.debug("opt-out result: \(String(describing: messageData))")
        
        if !messageData.result {
            refreshDashboardState(consentManaged: true, cosmetic: nil, optoutFailed: true, selftestFailed: nil)
            fireEvent(event: .errorOptoutFailed)
            
            if let url = URL(string: messageData.url) {
                notificationHandler?.handleOptOutFailed(for: url)
            }
        } else if messageData.scheduleSelfTest {
            selfTestWebView = message.webView
            selfTestFrameInfo = message.frameInfo
        }
        
        replyHandler([ "type": "ok" ], nil)
    }
    
    @MainActor
    private func handleOptInResult(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        Logger.autoconsent.debug("ignoring optInResult: \(String(describing: message.body))")
        replyHandler(nil, "opt-in is not supported")
    }
    
    @MainActor
    private func handleCmpDetected(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler([ "type": "ok" ], nil)
    }
    
    @MainActor
    private func handleSelfTestResult(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentSelfTestResultMessage = decodeMessageBody(from: message.body),
              let url = URL(string: messageData.url) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        Logger.autoconsent.debug("self-test result: \(String(describing: messageData))")
        refreshDashboardState(consentManaged: true, cosmetic: nil, optoutFailed: false, selftestFailed: messageData.result)
        
        notificationHandler?.handleSelfTestResult(for: url, result: messageData.result)
        fireEvent(event: messageData.result ? .selfTestOk : .selfTestFail)
        
        replyHandler([ "type": "ok" ], nil)
    }
    
    @MainActor
    private func handleAutoconsentDone(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let messageData: AutoconsentDoneMessage = decodeMessageBody(from: message.body),
              let url = URL(string: messageData.url),
              let host = url.host else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        Logger.autoconsent.debug("opt-out successful: \(String(describing: messageData))")
        
        refreshDashboardState(consentManaged: true, cosmetic: messageData.isCosmetic, optoutFailed: false, selftestFailed: nil)
        fireEvent(event: messageData.isCosmetic ? .doneCosmetic : .done)
        
        // Trigger notification once per domain
        if !management.sitesNotifiedCache.contains(host) {
            management.sitesNotifiedCache.insert(host)
            notificationHandler?.handleAutoconsentDone(for: url, isCosmetic: messageData.isCosmetic)
            fireEvent(event: messageData.isCosmetic ? .animationShownCosmetic : .animationShown)
        }
        
        replyHandler([ "type": "ok" ], nil)
        
        // Schedule self-test if needed
        if let selfTestWebView = selfTestWebView,
           let selfTestFrameInfo = selfTestFrameInfo {
            Logger.autoconsent.debug("requesting self-test in: \(messageData.url)")
            selfTestWebView.evaluateJavaScript(
                "window.autoconsentMessageCallback({ type: 'selfTest' })",
                in: selfTestFrameInfo,
                in: WKContentWorld.defaultClient
            ) { result in
                switch result {
                case .failure(let error):
                    Logger.autoconsent.error("Error running self-test: \(error.localizedDescription, privacy: .public)")
                case .success:
                    Logger.autoconsent.debug("self-test requested")
                }
            }
        }
        
        selfTestWebView = nil
        selfTestFrameInfo = nil
    }
    
    @MainActor
    private func handleAutoconsentError(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        Logger.autoconsent.error("Autoconsent error: \(String(describing: message.body))")
        fireEvent(event: .errorMultiplePopups)
        replyHandler([ "type": "ok" ], nil)
    }
    
    @MainActor
    private func handleReport(message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let report: AutoconsentReportMessage = decodeMessageBody(from: message.body) else {
            replyHandler(nil, "cannot decode message")
            return
        }
        
        // Handle heuristic matches and other reporting
        // This is typically platform-specific, so we'll let subclasses handle it
        handleReportMessage(report, message: message)
        
        replyHandler([ "type": "ok" ], nil)
    }
    
    
    private func handleReportMessage(_ report: AutoconsentReportMessage, message: WKScriptMessage) {
        // Default implementation - can be overridden by subclasses
        let heuristicMatch = report.state.heuristicPatterns.count > 0 || report.state.heuristicSnippets.count > 0
        
        if report.state.lifecycle == "nothingDetected" && heuristicMatch {
            fireEvent(event: .missedPopup)
        }

        if message.frameInfo.isMainFrame && heuristicMatch && !management.heuristicMatchCache.contains(report.instanceId) {
            management.heuristicMatchCache.insert(report.instanceId)
            fireEvent(event: .heuristicMatch)
        }
        
        if message.frameInfo.isMainFrame && heuristicMatch && report.state.detectedCmps.count > 0 && !management.heuristicMatchDetected.contains(report.instanceId) {
            management.heuristicMatchDetected.insert(report.instanceId)
            fireEvent(event: .heuristicDetected)
        }
    }

    // MARK: - Protected Methods for Subclasses

    func fireEvent(event: AutoconsentPixel) {
        if management.eventCounter.isEmpty {
            // start collection time window once the first event arrives
            management.lastEventSent = Int(Date().timeIntervalSince1970)
            DispatchQueue.global().asyncAfter(deadline: .now() + 60*2) {
                Logger.autoconsent.debug("Running delayed summary pixel")
                PixelKit.fire(AutoconsentPixel.summary(events: self.management.eventCounter), frequency: .standard)
                self.management.eventCounter = [:]
                self.management.lastEventSent = Int(Date().timeIntervalSince1970)
                self.management.heuristicMatchCache.removeAll()
                self.management.heuristicMatchDetected.removeAll()
            }
        }
        
        // increment counter
        management.eventCounter[event.key, default: 0] += 1
        
        Logger.autoconsent.debug("Autoconsent event: \(self.management.eventCounter)")
        
        // fire daily pixel if needed
        PixelKit.fire(event, frequency: .daily)
    }
} 
