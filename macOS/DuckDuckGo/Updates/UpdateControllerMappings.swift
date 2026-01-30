//
//  UpdateControllerEventMapping.swift
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

import AppUpdaterShared
import BrowserServicesKit
import Common
import FeatureFlags
import Persistence
import PixelKit
import PrivacyConfig
import Subscription

/// Provides event and metadata storage mappings for the AppUpdater package.
///
/// This centralizes the mapping logic that connects UpdateController's generic
/// events and metadata storage to the app's specific implementations.
enum UpdateControllerMappings {

    /// Creates an event mapping for UpdateController.
    ///
    /// Maps UpdateControllerEvent to the app's PixelKit for analytics.
    ///
    /// - Parameter pixelFiring: The pixel firing instance to use for analytics
    /// - Returns: An EventMapping for UpdateController
    static func eventMapping(pixelFiring: PixelFiring?) -> EventMapping<UpdateControllerEvent> {
        return EventMapping<UpdateControllerEvent> { event, error, _, _ in
            guard let pixelFiring else { return }
            switch event {
            case .updaterDidRunUpdate:
                pixelFiring.fire(GeneralPixel.updaterDidRunUpdate)
            case .updaterAttemptToRestartWithoutResumeBlock:
                pixelFiring.fire(GeneralPixel.updaterAttemptToRestartWithoutResumeBlock)
            case .updaterAborted(reason: let reason):
                pixelFiring.fire(DebugEvent(GeneralPixel.updaterAborted(reason: reason), error: error))
            case .updaterDidFindUpdate:
                pixelFiring.fire(GeneralPixel.updaterDidFindUpdate)
            case .updaterDidDownloadUpdate:
                pixelFiring.fire(GeneralPixel.updaterDidDownloadUpdate)
            case .releaseMetadataFetchFailed(error: let error):
                pixelFiring.fire(UpdateFlowPixels.releaseMetadataFetchFailed(error: error))
            case .releaseNotesEmpty:
                pixelFiring.fire(GeneralPixel.releaseNotesEmpty, frequency: .dailyAndCount)
            case .updateApplicationSuccess(let sourceVersion, let sourceBuild, let targetVersion, let targetBuild, let initiationType, let updateConfiguration, let osVersion):
                pixelFiring.fire(UpdateFlowPixels.updateApplicationSuccess(
                    sourceVersion: sourceVersion,
                    sourceBuild: sourceBuild,
                    targetVersion: targetVersion,
                    targetBuild: targetBuild,
                    initiationType: initiationType,
                    updateConfiguration: updateConfiguration,
                    osVersion: osVersion
                ), frequency: .dailyAndCount)
            case .updateApplicationFailure(let sourceVersion, let sourceBuild, let expectedVersion, let expectedBuild, let actualVersion, let actualBuild, let failureStatus, let initiationType, let updateConfiguration, let osVersion):
                pixelFiring.fire(UpdateFlowPixels.updateApplicationFailure(
                    sourceVersion: sourceVersion,
                    sourceBuild: sourceBuild,
                    expectedVersion: expectedVersion,
                    expectedBuild: expectedBuild,
                    actualVersion: actualVersion,
                    actualBuild: actualBuild,
                    failureStatus: failureStatus,
                    initiationType: initiationType,
                    updateConfiguration: updateConfiguration,
                    osVersion: osVersion
                ), frequency: .dailyAndCount)
            case .updateApplicationUnexpected(let targetVersion, let targetBuild, let osVersion):
                pixelFiring.fire(UpdateFlowPixels.updateApplicationUnexpected(
                    targetVersion: targetVersion,
                    targetBuild: targetBuild,
                    osVersion: osVersion
                ), frequency: .dailyAndCount)
            }
        }
    }

}
