//
//  SyncSharingManager.swift
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
import Persistence

public class SyncSharingManager {

    enum Constants {
        static let syncShareValueKey = "sync_share_last_value"
        static let syncShareStatusKey = "sync_share_sent"
    }

    enum Status: String {
        case local // ready to be sent, this never changes unless new one is received

        case new // got from sync, ready to be presented
        case presented
    }

    let keyValueFileStore: ThrowingKeyValueStoring
    let lock = NSLock()

    public var remoteShareSubject = PassthroughSubject<Void, Never>()
    public var localShareSubject = PassthroughSubject<Void, Never>()

    public init(keyValueFileStore: ThrowingKeyValueStoring) {
        self.keyValueFileStore = keyValueFileStore
    }

    public func getCurrentModel() -> SyncSharingModel? {
        lock.lock()
        defer { lock.unlock() }

        guard let valueData = try? keyValueFileStore.object(forKey: Constants.syncShareValueKey) as? Data else {
            return nil
        }

        return try? JSONDecoder.snakeCaseKeys.decode(SyncSharingModel.self, from: valueData)
    }

    public func getDataToSync() -> Data? {
        lock.lock()
        defer { lock.unlock() }

        guard let status = try? keyValueFileStore.object(forKey: Constants.syncShareStatusKey) as? String,
              Status(rawValue: status) == .local else {
            return nil
        }

        return try? keyValueFileStore.object(forKey: Constants.syncShareValueKey) as? Data
    }

    public func getModelToPresent() -> SyncSharingModel? {
        lock.lock()
        defer { lock.unlock() }

        guard let status = try? keyValueFileStore.object(forKey: Constants.syncShareStatusKey) as? String,
              Status(rawValue: status) == .new else {
            return nil
        }

        return getCurrentModel()
    }

    public func requestSync(for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let model = SyncSharingModel(url: url)
        guard let data = try? JSONEncoder.snakeCaseKeys.encode(model) else { return }

        try? keyValueFileStore.set(data, forKey: Constants.syncShareValueKey)
        try? keyValueFileStore.set(Status.local.rawValue, forKey: Constants.syncShareStatusKey)

        localShareSubject.send()
    }

    public func gotSyncRequest(for model: SyncSharingModel) {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? JSONEncoder.snakeCaseKeys.encode(model) else { return }

        try? keyValueFileStore.set(data, forKey: Constants.syncShareValueKey)
        try? keyValueFileStore.set(Status.new.rawValue, forKey: Constants.syncShareStatusKey)

        remoteShareSubject.send()
    }

    public func didPresent(model: SyncSharingModel) {
        lock.lock()
        defer { lock.unlock() }

        if let storedModel = getCurrentModel() {
            if storedModel.uuid != model.uuid {
                return
            }
        }

        try? keyValueFileStore.set(Status.presented.rawValue, forKey: Constants.syncShareStatusKey)
    }

}
