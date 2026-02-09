//
//  UpdateControllerProtocolTests.swift
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

import Cocoa
import Combine
import PixelKitTestingUtilities
import PrivacyConfig
import XCTest

@testable import DuckDuckGo_Privacy_Browser

final class UpdateControllerProtocolTests: XCTestCase {

    func testUpdateControllerProtocol_DefaultImplementationExists() throws {
        // This test just verifies the protocol extension exists and compiles
        // Given
        let controllerType = try XCTUnwrap(UpdateControllerFactory(featureFlagger: MockFeatureFlagger()).updateControllerType)
        let controller = controllerType.init(internalUserDecider: MockInternalUserDecider(),
                                             featureFlagger: MockFeatureFlagger(),
                                             eventMapping: nil,
                                             notificationPresenter: MockNotificationPresenter(),
                                             keyValueStore: UserDefaults.standard,
                                             buildType: nil,
                                             wideEvent: WideEventMock())

        // When/Then - Just verify the default implementation method exists
        controller.showUpdateNotificationIfNeeded()

        // No assertions needed - if it compiles and doesn't crash, the extension works
        XCTAssertNotNil(controller)
    }

}
