//
//  AIChatSyncHandler.swift
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
import DDGSync

public protocol AIChatSyncHandling {

    func getSyncStatus() throws -> AIChatSyncHandler.SyncStatus
    func getScopedToken() async throws -> AIChatSyncHandler.SyncToken
    func encrypt(_ string: String) throws -> AIChatSyncHandler.EncryptedData
    func decrypt(_ string: String) throws -> AIChatSyncHandler.DecryptedData
}

public class AIChatSyncHandler: AIChatSyncHandling {

    public enum Errors: Error {
        case internalError
    }

    public struct SyncStatus: Codable {
        let syncEnabled: Bool
        let syncSetupEnabled: Bool
        let userId: String?
        let deviceId: String?
        let deviceName: String?
        let deviceType: String?
    }

    public struct SyncToken: Encodable {
        let token: String
    }

    public struct EncryptedData: Encodable {
        let encryptedData: String
    }

    public struct DecryptedData: Encodable {
        let decryptedData: String
    }

    private let sync: DDGSyncing

    public init(sync: DDGSyncing) {
        self.sync = sync
    }

    private func validateSetup() throws {
        guard sync.authState != .initializing else {
            throw Errors.internalError
        }
    }

    public func getSyncStatus() throws -> SyncStatus {
        try validateSetup()

        guard let account = sync.account else {
            return SyncStatus(syncEnabled: true,
                              syncSetupEnabled: true,
                              userId: nil,
                              deviceId: nil,
                              deviceName: nil,
                              deviceType: nil)
        }

        return SyncStatus(syncEnabled: true,
                          syncSetupEnabled: true,
                          userId: account.userId,
                          deviceId: account.deviceId,
                          deviceName: account.deviceName,
                          deviceType: account.deviceType)
    }

    public func getScopedToken() async throws -> SyncToken {
        try validateSetup()

        guard let token = try await sync.mainTokenRescope(to: "ai_chats") else {
            throw Errors.internalError
        }

        return SyncToken(token: token)
    }

    public func encrypt(_ string: String) throws -> EncryptedData {
        try validateSetup()

        let data = try sync.jwtEncryptAndBase64Encode([string]).first ?? ""

        return EncryptedData(encryptedData: data)
    }

    public func decrypt(_ string: String) throws -> DecryptedData {
        try validateSetup()

        let data = try sync.jwtBase64DecodeAndDecrypt([string]).first ?? ""
        return DecryptedData(decryptedData: data)
    }
}
