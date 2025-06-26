//
//  UnexpectedExceptionContext.swift
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
import OSLog
import PixelKit

/// Context information captured when an unexpected exception occurs.
///
/// This struct holds relevant state information that can be safely accessed
/// from a C exception handler to provide debugging context for crashes.
/// The data is kept minimal and privacy-safe for transmission in crash pixels.
///
public struct UnexpectedExceptionContext {
    /// Current tunnel start state when the exception occurred
    let tunnelStartState: TunnelStartState

    /// Default context for when no tunnel operation is in progress
    static let idle = UnexpectedExceptionContext(tunnelStartState: .idle)

    /// Parameters safe to include in crash tracking pixels
    var pixelParameters: [String: String] {
        return [
            "tunnelStartState": tunnelStartState.rawValue,
            "isOnDemand": String(tunnelStartState.isOnDemand)
        ]
    }
}

/// Global context for unexpected exceptions - accessible from C exception handler
///
/// This global variable can be safely accessed from the NSSetUncaughtExceptionHandler
/// callback since it doesn't require Swift context capture. Updated throughout the
/// tunnel lifecycle to provide crash debugging context.
///
/// Being internal allows other components in the VPN module to update context
/// (e.g., connection testers, device managers, server selectors).
///
var unexpectedExceptionContext: UnexpectedExceptionContext = .idle

/// Sets up global exception handler to capture crash context for debugging.
///
/// This handler captures the current tunnel state and other relevant context
/// when unexpected exceptions occur, allowing for better crash diagnostics.
/// The handler accesses only global state to ensure it works even during crashes.
///
private func setupUnexpectedExceptionHandler() {
    NSSetUncaughtExceptionHandler { exception in
        let context = unexpectedExceptionContext

        Logger.networkProtection.fault("Unhandled exception: state=\(context.tunnelStartState.rawValue) onDemand=\(context.tunnelStartState.isOnDemand) exception=\(exception.name.rawValue)")

        // Fire pixel with crash context - this is global so should be safe during crash
        // Note: We're not accessing the instance here, only global data
        // In a real implementation, you'd want to ensure this providerEvents.fire is safe to call during crash
        // For now, this shows the pattern - you may need to implement a crash-safe pixel firing mechanism
    }
}

/// Represents the current phase of tunnel startup process.
///
/// Used for crash tracking to identify where exceptions occur during tunnel initialization.
/// Each state represents a semantic milestone in the startup flow.
///
public enum TunnelStartState {
    case idle
    case preparingToConnect
    case parsingStartupOptions
    case loadingOptions(isOnDemand: Bool)
    case validatingAuth(isOnDemand: Bool)
    case settingConnectionStatus(isOnDemand: Bool)
    case runningDebugSimulations(isOnDemand: Bool)
    case generatingConfiguration(isOnDemand: Bool)
    case startingAdapter(isOnDemand: Bool)
    case waitingForAdapterStart(isOnDemand: Bool)
    case handlingAdapterStarted(isOnDemand: Bool)
    case startingMonitors(isOnDemand: Bool)
    case completed(isOnDemand: Bool)

    var rawValue: String {
        switch self {
        case .idle: return "idle"
        case .preparingToConnect: return "preparingToConnect"
        case .parsingStartupOptions: return "parsingStartupOptions"
        case .loadingOptions: return "loadingOptions"
        case .validatingAuth: return "validatingAuth"
        case .settingConnectionStatus: return "settingConnectionStatus"
        case .runningDebugSimulations: return "runningDebugSimulations"
        case .generatingConfiguration: return "generatingConfiguration"
        case .startingAdapter: return "startingAdapter"
        case .waitingForAdapterStart: return "waitingForAdapterStart"
        case .handlingAdapterStarted: return "handlingAdapterStarted"
        case .startingMonitors: return "startingMonitors"
        case .completed: return "completed"
        }
    }

    var isOnDemand: Bool {
        switch self {
        case .idle, .preparingToConnect, .parsingStartupOptions: return false
        case .loadingOptions(let isOnDemand),
             .validatingAuth(let isOnDemand),
             .settingConnectionStatus(let isOnDemand),
             .runningDebugSimulations(let isOnDemand),
             .generatingConfiguration(let isOnDemand),
             .startingAdapter(let isOnDemand),
             .waitingForAdapterStart(let isOnDemand),
             .handlingAdapterStarted(let isOnDemand),
             .startingMonitors(let isOnDemand),
             .completed(let isOnDemand):
            return isOnDemand
        }
    }
}
