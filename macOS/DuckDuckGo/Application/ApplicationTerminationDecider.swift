//
//  ApplicationTerminationDecider.swift
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

import AppKit

// MARK: - Termination Response

/// Represents a decision about whether the application should terminate.
enum TerminationDecision {
    /// Continue to the next decider in the chain. If no more deciders, terminate the app.
    case next

    /// Cancel the termination request entirely.
    case cancel
}

// MARK: - Termination Query

/// Represents either a synchronous or asynchronous termination decision.
enum TerminationQuery {
    /// A synchronous decision that is available immediately.
    case sync(TerminationDecision)

    /// An asynchronous decision that will be resolved via a Task.
    /// The task should complete with a TerminationDecision.
    case async(Task<TerminationDecision, Never>)
}

// MARK: - Protocol

/// A protocol for objects that participate in the application termination decision process.
///
/// Deciders are consulted in sequence when the application is about to terminate. Each decider
/// can either make an immediate decision (synchronous) or defer the decision to an asynchronous
/// operation (e.g., showing an alert and waiting for user input).
///
/// ## Termination Flow
///
/// 1. When `NSApplication.terminate(_:)` is called, `applicationShouldTerminate(_:)` is invoked
/// 2. The AppDelegate queries each decider in sequence:
///    - Quit survey
///    - Active downloads confirmation
///    - Quit confirmation (warn before quit)
///    - Update controller
///    - State restoration
///    - Autoclear data
///    - Privacy statistics
///
/// 3. For each decider:
///    - If `.sync(.next)`: Continue to next decider
///    - If `.sync(.cancel)`: Cancel termination
///    - If `.async(task)`: Store task and continue asynchronously
///
/// 4. If all deciders return `.next`, the app terminates
///
/// ## Synchronous vs Asynchronous Execution
///
/// The `isAsync` parameter indicates whether the termination sequence has already been deferred
/// by a previous decider. This allows deciders to modify their behavior:
///
/// ```swift
/// func shouldTerminate(isAsync: Bool) -> TerminationQuery {
///     // Don't show confirmation if another decider already delayed termination
///     guard !isAsync else {
///         return .sync(.next)
///     }
///     
///     // Show confirmation and return async decision
///     return .async(Task {
///         let shouldQuit = await showConfirmation()
///         return shouldQuit ? .next : .cancel
///     })
/// }
/// ```
///
/// ## Example Implementation
///
/// ```swift
/// final class MyTerminationDecider: ApplicationTerminationDecider {
///     func shouldTerminate(isAsync: Bool) -> TerminationQuery {
///         guard needsConfirmation else {
///             return .sync(.next)  // No confirmation needed
///         }
///         
///         return .async(Task { @MainActor in
///             let result = await showAlert()
///             return result ? .next : .cancel
///         })
///     }
/// }
/// ```
protocol ApplicationTerminationDecider {
    /// Determines whether the application should terminate.
    ///
    /// - Parameter isAsync: `true` if the termination sequence has already been deferred by a
    ///   previous decider (e.g., a confirmation dialog is already shown). Use this to avoid
    ///   showing multiple confirmation dialogs.
    ///
    /// - Returns: A `TerminationQuery` indicating either:
    ///   - `.sync(decision)`: An immediate decision
    ///   - `.async(task)`: A deferred decision that will be resolved asynchronously
    @MainActor func shouldTerminate(isAsync: Bool) -> TerminationQuery
}

// MARK: - Termination Decider Handler

/// Handles the execution of termination deciders in sequence.
@MainActor
final class TerminationDeciderHandler {
    private var terminationTask: Task<Void, Never>?

    nonisolated init() {}

    /// Check if termination is currently in progress
    var isTerminating: Bool {
        terminationTask != nil
    }

    func executeTerminationDeciders(_ deciders: [ApplicationTerminationDecider], isAsync: Bool) -> NSApplication.TerminateReply {
        // Prevent reentry if already processing termination (only for initial calls, not recursive continuations)
        // Note: Recursive calls from async task completion happen after terminationTask is cleared, so they proceed normally
        if !isAsync && terminationTask != nil {
            // New termination attempt while already terminating - prevent reentry
            return .terminateLater
        }

        var remainingDeciders = deciders

        while !remainingDeciders.isEmpty {
            let decider = remainingDeciders.removeFirst()
            let query = decider.shouldTerminate(isAsync: isAsync)

            switch query {
            case .sync(let decision):
                switch decision {
                case .next:
                    continue  // Move to next decider
                case .cancel:
                    if isAsync {
                        NSApp.reply(toApplicationShouldTerminate: false)
                    }
                    return .terminateCancel
                }

            case .async(let task):
                // Store task and continue asynchronously
                terminationTask = Task { @MainActor in
                    let decision = await task.value
                    self.terminationTask = nil

                    switch decision {
                    case .next:
                        // Continue with remaining deciders in async mode
                        _ = self.executeTerminationDeciders(remainingDeciders, isAsync: true)
                    case .cancel:
                        NSApp.reply(toApplicationShouldTerminate: false)
                    }
                }

                return .terminateLater
            }
        }

        // All deciders returned .next
        if isAsync {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateNow
    }

}



