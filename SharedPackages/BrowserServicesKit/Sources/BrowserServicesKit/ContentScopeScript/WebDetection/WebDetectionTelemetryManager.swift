//
//  WebDetectionTelemetryManager.swift
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

/// Manages telemetry for web detection (e.g., adwall detection).
///
/// This class handles:
/// - Deduplication of telemetry events per page
/// - Incrementing daily and weekly counters
/// - Firing daily and weekly pixels
public final class WebDetectionTelemetryManager: WebDetectionTelemetryHandling {

    // MARK: - Types

    /// Storage protocol for persisting telemetry counters.
    /// Must be a class type to ensure mutations persist (not copied).
    public protocol CounterStorage: AnyObject {
        var dailyAdwallCount: Int { get set }
        var weeklyAdwallCount: Int { get set }
        var lastDailyPixelDate: Date? { get set }
        var lastWeeklyPixelDate: Date? { get set }
    }

    /// Delegate for firing pixels.
    public protocol PixelFiring: AnyObject {
        func fireAdwallDailyPixel(count: Int)
        func fireAdwallWeeklyPixel(count: Int)
    }

    // MARK: - Properties

    private let storage: CounterStorage
    private weak var pixelFiring: PixelFiring?
    private let calendar: Calendar
    private let lock = NSLock()

    /// Feature flags for controlling telemetry behavior.
    public var adwallTelemetryPixelEnabled: Bool = true
    public var adwallZeroCountPixelEnabled: Bool = true

    // MARK: - Initialization

    public init(storage: CounterStorage,
                pixelFiring: PixelFiring?,
                calendar: Calendar = .current) {
        self.storage = storage
        self.pixelFiring = pixelFiring
        self.calendar = calendar
    }

    // MARK: - WebDetectionTelemetryHandling

    public func handleTelemetry(type: String, detectorId: String) {
        guard type == "adwall" else { return }

        incrementAdwallCounters()
    }

    // MARK: - Counter Management

    private func incrementAdwallCounters() {
        lock.lock()
        defer { lock.unlock() }
        storage.dailyAdwallCount += 1
        storage.weeklyAdwallCount += 1
    }

    // MARK: - Pixel Firing

    /// Called periodically (e.g., on app launch or timer) to fire daily/weekly pixels.
    public func firePixelsIfNeeded() {
        guard adwallTelemetryPixelEnabled else { return }

        fireDailyPixelIfNeeded()
        fireWeeklyPixelIfNeeded()
    }

    private func fireDailyPixelIfNeeded() {
        lock.lock()
        let now = Date()

        // Check if a day has passed since last daily pixel
        if let lastDate = storage.lastDailyPixelDate,
           calendar.isDate(lastDate, inSameDayAs: now) {
            lock.unlock()
            return // Already fired today
        }

        let count = storage.dailyAdwallCount

        // Reset daily counter and update last pixel date
        storage.dailyAdwallCount = 0
        storage.lastDailyPixelDate = now
        lock.unlock()

        // Fire pixel outside lock (count > 0 or zero-count pixels are enabled)
        if count > 0 || adwallZeroCountPixelEnabled {
            pixelFiring?.fireAdwallDailyPixel(count: count)
        }
    }

    private func fireWeeklyPixelIfNeeded() {
        lock.lock()
        let now = Date()

        // Check if a week has passed since last weekly pixel
        if let lastDate = storage.lastWeeklyPixelDate {
            if let daysSinceLastPixel = calendar.dateComponents([.day], from: lastDate, to: now).day,
               daysSinceLastPixel < 7 {
                lock.unlock()
                return // Not yet a week
            }
        }

        let count = storage.weeklyAdwallCount

        // Reset weekly counter and update last pixel date
        storage.weeklyAdwallCount = 0
        storage.lastWeeklyPixelDate = now
        lock.unlock()

        // Fire pixel outside lock (count > 0 or zero-count pixels are enabled)
        if count > 0 || adwallZeroCountPixelEnabled {
            pixelFiring?.fireAdwallWeeklyPixel(count: count)
        }
    }
}

// MARK: - UserDefaults Storage Implementation

/// Default implementation of CounterStorage using UserDefaults.
public final class WebDetectionUserDefaultsStorage: WebDetectionTelemetryManager.CounterStorage {

    private let userDefaults: UserDefaults
    private let dailyCountKey = "com.duckduckgo.webdetection.adwall.dailyCount"
    private let weeklyCountKey = "com.duckduckgo.webdetection.adwall.weeklyCount"
    private let lastDailyDateKey = "com.duckduckgo.webdetection.adwall.lastDailyDate"
    private let lastWeeklyDateKey = "com.duckduckgo.webdetection.adwall.lastWeeklyDate"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var dailyAdwallCount: Int {
        get { userDefaults.integer(forKey: dailyCountKey) }
        set { userDefaults.set(newValue, forKey: dailyCountKey) }
    }

    public var weeklyAdwallCount: Int {
        get { userDefaults.integer(forKey: weeklyCountKey) }
        set { userDefaults.set(newValue, forKey: weeklyCountKey) }
    }

    public var lastDailyPixelDate: Date? {
        get { userDefaults.object(forKey: lastDailyDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastDailyDateKey) }
    }

    public var lastWeeklyPixelDate: Date? {
        get { userDefaults.object(forKey: lastWeeklyDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastWeeklyDateKey) }
    }
}
