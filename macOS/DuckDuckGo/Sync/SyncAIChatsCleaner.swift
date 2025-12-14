//
//  SyncAIChatsCleaner.swift
//  DuckDuckGo
//
//  Coordinates server-side AI Chat deletion to mirror local clears (Fire/AutoClear).
//

import BrowserServicesKit
import DDGSync
import FeatureFlags
import Foundation
import Persistence
import os.log

/// Coordinates server-side AI Chat deletion to mirror local clears (Fire/AutoClear).
/// Stores a timestamp when local data is cleared and retries the DELETE on next trigger until it succeeds.
protocol SyncAIChatsCleaning: AnyObject {
    func recordLocalClear(date: Date?)
    func markChatHistoryEnabled()
    func deleteIfNeeded() async
}

final class SyncAIChatsCleaner: SyncAIChatsCleaning {

    enum Keys {
        static let lastClearTimestamp = "com.duckduckgo.aichat.sync.lastClearTimestamp"
        static let chatHistoryEnabled = "com.duckduckgo.aichat.sync.chatHistoryEnabled"
    }

    private let sync: DDGSyncing
    private let keyValueStore: ThrowingKeyValueStoring
    private let featureFlagger: FeatureFlagger
    private let dateProvider: () -> Date

    private var canUseAIChatSyncDelete: Bool {
        guard featureFlagger.isFeatureOn(.aiChatSync) else {
            return false
        }

        guard sync.authState != .inactive else {
            return false
        }

        return isChatHistoryEnabled
    }

    private var isChatHistoryEnabled: Bool {
        (try? keyValueStore.object(forKey: Keys.chatHistoryEnabled) as? Bool) == true
    }

    init(sync: DDGSyncing,
         keyValueStore: ThrowingKeyValueStoring,
         featureFlagger: FeatureFlagger,
         dateProvider: @escaping () -> Date = Date.init) {
        self.sync = sync
        self.keyValueStore = keyValueStore
        self.featureFlagger = featureFlagger
        self.dateProvider = dateProvider
    }

    /// Record the time of a local clear (Fire/autoclear). This timestamp will be used for the next delete call.
    func recordLocalClear(date: Date? = nil) {
        guard canUseAIChatSyncDelete else {
            return
        }

        let timestamp = (date ?? dateProvider()).timeIntervalSince1970
        try? keyValueStore.set(timestamp, forKey: Keys.lastClearTimestamp)
    }

    /// Record if getSyncStatus was ever called by FE (assuming it will only have been called if user has chat history turned on.)
    func markChatHistoryEnabled() {
        try? keyValueStore.set(true, forKey: Keys.chatHistoryEnabled)
    }

    /// If a clear timestamp exists, attempt to delete AI Chats up to that time on the server.
    /// On success, the timestamp is removed; on failure it is retained for a later retry.
    func deleteIfNeeded() async {
        guard canUseAIChatSyncDelete else {
            return
        }

        guard let timestampValue = try? keyValueStore.object(forKey: Keys.lastClearTimestamp) as? Double else {
            return
        }

        let untilDate = Date(timeIntervalSince1970: timestampValue)
        Logger.sync.debug("Deleting AI Chats up until \(untilDate)")

        do {
            try await sync.deleteAIChats(until: untilDate)

            // Only clear the stored timestamp if it hasn't been updated since we read it.
            if let currentTimestamp = try? keyValueStore.object(forKey: Keys.lastClearTimestamp) as? Double,
               currentTimestamp == timestampValue {
                try? keyValueStore.removeObject(forKey: Keys.lastClearTimestamp)
            }
        } catch {
            Logger.sync.debug("Failed to delete AI Chats: \(error)")
        }
    }
}


