//
//  WideEventCleaning.swift
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

/// Protocol for coordinating Wide Event cleanup during app lifecycle events.
///
/// Allows multiple subsystems (subscriptions, updates, future features) to register
/// cleanup handlers independently without coupling to a central cleanup mechanism.
/// WideEventService coordinates calling all registered cleaners at appropriate lifecycle points.
///
/// ## Lifecycle Hooks
///
/// - `handleAppLaunch()`: Clean up abandoned flows from previous sessions (async)
/// - `handleAppTermination()`: Cancel any active flows before app quits (synchronous)
///
/// ## Why a Protocol
///
/// This generalization allows each feature to manage its own wide event cleanup
/// independently. New features can adopt this protocol without modifying WideEventService.
protocol WideEventCleaning {
    /// Called during app launch to clean up abandoned flows from previous sessions.
    func handleAppLaunch() async

    /// Called during app termination to cancel any active flows.
    ///
    /// - Note: Must execute synchronously before app terminates. Keep cleanup fast.
    func handleAppTermination()
}
