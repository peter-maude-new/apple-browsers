//
//  AIChatSyncHandler.swift
//  DuckDuckGo
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

protocol AIChatSyncHandling {

    func getAccountInfo() throws -> AIChatSyncHandler.AccountInfo
    func encrypt(_ string: String) throws -> String
    func decrypt(_ string: String) throws -> String
}

class AIChatSyncHandler: AIChatSyncHandling {

    enum Errors: Error {
        case syncNotActivated
    }

    struct AccountInfo: Encodable {
        let token: String
        let userId: String
        let deviceId: String
        let deviceName: String
        let deviceType: String
    }

    let sync: DDGSyncing

    init(sync: DDGSyncing) {
        self.sync = sync
    }

    func getAccountInfo() throws -> AccountInfo {
        guard sync.authState != .inactive, sync.authState != .initializing,
                let account = sync.account else {
            throw Errors.syncNotActivated
        }

//    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJQUzI1NiJ9.eyJlMmVlX2lkIjoiNzJjZjMxMzEtNzRlMS00MTcxLTliM2ItN2FkNzg1NDVlY2VkIiwianRpIjoiX1AyTVhWUEJRdGswejhMR0tRZU1mTGFKYWJwNlV0SVYiLCJzdWIiOiJkNzkyMzFlNC0wYTcwLTQ5OTItOTYyNC0xODBlOWUwNjNjYzgiLCJkZXZpY2VfaWQiOiJjMDJmN2MxNC1kIiwiaXNzIjoic3luYy5kdWNrZHVja2dvLmNvbSIsInNjb3BlIjoiYWlfY2hhdHMiLCJhdWQiOiJwcm9kIiwiaWF0IjoxNzYyNTQ1NTUxfQ.ZM9CembOkeKGCLi0q2-MxRiOU8pSFrFCGdRWBILktFUGDVF-jyAYfHBjnVtzKOZOTKiu9BHnoeqiYJbX4a14Q_aFlnsiwYsHMc32FnmnRmiI1V7nDXReNXiQZRkEo_QWOfFEoOSlwNOdG_j6i-UUmgUb-AmLXL5bKTgEZaTz_AuM2EsXL7EfhvfI1EN1U8dyGUFgbTTIQejRlKHGr7SK_lGMWwUAplIivpDAiBeSdhXO2Kd8_rsjSHAZ1L2AiW8pXUSi-tOgTvQ01ftX5pBm0r1qeyAwGMZTUkaZ35nf6hUXRwhtWx4gVO_RM4xIQ2YbFUm9OXEvOqoaNGUV0vVqUA",
//        "user_id": "d79231e4-0a70-4992-9624-180e9e063cc8"

        return AccountInfo(token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJQUzI1NiJ9.eyJlMmVlX2lkIjoiNzJjZjMxMzEtNzRlMS00MTcxLTliM2ItN2FkNzg1NDVlY2VkIiwianRpIjoiX1AyTVhWUEJRdGswejhMR0tRZU1mTGFKYWJwNlV0SVYiLCJzdWIiOiJkNzkyMzFlNC0wYTcwLTQ5OTItOTYyNC0xODBlOWUwNjNjYzgiLCJkZXZpY2VfaWQiOiJjMDJmN2MxNC1kIiwiaXNzIjoic3luYy5kdWNrZHVja2dvLmNvbSIsInNjb3BlIjoiYWlfY2hhdHMiLCJhdWQiOiJwcm9kIiwiaWF0IjoxNzYyNTQ1NTUxfQ.ZM9CembOkeKGCLi0q2-MxRiOU8pSFrFCGdRWBILktFUGDVF-jyAYfHBjnVtzKOZOTKiu9BHnoeqiYJbX4a14Q_aFlnsiwYsHMc32FnmnRmiI1V7nDXReNXiQZRkEo_QWOfFEoOSlwNOdG_j6i-UUmgUb-AmLXL5bKTgEZaTz_AuM2EsXL7EfhvfI1EN1U8dyGUFgbTTIQejRlKHGr7SK_lGMWwUAplIivpDAiBeSdhXO2Kd8_rsjSHAZ1L2AiW8pXUSi-tOgTvQ01ftX5pBm0r1qeyAwGMZTUkaZ35nf6hUXRwhtWx4gVO_RM4xIQ2YbFUm9OXEvOqoaNGUV0vVqUA",
                           userId: "d79231e4-0a70-4992-9624-180e9e063cc8",
                           deviceId: account.deviceId,
                           deviceName: account.deviceName,
                           deviceType: account.deviceType)
    }

    func encrypt(_ string: String) throws -> String {
        return try sync.encryptAndBase64Encode([string]).first ?? ""
    }

    func decrypt(_ string: String) throws -> String {
        return try sync.base64DecodeAndDecrypt([string]).first ?? ""
    }
}
