//
//  VPNEnabledObserverTests.swift
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

import XCTest
import NetworkExtension
@testable import VPN

/// Tests for VPNEnabledObserverThroughSession.
///
/// The observer now separates connection status from on-demand status updates to prevent
/// a bug where `.NEVPNConfigurationChange` notifications could incorrectly set `isVPNEnabled = false`
/// when `activeSession()` returned nil (due to race conditions or manager reloading).
///
/// Key behaviors:
/// - `.NEVPNStatusDidChange` updates both connection status and on-demand status (reliable - uses notification's session)
/// - `.NEVPNConfigurationChange` only updates on-demand status (conservative - if session unavailable, no update)
/// - `isVPNEnabled` is recalculated from stored state whenever either value changes
///
/// Note: Full integration testing of notification handling requires mocking `NETunnelProviderSession`
/// which is not easily achievable. These tests focus on the core `isVPNEnabled` calculation logic.
final class VPNEnabledObserverTests: XCTestCase {

    // MARK: - Connected Status Tests

    func testIsVPNEnabled_whenConnected_withoutOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .connected,
            isOnDemandEnabled: false
        )
        XCTAssertTrue(result)
    }

    func testIsVPNEnabled_whenConnected_withOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .connected,
            isOnDemandEnabled: true
        )
        XCTAssertTrue(result)
    }

    // MARK: - Connecting Status Tests

    func testIsVPNEnabled_whenConnecting_withoutOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .connecting,
            isOnDemandEnabled: false
        )
        XCTAssertTrue(result)
    }

    // MARK: - Reasserting Status Tests

    func testIsVPNEnabled_whenReasserting_withoutOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .reasserting,
            isOnDemandEnabled: false
        )
        XCTAssertTrue(result)
    }

    // MARK: - Disconnected with On-Demand Tests

    func testIsVPNEnabled_whenDisconnected_withOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .disconnected,
            isOnDemandEnabled: true
        )
        XCTAssertTrue(result)
    }

    func testIsVPNEnabled_whenDisconnected_withoutOnDemand_returnsFalse() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .disconnected,
            isOnDemandEnabled: false
        )
        XCTAssertFalse(result)
    }

    // MARK: - Invalid Status Tests (Edge Case)

    func testIsVPNEnabled_whenInvalid_withOnDemand_returnsFalse() {
        // Edge case: Config deleted but isOnDemandEnabled returns stale true
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .invalid,
            isOnDemandEnabled: true
        )
        XCTAssertFalse(result)
    }

    func testIsVPNEnabled_whenInvalid_withoutOnDemand_returnsFalse() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .invalid,
            isOnDemandEnabled: false
        )
        XCTAssertFalse(result)
    }

    // MARK: - Disconnecting Status Tests

    func testIsVPNEnabled_whenDisconnecting_withOnDemand_returnsTrue() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .disconnecting,
            isOnDemandEnabled: true
        )
        XCTAssertTrue(result)
    }

    func testIsVPNEnabled_whenDisconnecting_withoutOnDemand_returnsFalse() {
        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: .disconnecting,
            isOnDemandEnabled: false
        )
        XCTAssertFalse(result)
    }

    // MARK: - Stored State Scenario Tests

    /// Verifies that if connection status is `.connected` and on-demand changes to false,
    /// `isVPNEnabled` should still be true (connection takes precedence).
    func testIsVPNEnabled_whenConnected_andOnDemandBecomesDisabled_remainsTrue() {
        // Simulates: status update set connected, then config update disabled on-demand
        let status: NEVPNStatus = .connected
        let onDemandEnabled = false

        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: status,
            isOnDemandEnabled: onDemandEnabled
        )

        XCTAssertTrue(result, "VPN should remain enabled when connected, regardless of on-demand status")
    }

    /// Verifies the bug scenario: if we only had on-demand=false and somehow lost connection status,
    /// `isVPNEnabled` would incorrectly be false. This test documents why we need separate state tracking.
    func testIsVPNEnabled_whenDisconnectedDefault_andOnDemandDisabled_returnsFalse() {
        // This is what happens if connection status is corrupted to .disconnected
        // while VPN is actually connected - the bug we're fixing
        let status: NEVPNStatus = .disconnected
        let onDemandEnabled = false

        let result = VPNEnabledObserverThroughSession.isVPNEnabled(
            status: status,
            isOnDemandEnabled: onDemandEnabled
        )

        XCTAssertFalse(result, "With both disconnected status and no on-demand, VPN shows disabled")
    }

    /// Verifies that on-demand alone is sufficient to show VPN as enabled (toggle ON).
    func testIsVPNEnabled_whenOnDemandEnabled_regardlessOfStatus_returnsTrue() {
        let statuses: [NEVPNStatus] = [.disconnected, .disconnecting]

        for status in statuses {
            let result = VPNEnabledObserverThroughSession.isVPNEnabled(
                status: status,
                isOnDemandEnabled: true
            )
            XCTAssertTrue(result, "VPN should be enabled when on-demand is true, even with status \(status)")
        }
    }
}
