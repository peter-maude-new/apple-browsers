//
//  NewTabPageStateProviderTests.swift
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
import XCTest
@testable import DuckDuckGo_Privacy_Browser
@testable import NewTabPage

final class NewTabPageStateProviderTests: XCTestCase {

    var provider: NewTabPageStateProvider!
    var windowControllersManager: WindowControllersManagerMock!
    var featureFlagger: MockFeatureFlagger!
    var tabsChangedSubject: PassthroughSubject<Void, Never>!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        windowControllersManager = WindowControllersManagerMock()
        featureFlagger = MockFeatureFlagger()
        tabsChangedSubject = PassthroughSubject<Void, Never>()
        cancellables = []

        // Set up the tabsChanged publisher on the mock BEFORE creating the provider
        windowControllersManager.tabsChanged = tabsChangedSubject.eraseToAnyPublisher()
    }

    override func tearDown() {
        provider = nil
        windowControllersManager = nil
        featureFlagger = nil
        tabsChangedSubject = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Feature Flag Tests

    @MainActor
    func testGetState_whenNewTabPageTabIDsDisabled_returnsNil() {
        // Given: Both feature flags disabled
        featureFlagger.enabledFeatureFlags = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When
        let state = provider.getState()

        // Then
        XCTAssertNil(state, "Should return nil when newTabPageTabIDs is disabled")
    }

    @MainActor
    func testGetState_whenNewTabPagePerTabEnabled_returnsNil() {
        // Given: Both flags enabled (per-tab mode takes precedence)
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs, .newTabPagePerTab]
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When
        let state = provider.getState()

        // Then
        XCTAssertNil(state, "Should return nil when newTabPagePerTab is enabled (incompatible mode)")
    }

    @MainActor
    func testGetState_whenNewTabPageTabIDsEnabledAndPerTabDisabled_returnsNonNil() {
        // Given: Only newTabPageTabIDs enabled (correct configuration)
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        windowControllersManager.mainWindowControllers = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When
        let state = provider.getState()

        // Then
        XCTAssertNotNil(state, "Should return non-nil state when newTabPageTabIDs is enabled and newTabPagePerTab is disabled")
    }

    @MainActor
    func testGetState_whenOnlyPerTabEnabled_returnsNil() {
        // Given: Only newTabPagePerTab enabled (without tabIDs)
        featureFlagger.enabledFeatureFlags = [.newTabPagePerTab]
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When
        let state = provider.getState()

        // Then
        XCTAssertNil(state, "Should return nil when only newTabPagePerTab is enabled")
    }

    // MARK: - State Collection Tests

    @MainActor
    func testGetState_withNoWindows_returnsEmptyArray() {
        // Given: Feature enabled but no windows
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        windowControllersManager.mainWindowControllers = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When
        let state = provider.getState()

        // Then
        XCTAssertNotNil(state, "Should return non-nil when feature is enabled")
        XCTAssertEqual(state?.count, 0, "Should return empty array when no windows exist")
    }

    // MARK: - Publisher Tests

    @MainActor
    func testStateChangedPublisher_whenNewTabPageTabIDsDisabled_doesNotEmit() {
        // Given: Feature flag disabled
        featureFlagger.enabledFeatureFlags = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        var emissionCount = 0
        provider.stateChangedPublisher
            .sink { _ in emissionCount += 1 }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()
        tabsChangedSubject.send()

        // Then
        XCTAssertEqual(emissionCount, 0, "Publisher should not emit when newTabPageTabIDs is disabled")
    }

    @MainActor
    func testStateChangedPublisher_whenNewTabPagePerTabEnabled_doesNotEmit() {
        // Given: Both flags enabled (per-tab mode)
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs, .newTabPagePerTab]
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        var emissionCount = 0
        provider.stateChangedPublisher
            .sink { _ in emissionCount += 1 }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()
        tabsChangedSubject.send()

        // Then
        XCTAssertEqual(emissionCount, 0, "Publisher should not emit when newTabPagePerTab is enabled")
    }

    @MainActor
    func testStateChangedPublisher_whenFeaturesProperlyEnabled_emitsOnTabChanges() {
        // Given: Correct configuration (tabIDs on, perTab off)
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        let tabsChangedSubject = PassthroughSubject<Void, Never>()
        windowControllersManager.tabsChanged = tabsChangedSubject.eraseToAnyPublisher()

        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        let expectation = expectation(description: "Publisher emits 3 times")
        expectation.expectedFulfillmentCount = 3

        provider.stateChangedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()
        tabsChangedSubject.send()
        tabsChangedSubject.send()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testStateChangedPublisher_filterConsistencyWithGetState() {
        // Given: Correct configuration
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        let tabsChangedSubject = PassthroughSubject<Void, Never>()
        windowControllersManager.tabsChanged = tabsChangedSubject.eraseToAnyPublisher()

        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        let expectation = expectation(description: "Publisher emission")
        provider.stateChangedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()

        // Then: Publisher and getState() should be consistent
        wait(for: [expectation], timeout: 1.0)
        let state = provider.getState()
        XCTAssertNotNil(state, "getState() should return non-nil when publisher emits")
    }

    @MainActor
    func testStateChangedPublisher_filterConsistencyWhenDisabled() {
        // Given: Feature disabled
        featureFlagger.enabledFeatureFlags = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        var publisherEmitted = false
        provider.stateChangedPublisher
            .sink { _ in publisherEmitted = true }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()
        let state = provider.getState()

        // Then: Both should indicate disabled state
        XCTAssertFalse(publisherEmitted, "Publisher should not have emitted")
        XCTAssertNil(state, "getState() should return nil when publisher doesn't emit")
    }

    @MainActor
    func testStateChangedPublisher_receivesOnMainQueue() {
        // Given
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        let expectation = expectation(description: "Publisher emission on main queue")
        provider.stateChangedPublisher
            .sink { _ in
                XCTAssertTrue(Thread.isMainThread, "Publisher should emit on main queue")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        tabsChangedSubject.send()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Dynamic Feature Flag Tests

    @MainActor
    func testPublisherFilter_checksFeatureFlagDynamically() {
        // Given: Start with feature disabled
        featureFlagger.enabledFeatureFlags = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        var emissions: [Bool] = []
        provider.stateChangedPublisher
            .sink { _ in emissions.append(true) }
            .store(in: &cancellables)

        // When: Trigger event while disabled
        tabsChangedSubject.send()

        // Then: No emission (check synchronously - no async delay expected when filtered out)
        XCTAssertEqual(emissions.count, 0, "Should not emit while disabled")

        // When: Enable feature and trigger again
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        let expectation = expectation(description: "Publisher emits after flag enabled")
        provider.stateChangedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        tabsChangedSubject.send()

        // Then: Should emit now (filter checks flag dynamically)
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotEqual(emissions.count, 0, "Should emit after flag is enabled (filter is dynamic)")
    }

    @MainActor
    func testGetState_checksFeatureFlagDynamically() {
        // Given: Create provider with flag disabled
        featureFlagger.enabledFeatureFlags = []
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        // When: Check state while disabled
        let stateWhileDisabled = provider.getState()

        // Then: Returns nil
        XCTAssertNil(stateWhileDisabled)

        // When: Enable flag and check again
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        let stateWhileEnabled = provider.getState()

        // Then: Now returns non-nil
        XCTAssertNotNil(stateWhileEnabled, "getState() should check flag dynamically")
    }

    @MainActor
    func testPublisherAndGetState_remainConsistentWhenFlagChanges() {
        // Given: Start enabled
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        provider = NewTabPageStateProvider(
            windowControllersManager: windowControllersManager,
            featureFlagger: featureFlagger
        )

        var publisherEmitted = false
        provider.stateChangedPublisher
            .sink { _ in publisherEmitted = true }
            .store(in: &cancellables)

        // When: Disable flag
        featureFlagger.enabledFeatureFlags = []
        tabsChangedSubject.send()
        let stateAfterDisable = provider.getState()

        // Then: Both should indicate disabled
        XCTAssertFalse(publisherEmitted, "Publisher should not emit after flag disabled")
        XCTAssertNil(stateAfterDisable, "getState() should return nil after flag disabled")

        // When: Re-enable flag
        featureFlagger.enabledFeatureFlags = [.newTabPageTabIDs]
        let expectation = expectation(description: "Publisher emits after flag re-enabled")
        provider.stateChangedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        tabsChangedSubject.send()

        // Then: Both should indicate enabled
        wait(for: [expectation], timeout: 1.0)
        let stateAfterReenable = provider.getState()
        XCTAssertNotNil(stateAfterReenable, "getState() should return non-nil after flag re-enabled")
    }
}
