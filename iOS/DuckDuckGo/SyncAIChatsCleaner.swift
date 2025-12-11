//
//  SyncAIChatsCleaner.swift
//  DuckDuckGo
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
import DDGSync
import Persistence
import os.log

/// Coordinates server-side AI Chat deletion to mirror local clears (Fire/AutoClear).
/// Stores a timestamp when local data is cleared and retries the DELETE on next trigger until it succeeds.
protocol SyncAIChatsCleaning {
    func recordLocalClear(date: Date?)
    func markChatHistoryEnabled()
    func deleteIfNeeded() async
}

final class SyncAIChatsCleaner: SyncAIChatsCleaning {

    private enum Keys {
        static let lastClearTimestamp = "com.duckduckgo.aichat.lastClearTimestamp"
        static let chatHistoryEnabled = "com.duckduckgo.aichat.chatHistoryEnabled"
    }

    private let sync: DDGSyncing
    private let keyValueStore: ThrowingKeyValueStoring
    private let dateProvider: () -> Date

    init(sync: DDGSyncing,
         keyValueStore: ThrowingKeyValueStoring,
         dateProvider: @escaping () -> Date = Date.init) {
        self.sync = sync
        self.keyValueStore = keyValueStore
        self.dateProvider = dateProvider
    }

    /// Record the time of a local clear (Fire/autoclear). This timestamp will be used for the next delete call.
    func recordLocalClear(date: Date? = nil) {
        let timestamp = (date ?? dateProvider()).timeIntervalSince1970
        try? keyValueStore.set(timestamp, forKey: Keys.lastClearTimestamp)
    }

    /// Record if getSyncStatus was ever called by FE (assuming it will only have been  called if user has chat history turned on.)
    func markChatHistoryEnabled() {
        try? keyValueStore.set(true, forKey: Keys.chatHistoryEnabled)
    }

    /// If a clear timestamp exists, attempt to delete AI Chats up to that time on the server.
    /// On success, the timestamp is removed; on failure it is retained for a later retry.
    func deleteIfNeeded() async {
        guard sync.authState != .inactive else {
            return
        }

        guard let chatHistoryEnabled = try? keyValueStore.object(forKey: Keys.chatHistoryEnabled) as? Bool,
              chatHistoryEnabled else {
            return
        }

        guard let timestampValue = try? keyValueStore.object(forKey: Keys.lastClearTimestamp) as? Double else {
            return
        }

        let untilDate = Date(timeIntervalSince1970: timestampValue)

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
