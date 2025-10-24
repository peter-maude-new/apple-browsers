//
//  UpdateControllerTests.swift
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
@testable import DuckDuckGo_Privacy_Browser
import BrowserServicesKit
import Sparkle

final class UpdateControllerTests: XCTestCase {

    func testSparkleUpdaterErrorReason() {
        let updateController = SparkleUpdateController(
            internalUserDecider: MockInternalUserDecider(),
            featureFlagger: MockFeatureFlagger(),
            updateCheckState: UpdateCheckState()
        )

        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Package installer failed to launch."), "Package installer failed to launch." )
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Guided package installer failed to launch"), "Guided package installer failed to launch")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "An error occurred while running the updater. Please try again later."), "An error occurred while running the updater.")

        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Guided package installer failed to launch with additional error details"), "Guided package installer failed to launch")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Failed to move the new app from /path/to/source to /path/to/destination"), "Failed to move the new app")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Guided package installer returned non-zero exit status (1)"), "Guided package installer returned non-zero exit status")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Found regular application update but expected 'version=1.0' from appcast"), "Found regular application update")

        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Some completely unknown error message"), "unknown")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: ""), "unknown")
        XCTAssertEqual(updateController.sparkleUpdaterErrorReason(from: "Unexpected installer error format"), "unknown")
    }

    func testUpdaterWillRelaunchApplication_completesWideEventWithSuccess() {
        // Given
        let mockWideEventManager = WideEventMock()
        let mockWideEvent = SparkleUpdateWideEvent(
            wideEventManager: mockWideEventManager,
            internalUserDecider: MockInternalUserDecider(),
            areAutomaticUpdatesEnabled: true
        )
        
        let updateController = SparkleUpdateController(
            internalUserDecider: MockInternalUserDecider(),
            featureFlagger: MockFeatureFlagger(),
            updateCheckState: UpdateCheckState(),
            updateWideEvent: mockWideEvent
        )
        
        // Start a flow and simulate finding an update
        mockWideEvent.startFlow(initiationType: .automatic)
        mockWideEvent.updateFlow(.updateFound(version: "1.1.0", build: "110", isCritical: false))
        
        // Create a mock SPUUpdater
        let mockUpdater = MockSPUUpdater()
        
        // When
        updateController.updaterWillRelaunchApplication(mockUpdater)
        
        // Then - verify the wide event was completed with success
        XCTAssertEqual(mockWideEventManager.completions.count, 1)
        let (completedData, status) = mockWideEventManager.completions[0]
        
        // Verify it's a success status with the correct reason
        if case .success(let reason) = status {
            XCTAssertEqual(reason, "update_installed")
        } else {
            XCTFail("Expected success status with update_installed reason, got \(status)")
        }
        
        // Verify the data includes version info
        let pixelParams = (completedData as? UpdateWideEventData)?.pixelParameters() ?? [:]
        XCTAssertEqual(pixelParams["feature.data.ext.to_version"], "1.1.0")
        XCTAssertEqual(pixelParams["feature.data.ext.to_build"], "110")
    }

    func testDidFinishUpdateCycleFor_withNoUpdateFound_completesWideEvent() {
        let mockWideEventManager = WideEventMock()
        let mockWideEvent = SparkleUpdateWideEvent(
            wideEventManager: mockWideEventManager,
            internalUserDecider: MockInternalUserDecider(),
            areAutomaticUpdatesEnabled: true
        )
        
        let updateController = SparkleUpdateController(
            internalUserDecider: MockInternalUserDecider(),
            featureFlagger: MockFeatureFlagger(),
            updateCheckState: UpdateCheckState(),
            updateWideEvent: mockWideEvent
        )
        
        // Start a flow
        mockWideEvent.startFlow(initiationType: .automatic)
        
        // Simulate the milestone being recorded
        mockWideEvent.updateFlow(.noUpdateFound)
        
        // Create a mock SPUUpdater
        let mockUpdater = MockSPUUpdater()
        
        // Create the noUpdateError
        let noUpdateError = NSError(domain: SPUSparkleErrorDomain, code: Int(SUError.noUpdateError.rawValue))
        
        // When - didFinishUpdateCycleFor is called with noUpdateError
        updateController.updater(mockUpdater, didFinishUpdateCycleFor: .initiated, error: noUpdateError)
        
        // Then - verify the wide event WAS completed with success
        XCTAssertEqual(mockWideEventManager.completions.count, 1)
        let (_, status) = mockWideEventManager.completions[0]
        
        if case .success(let reason) = status {
            XCTAssertEqual(reason, "no_update_available")
        } else {
            XCTFail("Expected success status with no_update_available reason, got \(status)")
        }
    }

}

// MARK: - Mock Classes

private class MockSPUUpdater: SPUUpdater {
    override init(hostBundle: Bundle, applicationBundle: Bundle, userDriver: SPUUserDriver, delegate: (any SPUUpdaterDelegate)?) {
        super.init(hostBundle: hostBundle, applicationBundle: applicationBundle, userDriver: userDriver, delegate: delegate)
    }
    
    convenience init() {
        let mockUserDriver = MockUserDriver()
        self.init(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: mockUserDriver,
            delegate: nil
        )
    }
}

private class MockUserDriver: NSObject, SPUUserDriver {
    func showCanCheck(forUpdates canCheckForUpdates: Bool) {}
    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {}
    func showUserInitiatedUpdateCheck(completion updateCheckStatusCompletion: @escaping (SPUUserInitiatedCheckStatus) -> Void) {}
    func dismissUserInitiatedUpdateCheck() {}
    func showUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {}
    func showDownloadedUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {}
    func showResumableUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInstallUpdateStatus) -> Void) {}
    func showInformationalUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInformationalUpdateAlertChoice) -> Void) {}
    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {}
    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: any Error) {}
    func showUpdateNotFound(acknowledgement: @escaping () -> Void) {}
    func showUpdaterError(_ error: any Error, acknowledgement: @escaping () -> Void) {}
    func showDownloadInitiated(completion downloadUpdateStatusCompletion: @escaping (SPUDownloadUpdateStatus) -> Void) {}
    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {}
    func showDownloadDidReceiveData(ofLength length: UInt64) {}
    func showDownloadDidStartExtractingUpdate() {}
    func showExtractionReceivedProgress(_ progress: Double) {}
    func showReady(toInstallAndRelaunch installUpdateHandler: @escaping (SPUInstallUpdateStatus) -> Void) {}
    func showInstallingUpdate() {}
    func showSendingTerminationSignal() {}
    func showUpdateInstallationDidFinish(acknowledgement: @escaping () -> Void) {}
    func dismissUpdateInstallation() {}
}
