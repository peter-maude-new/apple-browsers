//
//  QuitSurveyReturnUserHandler.swift
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

import os.log
import PixelKit

/// Handles firing the quit survey return user pixel on app launch.
///
/// When a user completes the quit survey (thumbs down with reasons), the reasons are stored
/// in the persistor. On the next app launch, this handler checks for pending reasons and
/// fires the return user pixel once, then clears the stored reasons.
final class QuitSurveyReturnUserHandler {

    private var persistor: QuitSurveyPersistor

    init(persistor: QuitSurveyPersistor) {
        self.persistor = persistor
    }

    /// Fires the return user pixel if there are pending reasons from a previous quit survey submission.
    /// This should be called on app launch.
    func fireReturnUserPixelIfNeeded() {
        guard let reasons = persistor.pendingReturnUserReasons else {
            return
        }

        Logger.general.debug("Firing quit survey return user pixel")
        PixelKit.fire(QuitSurveyPixels.quitSurveyReturnUser(reasons: reasons))

        // Clear the stored reasons to ensure the pixel is only fired once
        persistor.pendingReturnUserReasons = nil
    }
}

