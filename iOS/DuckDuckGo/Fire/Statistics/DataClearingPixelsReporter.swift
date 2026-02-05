//
//  DataClearingPixelsReporter.swift
//  DuckDuckGo
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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
import PixelKit

final class DataClearingPixelsReporter {

    // MARK: - Supporting Types

    enum ClearingTrigger: String {
        case manualFire
        case autoClearOnLaunch
        case autoClearOnForeground
    }

    enum ClearingScope: String {
        case tab
        case all
    }

    enum ClearingOption: String {
        case tab
        case data
        case aichats
        case all
    }

    enum WebsiteDataStep: String {
        case safelyRemovableData
        case fireproofableData
        case cookies
    }

    // MARK: - Properties

    var endDateProvider: () -> Date
    private let pixelFiring: PixelFiring?

    @MainActor
    private var lastFireTime: Date?
    private let retriggerWindow: TimeInterval = 20.0

    // MARK: - Initialization

    init(pixelFiring: PixelFiring? = PixelKit.shared,
         endDateProvider: @escaping () -> Date = { Date() }) {
        self.pixelFiring = pixelFiring
        self.endDateProvider = endDateProvider
    }

    // MARK: - Overall Flow Metrics

    func fireClearingCompletionPixel(from startTime: Date,
                                     request: FireRequest) {
        pixelFiring?.fire(
            DataClearingPixels.clearingCompletion(
                duration: prepareDuration(from: startTime, to: endDateProvider()),
                option: request.options.description,
                trigger: request.trigger.description,
                scope: request.scope.description
            ),
            frequency: .standard
        )
    }

    @MainActor
    func fireRetriggerPixelIfNeeded() {
        let now = endDateProvider()
        if let lastFire = lastFireTime, now.timeIntervalSince(lastFire) <= retriggerWindow {
            pixelFiring?.fire(DataClearingPixels.retriggerIn20s, frequency: .standard)
        }
        lastFireTime = now
    }

    func fireUserActionBeforeCompletionPixel() {
        pixelFiring?.fire(DataClearingPixels.userActionBeforeCompletion, frequency: .standard)
    }

    // MARK: - Per-Action Quality Metrics

    func fireDurationPixel(_ durationPixel: @escaping (Int) -> DataClearingPixels,
                           from startTime: Date) {
        pixelFiring?.fire(
            durationPixel(prepareDuration(from: startTime, to: endDateProvider())),
            frequency: .standard
        )
    }
    
    func fireResiduePixelIfNeeded(_ residuePixel: DataClearingPixels, check: () -> Bool) {
        if check() {
            pixelFiring?.fire(residuePixel, frequency: .standard)
        }
    }

    func fireResiduePixel(_ residuePixel: DataClearingPixels) {
        pixelFiring?.fire(residuePixel, frequency: .standard)
    }

    func fireErrorPixel(_ errorPixel: DataClearingPixels) {
        pixelFiring?.fire(errorPixel, frequency: .dailyAndCount)
    }
}

// MARK: - Private Helpers

private extension DataClearingPixelsReporter {

    func prepareDuration(from startTime: Date, to endTime: Date) -> Int {
        Int(endTime.timeIntervalSince(startTime) * 1000)
    }
}
