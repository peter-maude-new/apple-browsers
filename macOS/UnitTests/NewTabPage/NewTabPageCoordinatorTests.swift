//
//  NewTabPageCoordinatorTests.swift
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
import NewTabPage
import PersistenceTestingUtils
import PixelKit
import PrivacyStats
import XCTest
@testable import DuckDuckGo_Privacy_Browser

final class MockPrivacyStats: PrivacyStatsCollecting {

    let statsUpdatePublisher: AnyPublisher<Void, Never> = Empty<Void, Never>().eraseToAnyPublisher()

    func recordBlockedTracker(_ name: String) async {}
    func fetchPrivacyStats() async -> [String: Int64] { [:] }
    func fetchPrivacyStatsTotalCount() async -> Int64 { 0 }
    func clearPrivacyStats() async {}
    func handleAppTermination() async {}
}

final class NewTabPageCoordinatorTests: XCTestCase {
    var coordinator: NewTabPageCoordinator!
    var appearancePreferences: AppearancePreferences!
    var customizationModel: NewTabPageCustomizationModel!
    var notificationCenter: NotificationCenter!
    var keyValueStore: MockKeyValueStore!
    var firePixelCalls: [PixelKitEvent] = []

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        notificationCenter = NotificationCenter()
        keyValueStore = MockKeyValueStore()
        firePixelCalls.removeAll()

        let appearancePreferencesPersistor = AppearancePreferencesPersistorMock()
        appearancePreferences = AppearancePreferences(persistor: appearancePreferencesPersistor)

        customizationModel = NewTabPageCustomizationModel(
            appearancePreferences: appearancePreferences,
            userBackgroundImagesManager: nil,
            sendPixel: { _ in },
            openFilePanel: { nil },
            showAddImageFailedAlert: {},
            visualStyle: VisualStyle.legacy
        )

        coordinator = NewTabPageCoordinator(
            appearancePreferences: appearancePreferences,
            customizationModel: customizationModel,
            bookmarkManager: MockBookmarkManager(),
            activeRemoteMessageModel: ActiveRemoteMessageModel(
                remoteMessagingStore: MockRemoteMessagingStore(),
                remoteMessagingAvailabilityProvider: MockRemoteMessagingAvailabilityProvider(),
                openURLHandler: { _ in }
            ),
            historyCoordinator: HistoryCoordinatingMock(),
            privacyStats: MockPrivacyStats(),
            freemiumDBPPromotionViewCoordinator: FreemiumDBPPromotionViewCoordinator(
                freemiumDBPUserStateManager: MockFreemiumDBPUserStateManager(),
                freemiumDBPFeature: MockFreemiumDBPFeature(),
                freemiumDBPPresenter: MockFreemiumDBPPresenter(),
                notificationCenter: notificationCenter,
                freemiumDBPExperimentPixelHandler: MockFreemiumDBPExperimentPixelHandler()
            ),
            keyValueStore: keyValueStore,
            notificationCenter: notificationCenter,
            fireDailyPixel: { self.firePixelCalls.append($0) }
        )
    }

    func testWhenNewTabPageAppearsThenPixelIsSent() {
        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        XCTAssertEqual(firePixelCalls.count, 1)
    }

    func testWhenFavoritesIsVisibleThenPixelSetsTrueForFavorites() throws {
        appearancePreferences.isFavoriteVisible = true

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(favorites: true, _, _):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }

    func testWhenFavoritesIsNotVisibleThenPixelSetsFalseForFavorites() throws {
        appearancePreferences.isFavoriteVisible = false

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(favorites: false, _, _):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }

    func testWhenProtectionReportIsVisibleThenPixelSetsTrueForFavorites() throws {
        appearancePreferences.isProtectionsVisible = true

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(_, protections: true, _):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }

    func testWhenProtectionReportIsNotVisibleThenPixelSetsFalseForFavorites() throws {
        appearancePreferences.isProtectionsVisible = false

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(_, protections: false, _):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }

    func testWhenBackgroundIsCustomThenPixelSetsTrueForCustomBackground() throws {
        customizationModel.customBackground = .gradient(.gradient02)

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(_, _, customBackground: true):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }

    func testWhenBackgroundIsDefaultThenPixelSetsFalseForCustomBackground() throws {
        customizationModel.customBackground = nil

        notificationCenter.post(name: .newTabPageWebViewDidAppear, object: nil)
        let pixel = try XCTUnwrap(firePixelCalls.first as? NewTabPagePixel)

        switch pixel {
        case .newTabPageShown(_, _, customBackground: false):
            break
        default:
            XCTFail("Unexpected pixel value: \(pixel)")
        }
    }
}
