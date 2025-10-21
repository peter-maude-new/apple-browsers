//
//  SparkleUpdateWideEvent.swift
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

#if SPARKLE

import BrowserServicesKit
import Common
import Foundation
import PixelKit
import os.log

final class SparkleUpdateWideEvent {
    private let wideEventManager: WideEventManaging
    private let internalUserDecider: InternalUserDecider
    private var currentFlowID: String?

    init(wideEventManager: WideEventManaging,
         internalUserDecider: InternalUserDecider) {
        self.wideEventManager = wideEventManager
        self.internalUserDecider = internalUserDecider
    }

    /// Start tracking a new update flow
    /// Completes any existing pending flow before starting
    func startFlow(initiationType: UpdateWideEventData.InitiationType) {
        // Complete any existing pending flow
        if let existingFlowID = currentFlowID,
           var existingFlow = wideEventManager.getFlowData(UpdateWideEventData.self, globalID: existingFlowID) {
            existingFlow.totalDuration?.complete()
            existingFlow.downloadDuration?.complete()
            existingFlow.extractionDuration?.complete()
            wideEventManager.completeFlow(existingFlow, status: .unknown(reason: "incomplete")) { _, _ in }
            Logger.updates.log("Completed previous WideEvent flow as incomplete")
        }

        // Start new flow
        let globalID = UUID().uuidString
        currentFlowID = globalID

        var eventData = UpdateWideEventData(
            fromVersion: AppVersion.shared.versionNumber,
            fromBuild: AppVersion.shared.buildNumber,
            initiationType: initiationType,
            isInternalUser: internalUserDecider.isInternalUser,
            contextData: WideEventContextData(name: "sparkle_update"),
            appData: WideEventAppData(internalUser: internalUserDecider.isInternalUser),
            globalData: WideEventGlobalData(id: globalID)
        )
        eventData.totalDuration = .startingNow()
        eventData.updateCheckDuration = .startingNow()
        eventData.lastKnownStep = .updateCheck

        wideEventManager.startFlow(eventData)
    }

    /// Update the flow with milestone progress
    func updateFlow(_ milestone: UpdateMilestone) {
        guard let globalID = currentFlowID else { return }

        switch milestone {
        case .preconditionsMet:
            // Pre-flight checks passed, about to call Sparkle
            Logger.updates.debug("Update WideEvent: preconditions met, Sparkle check starting")

        case .updateFound(let version, let build, let isCritical):
            wideEventManager.updateFlow(globalID: globalID) { (data: inout UpdateWideEventData) in
                data.toVersion = version
                data.toBuild = build
                data.updateType = isCritical ? .critical : .regular
                data.updateCheckDuration?.complete()
            }

        case .noUpdateAvailable:
            // Special case: also completes the flow
            guard let flowData = wideEventManager.getFlowData(UpdateWideEventData.self, globalID: globalID) else { return }
            var data = flowData
            data.updateCheckDuration?.complete()
            data.totalDuration?.complete()
            wideEventManager.completeFlow(data, status: .success(reason: "no_update_available")) { _, _ in }
            currentFlowID = nil

        case .downloadStarted:
            wideEventManager.updateFlow(globalID: globalID) { (data: inout UpdateWideEventData) in
                data.downloadDuration = .startingNow()
                data.lastKnownStep = .download
            }

        case .extractionStarted:
            wideEventManager.updateFlow(globalID: globalID) { (data: inout UpdateWideEventData) in
                data.downloadDuration?.complete()
                data.extractionDuration = .startingNow()
                data.lastKnownStep = .extraction
            }

        case .extractionCompleted:
            wideEventManager.updateFlow(globalID: globalID) { (data: inout UpdateWideEventData) in
                data.extractionDuration?.complete()
                data.lastKnownStep = .installation
            }
        }
    }

    /// Complete the flow with final status
    func completeFlow(status: WideEventStatus, error: Error? = nil) {
        guard let globalID = currentFlowID,
              let flowData = wideEventManager.getFlowData(UpdateWideEventData.self, globalID: globalID) else {
            return
        }
        defer { currentFlowID = nil }

        var data = flowData
        data.totalDuration?.complete()
        data.downloadDuration?.complete()
        data.extractionDuration?.complete()

        if let error = error {
            data.errorData = WideEventErrorData(error: error)
        }

        wideEventManager.completeFlow(data, status: status) { success, error in
            if success {
                Logger.updates.log("Update WideEvent completed successfully with status: \(status.description)")
            } else {
                Logger.updates.error("Update WideEvent failed to send: \(String(describing: error))")
            }
        }
    }

    enum UpdateMilestone {
        case preconditionsMet
        case updateFound(version: String, build: String, isCritical: Bool)
        case noUpdateAvailable
        case downloadStarted
        case extractionStarted
        case extractionCompleted
    }
}

extension SparkleUpdateWideEvent: WideEventCleaning {
    func cleanPendingEvents() async {
        let pending: [UpdateWideEventData] = wideEventManager.getAllFlowData(UpdateWideEventData.self)
        
        // Any pending update pixels at app startup are considered abandoned,
        // since they represent flows from a previous session that were interrupted.
        for data in pending {
            _ = try? await wideEventManager.completeFlow(data, status: .unknown(reason: "abandoned"))
        }
    }
}

#endif
