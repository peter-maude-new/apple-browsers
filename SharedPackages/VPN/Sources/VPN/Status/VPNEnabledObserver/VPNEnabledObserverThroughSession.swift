//
//  VPNEnabledObserverThroughSession.swift
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
import Foundation
import NetworkExtension
import NotificationCenter
import Common
import os.log

public class VPNEnabledObserverThroughSession: VPNEnabledObserver {

    public var isVPNEnabled: Bool {
        subject.value
    }

    public lazy var publisher: AnyPublisher<Bool, Never> = subject.eraseToAnyPublisher()
    private let subject: CurrentValueSubject<Bool, Never>

    private let tunnelSessionProvider: TunnelSessionProvider
    private let extensionResolver: VPNExtensionResolving

    // MARK: - Last Known State

    private var lastKnownConnectionStatus: NEVPNStatus = .disconnected
    private var lastKnownOnDemandEnabled: Bool = false

    // MARK: - Notifications

    private let notificationCenter: NotificationCenter
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(tunnelSessionProvider: TunnelSessionProvider,
                extensionResolver: VPNExtensionResolving,
                notificationCenter: NotificationCenter = .default) {

        self.extensionResolver = extensionResolver
        self.notificationCenter = notificationCenter
        self.tunnelSessionProvider = tunnelSessionProvider

        // Unfortunately we can't set the initial value from real data without making the init
        // async, so for now we'll be content to allow this to be false. The initial update
        // will happen in startObservingChanges().
        subject = CurrentValueSubject<Bool, Never>(false)

        startObservingChanges()
    }

    // MARK: - VPN-Enabled Status Calculations

    internal static func isVPNEnabled(status: NEVPNStatus, isOnDemandEnabled: Bool) -> Bool {
        // If the VPN has not been configured it's certainly not on, and won't have on-demand
        // enabled.  We need to capture this here though because `isOnDemandEnabled` keeps
        // returning true the last known value when the VPN configuration has been deleted.
        guard status != .invalid else {
            return false
        }

        let isVPNConnectedOrConnecting = status == .connected
            || status == .connecting
            || status == .reasserting
        return isOnDemandEnabled || isVPNConnectedOrConnecting
    }

    // MARK: - Observing VPN status and configuration

    private func startObservingChanges() {
        // Subscribe to status changes - uses notification's session (reliable)
        notificationCenter.publisher(for: .NEVPNStatusDidChange)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleStatusChange(notification)
                }
            }
            .store(in: &cancellables)

        // Subscribe to config changes - uses activeSession() (conservative)
        notificationCenter.publisher(for: .NEVPNConfigurationChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleConfigChange()
                }
            }
            .store(in: &cancellables)

        // Fetch initial state
        Task { @MainActor in
            await loadInitialState()
        }
    }

    // MARK: - Recalculating isVPNEnabled

    @MainActor
    private func updateIsVPNEnabled() {
        let isEnabled = Self.isVPNEnabled(
            status: lastKnownConnectionStatus,
            isOnDemandEnabled: lastKnownOnDemandEnabled
        )

        if isEnabled != subject.value {
            subject.send(isEnabled)
        }
    }

    // MARK: - Status Change Handler (Reliable)

    /// Handles `.NEVPNStatusDidChange` notifications by extracting the session directly from the notification.
    /// This is reliable because the session is attached to the notification object.
    /// Updates both connection status and on-demand status.
    @MainActor
    private func handleStatusChange(_ notification: Notification) {
        guard let session = ConnectionSessionUtilities.session(from: notification) else {
            return
        }

        lastKnownConnectionStatus = session.status
        lastKnownOnDemandEnabled = session.manager.isOnDemandEnabled
        updateIsVPNEnabled()
    }

    // MARK: - Config Change Handler (Conservative)

    /// Handles `.NEVPNConfigurationChange` notifications.
    /// Only updates on-demand status, never touches connection status.
    /// If `activeSession()` returns nil, does nothing to avoid corrupting state.
    @MainActor
    private func handleConfigChange() async {
        guard let session = await tunnelSessionProvider.activeSession() else {
            return
        }

        lastKnownOnDemandEnabled = session.manager.isOnDemandEnabled
        updateIsVPNEnabled()
    }

    // MARK: - Initial State Loader

    /// Loads initial state on startup. Uses `activeSession()` to get initial values.
    @MainActor
    private func loadInitialState() async {
        guard let session = await tunnelSessionProvider.activeSession() else {
            return
        }

        lastKnownConnectionStatus = session.status
        lastKnownOnDemandEnabled = session.manager.isOnDemandEnabled
        updateIsVPNEnabled()
    }
}

