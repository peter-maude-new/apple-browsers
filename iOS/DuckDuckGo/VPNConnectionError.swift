//
//  VPNConnectionError.swift
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

/// Represents VPN connection errors with user-friendly localized messages.
///
/// This type can be initialized from an NSError (using domain and error code) or from
/// an error message string (as a fallback). The NSError-based initialization is preferred
/// as it's more robust against message string changes.
///
enum VPNConnectionError: Equatable {
    case authenticationFailed
    case connectionFailed
    case configurationIncomplete
    case sessionInterrupted
    case subscriptionExpired
    case unknown

    // MARK: - TunnelError Domain and Codes

    /// The error domain used by PacketTunnelProvider.TunnelError
    private static let tunnelErrorDomain = "VPN.PacketTunnelProvider.TunnelError"

    /// Error codes from PacketTunnelProvider.TunnelError
    private enum TunnelErrorCode: Int {
        case startingTunnelWithoutAuthToken = 0
        case couldNotGenerateTunnelConfiguration = 1
        case simulateTunnelFailureError = 2
        case settingsMissing = 3
        case simulateSubscriptionExpiration = 4
        case tokenReset = 5
        case vpnAccessRevoked = 100
        case vpnAccessRevokedDetectedByMonitorCheck = 101
        case appRequestedCancellation = 200
    }

    // MARK: - Initialization

    /// Initialize from an NSError, mapping the domain and error code to the appropriate case.
    ///
    /// - Parameter error: The NSError from `fetchLastDisconnectError` or similar.
    /// - Returns: A `VPNConnectionError` case, or `nil` if the error should not be displayed
    ///            (e.g., user-initiated cancellation).
    ///
    init?(nsError error: NSError) {
        guard error.domain == Self.tunnelErrorDomain else {
            self = .unknown
            return
        }

        guard let errorCode = TunnelErrorCode(rawValue: error.code) else {
            self = .unknown
            return
        }

        switch errorCode {
        case .startingTunnelWithoutAuthToken:
            self = .authenticationFailed
        case .couldNotGenerateTunnelConfiguration:
            self = .connectionFailed
        case .simulateTunnelFailureError:
            self = .connectionFailed
        case .settingsMissing:
            self = .configurationIncomplete
        case .simulateSubscriptionExpiration:
            // Don't show error UI for simulated subscription expiration
            return nil
        case .tokenReset:
            self = .sessionInterrupted
        case .vpnAccessRevoked, .vpnAccessRevokedDetectedByMonitorCheck:
            self = .subscriptionExpired
        case .appRequestedCancellation:
            // User-initiated disconnection, don't show error
            return nil
        }
    }

    /// Initialize from an error message string (fallback when NSError is not available).
    ///
    /// This uses pattern matching on known error message strings from TunnelError.errorDescription.
    /// This approach is less robust than NSError-based initialization, so prefer using `init(nsError:)`
    /// when possible.
    ///
    /// - Parameter errorMessage: The error message string.
    /// - Returns: A `VPNConnectionError` case, or `nil` if the error should not be displayed.
    ///
    init?(errorMessage: String) {
        switch errorMessage {
        case let msg where msg.contains("Missing auth token"):
            self = .authenticationFailed
        case let msg where msg.contains("Failed to generate a tunnel configuration"):
            self = .connectionFailed
        case "VPN settings are missing or invalid":
            self = .configurationIncomplete
        case "Abnormal situation caused the token to be reset":
            self = .sessionInterrupted
        case "VPN disconnected due to expired subscription":
            self = .subscriptionExpired
        default:
            self = .unknown
        }
    }

    // MARK: - Localized Message

    /// Returns the user-friendly localized error message.
    var localizedMessage: String {
        switch self {
        case .authenticationFailed:
            return UserText.vpnErrorAuthenticationFailed
        case .connectionFailed:
            return UserText.vpnErrorConnectionFailed
        case .configurationIncomplete:
            return UserText.vpnErrorConfigurationIncomplete
        case .sessionInterrupted:
            return UserText.vpnErrorSessionInterrupted
        case .subscriptionExpired:
            return UserText.vpnAccessRevokedAlertTitle
        case .unknown:
            return UserText.vpnErrorUnknown
        }
    }
}
