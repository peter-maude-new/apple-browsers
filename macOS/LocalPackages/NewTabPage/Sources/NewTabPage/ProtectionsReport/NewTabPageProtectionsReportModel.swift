//
//  NewTabPageProtectionsReportModel.swift
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

import Combine
import Common
import Foundation
import os.log
import Persistence
import PrivacyStats

public protocol NewTabPageProtectionReportSettingsPersistor: AnyObject {
    var activeFeed: NewTabPageDataModel.Feed { get set }
    var isViewExpanded: Bool { get set }
}

final class UserDefaultsNewTabPageProtectionReportSettingsPersistor: NewTabPageProtectionReportSettingsPersistor {
    enum Keys {
        static let isViewExpanded = "new-tab-page.protection-report.is-view-expanded"
        static let activeFeed = "new-tab-page.protection-report.active-feed"
    }

    private let keyValueStore: KeyValueStoring

    init(_ keyValueStore: KeyValueStoring = UserDefaults.standard, getLegacySetting: @autoclosure () -> Bool?) {
        self.keyValueStore = keyValueStore
        migrateFromLegacyHomePageSettings(using: getLegacySetting)
    }

    var isViewExpanded: Bool {
        get { return keyValueStore.object(forKey: Keys.isViewExpanded) as? Bool ?? true }
        set { keyValueStore.set(newValue, forKey: Keys.isViewExpanded) }
    }

    var activeFeed: NewTabPageDataModel.Feed {
        get { return (keyValueStore.object(forKey: Keys.activeFeed) as? String).flatMap(NewTabPageDataModel.Feed.init) ?? .activity }
        set { keyValueStore.set(newValue.rawValue, forKey: Keys.activeFeed)}
    }

    private func migrateFromLegacyHomePageSettings(using getLegacySetting: () -> Bool?) {
        guard keyValueStore.object(forKey: Keys.isViewExpanded) == nil, let legacySetting = getLegacySetting() else {
            return
        }
        isViewExpanded = legacySetting
    }
}

public final class NewTabPageProtectionReportModel {

    let privacyStats: PrivacyStatsCollecting
    let statsUpdatePublisher: AnyPublisher<Void, Never>

    @Published var isViewExpanded: Bool {
        didSet {
            settingsPersistor.isViewExpanded = self.isViewExpanded
        }
    }

    @Published var activeFeed: NewTabPageDataModel.Feed {
        didSet {
            settingsPersistor.activeFeed = self.activeFeed
        }
    }

    private let settingsPersistor: NewTabPageProtectionReportSettingsPersistor

    private let statsUpdateSubject = PassthroughSubject<Void, Never>()
    private var cancellables: Set<AnyCancellable> = []

    public convenience init(
        privacyStats: PrivacyStatsCollecting,
        keyValueStore: KeyValueStoring = UserDefaults.standard,
        getLegacyIsViewExpandedSetting: @autoclosure () -> Bool?
    ) {
        let settingsPersistor = UserDefaultsNewTabPageProtectionReportSettingsPersistor(keyValueStore, getLegacySetting: getLegacyIsViewExpandedSetting())
        self.init(privacyStats: privacyStats, settingsPersistor: settingsPersistor)
    }

    init(privacyStats: PrivacyStatsCollecting, settingsPersistor: NewTabPageProtectionReportSettingsPersistor) {
        self.privacyStats = privacyStats
        self.settingsPersistor = settingsPersistor

        isViewExpanded = settingsPersistor.isViewExpanded
        activeFeed = settingsPersistor.activeFeed
        statsUpdatePublisher = statsUpdateSubject.eraseToAnyPublisher()

        privacyStats.statsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.statsUpdateSubject.send()
            }
            .store(in: &cancellables)
    }

    func calculateTotalCount() async -> Int64 {
        await privacyStats.fetchPrivacyStatsTotalCount()
    }
}

