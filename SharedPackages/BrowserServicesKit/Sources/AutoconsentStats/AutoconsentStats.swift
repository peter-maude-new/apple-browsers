//
//  AutoconsentStats.swift
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
import Persistence
import BrowserServicesKit

public protocol AutoconsentStatsCollecting {
    /**
     * Record an autoconsent action with interaction metrics.
     * - Parameters:
     *   - clicksMade: The number of clicks made during the autoconsent interaction
     *   - timeSpent: The time spent handling the autoconsent interaction
     */
    func recordAutoconsentAction(clicksMade: Int64, timeSpent: TimeInterval) async

    /**
     * This function fetches total count of cookie pop ups blocked.
     */
    func fetchTotalCookiePopUpsBlocked() async -> Int64

    /**
     * This function fetches total count of clicks made blocking pop ups.
     */
    func fetchTotalClicksMadeBlockingCookiePopUps() async -> Int64

    /**
     * This function fetches total time spent on blocking cookie pop ups.
     */
    func fetchTotalTotalTimeSpentBlockingCookiePopUps() async -> TimeInterval

    /**
     * This function fetches the daily usage pack containing all autoconsent statistics.
     */
    func fetchAutoconsentDailyUsagePack() async -> AutoconsentDailyUsagePack

    /**
     * This function clears all autoconsent stats from the storage.
     */
    func clearAutoconsentStats() async
}

public actor AutoconsentStats: AutoconsentStatsCollecting {

    public enum Constants {
        public static let totalCookiePopUpsBlockedKey = "com.duckduckgo.autoconsent.cookie.popups.blocked"
        public static let totalClicksMadeBlockingCookiePopUpsKey = "com.duckduckgo.autoconsent.clicks.made"
        public static let totalTimeSpentBlockingCookiePopUpsKey = "com.duckduckgo.autoconsent.time.spent"
    }

    private let keyValueStore: ThrowingKeyValueStoring
    private let featureFlagger: FeatureFlagger

    public init(keyValueStore: ThrowingKeyValueStoring,
                featureFlagger: FeatureFlagger) {
        self.keyValueStore = keyValueStore
        self.featureFlagger = featureFlagger
    }

    public func recordAutoconsentAction(clicksMade: Int64, timeSpent: TimeInterval) async {
        do {
            let currentStats = await fetchAutoconsentDailyUsagePack()

            let newTotalCookiePopUpsBlocked = currentStats.totalCookiePopUpsBlocked + 1
            try keyValueStore.set(newTotalCookiePopUpsBlocked, forKey: Constants.totalCookiePopUpsBlockedKey)

            let newTotalClicks = currentStats.totalClicksMadeBlockingCookiePopUps + clicksMade
            try keyValueStore.set(newTotalClicks, forKey: Constants.totalClicksMadeBlockingCookiePopUpsKey)

            let newTotalTimeSpent = currentStats.totalTotalTimeSpentBlockingCookiePopUps + timeSpent
            try keyValueStore.set(newTotalTimeSpent, forKey: Constants.totalTimeSpentBlockingCookiePopUpsKey)

        } catch {
            // Logger.autoconsent.error("Failed to record autoconsent action: \(error.localizedDescription)")
            return
        }
    }
    
    public func fetchTotalCookiePopUpsBlocked() async -> Int64 {
        do {
            if let value = try keyValueStore.object(forKey: Constants.totalCookiePopUpsBlockedKey) as? Int64 {
                return value
            }
            return 0
        } catch {
            return 0
        }
    }
    
    public func fetchTotalClicksMadeBlockingCookiePopUps() async -> Int64 {
        do {
            if let value = try keyValueStore.object(forKey: Constants.totalClicksMadeBlockingCookiePopUpsKey) as? Int64 {
                return value
            }
            return 0
        } catch {
            return 0
        }
    }
    
    public func fetchTotalTotalTimeSpentBlockingCookiePopUps() async -> TimeInterval {
        do {
            if let value = try keyValueStore.object(forKey: Constants.totalTimeSpentBlockingCookiePopUpsKey) as? TimeInterval {
                return value
            }
            return 0
        } catch {
            return 0
        }
    }

    public func fetchAutoconsentDailyUsagePack() async -> AutoconsentDailyUsagePack {
        let totalCookiePopUpsBlocked = await fetchTotalCookiePopUpsBlocked()
        let totalClicksMade = await fetchTotalClicksMadeBlockingCookiePopUps()
        let totalTimeSpent = await fetchTotalTotalTimeSpentBlockingCookiePopUps()
        
        return AutoconsentDailyUsagePack(
            totalCookiePopUpsBlocked: totalCookiePopUpsBlocked,
            totalClicksMadeBlockingCookiePopUps: totalClicksMade,
            totalTotalTimeSpentBlockingCookiePopUps: totalTimeSpent
        )
    }
    
    public func clearAutoconsentStats() async {
        do {
            try keyValueStore.removeObject(forKey: Constants.totalCookiePopUpsBlockedKey)
            try keyValueStore.removeObject(forKey: Constants.totalClicksMadeBlockingCookiePopUpsKey)
            try keyValueStore.removeObject(forKey: Constants.totalTimeSpentBlockingCookiePopUpsKey)
        } catch {
            // Logger.autoconsent.error("Failed to clear autoconsent stats: \(error.localizedDescription)")
        }
    }
}
