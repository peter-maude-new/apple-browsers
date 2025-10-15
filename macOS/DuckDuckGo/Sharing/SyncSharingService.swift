//
//  SyncSharingService.swift
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
import QuickLookUI

extension NSSharingService {
    static let syncSharing = SyncSharingService()
}

final class SyncSharingService: NSSharingService {

    let shareService = Application.appDelegate.syncSharingManager
    let syncService = Application.appDelegate.syncService

    fileprivate init() {
        super.init(title: "Sync Share", image: .sync, alternateImage: nil) {}
    }

    override func canPerform(withItems items: [Any]?) -> Bool {
        syncService?.authState != .inactive && (items?.first as? URL) != nil
    }

    override func perform(withItems items: [Any]) {
        guard let shareService, let syncService, let url = items.first as? URL else {
            return
        }

        shareService.requestSync(for: url)
        syncService.scheduler.requestSyncImmediately()
    }
}
