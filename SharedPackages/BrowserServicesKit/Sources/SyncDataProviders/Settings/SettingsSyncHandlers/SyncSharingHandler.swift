//
//  SyncSharingHandler.swift
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
import Combine

extension SettingsProvider.Setting {
    static let syncSharing = SettingsProvider.Setting(key: "sync_sharing")
}

public class SyncSharingHandler: SettingSyncHandler {

    enum Constants {
        static let syncSharingKey = "sync_share_last_value"
    }

    let manager: SyncSharingManager

    public init(manager: SyncSharingManager) {
        self.manager = manager
        super.init()
    }

    public override var setting: SettingsProvider.Setting {
        .syncSharing
    }

    public override func getValue() throws -> String? {
        guard let data = manager.getDataToSync() else {
            return nil
        }

        return String(bytes: data, encoding: .utf8)
    }

    public override func setValue(_ value: String?, shouldDetectOverride: Bool) throws {

        guard let value,
              let valueData = value.data(using: .utf8),
              let model = try? JSONDecoder.snakeCaseKeys.decode(SyncSharingModel.self, from: valueData) else {
            return
        }

        manager.gotSyncRequest(for: model)
    }

    public override var valueDidChangePublisher: AnyPublisher<Void, Never> {
        manager.localShareSubject.eraseToAnyPublisher()
    }
}
