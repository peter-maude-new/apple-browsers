//
//  AutoconsentStats.swift
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
     * This function clears all autoconsent stats from the storage.
     */
    func clearAutoconsentStats() async
}

public final class AutoconsentStats: AutoconsentStatsCollecting {

    enum Constants {
        public static let totalCookiePopUpsBlockedKey = "com.duckduckgo.autoconsent.cookie.popups.blocked"
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
            let currentTotalCookiePopUpsBlocked: Int

            if let totalCookiePopUpsBlocked = try keyValueStore.object(forKey: Constants.totalCookiePopUpsBlockedKey) as? Int {
                currentTotalCookiePopUpsBlocked = totalCookiePopUpsBlocked
            }  else {
                print(" --- recordAutoconsentAction error - totalCookiePopUpsBlocked missing setting 0")
                currentTotalCookiePopUpsBlocked = 0
            }

            print(" --- totalCookiePopUpsBlocked: \(currentTotalCookiePopUpsBlocked) ")
            try keyValueStore.set(currentTotalCookiePopUpsBlocked + 1, forKey: Constants.totalCookiePopUpsBlockedKey)

        } catch {
            print(" --- recordAutoconsentAction error !!1!!!1!")
//            Logger.autoconsent.error("Failed to read daily stats: \(error.localizedDescription)")
            return
        }
    }
    
    public func fetchTotalCookiePopUpsBlocked() -> Int64 {
        return 0
    }
    
    public func fetchTotalClicksMadeBlockingCookiePopUps() -> Int64 {
        return 0
    }
    
    public func fetchTotalTotalTimeSpentBlockingCookiePopUps() -> TimeInterval {
        return 0
    }
    
    public func clearAutoconsentStats() async {

    }
}
