//
//  RemoteMessagingConfigProcessor.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import Common
import os.log

/**
 * This protocol defines API for processing RMF config file
 * in order to find a message to be displayed.
 */
public protocol RemoteMessagingConfigProcessing {
    var remoteMessagingConfigMatcher: RemoteMessagingConfigMatcher { get }

    func shouldProcessConfig(_ currentConfig: RemoteMessagingConfig?) -> Bool

    func process(
        jsonRemoteMessagingConfig: RemoteMessageResponse.JsonRemoteMessagingConfig,
        currentConfig: RemoteMessagingConfig?
    ) -> RemoteMessagingConfigProcessor.ProcessorResult?
}

public struct RemoteMessagingConfigProcessor: RemoteMessagingConfigProcessing {

    public struct ProcessorResult {
        public let version: Int64
        public let message: RemoteMessageModel?
    }

    public let remoteMessagingConfigMatcher: RemoteMessagingConfigMatcher

    public func process(jsonRemoteMessagingConfig: RemoteMessageResponse.JsonRemoteMessagingConfig,
                        currentConfig: RemoteMessagingConfig?) -> ProcessorResult? {
        Logger.remoteMessaging.debug("Processing version \(jsonRemoteMessagingConfig.version, privacy: .public)")

        let currentVersion = currentConfig?.version ?? 0
        let newVersion     = jsonRemoteMessagingConfig.version

        let isNewVersion = newVersion != currentVersion

        if isNewVersion || shouldProcessConfig(currentConfig) {
            let config = JsonToRemoteConfigModelMapper.mapJson(
                remoteMessagingConfig: jsonRemoteMessagingConfig,
                surveyActionMapper: remoteMessagingConfigMatcher.surveyActionMapper
            )
            let message = remoteMessagingConfigMatcher.evaluate(remoteConfig: config)
            Logger.remoteMessaging.debug("Message to present next: \(message.debugDescription, privacy: .public)")
            let processedMessage = processMessageListIfNeeded(message: message, config: config)
            if let original = message?.content,
               let processed = processedMessage?.content,
               case .promoList(_, let originalItems, _, _) = original,
               case .promoList(_, let processedItems, _, _) = processed {
                let diff = processedItems.difference(from: originalItems) { $0.id == $1.id }
                Logger.remoteMessaging.debug("Item changes: \(diff.removals.count) removed")
            }
            return ProcessorResult(version: jsonRemoteMessagingConfig.version, message: processedMessage)
        }

        return nil
    }

    public func shouldProcessConfig(_ currentConfig: RemoteMessagingConfig?) -> Bool {
        guard let currentConfig = currentConfig else {
            return true
        }

        return currentConfig.invalidate || currentConfig.expired()
    }
}

// MARK: - Private

private extension RemoteMessagingConfigProcessor {

    func processMessageListIfNeeded(message: RemoteMessageModel?, config: RemoteConfigModel) -> RemoteMessageModel? {
        guard let message, case let .promoList(titleText, items, primaryActionText, primaryAction) = message.content else { return message }

        let matchingItems = items.filter { item in
            if item.matchingRules.isEmpty && item.exclusionRules.isEmpty {
                      return true
                  }

            let matchingResult = remoteMessagingConfigMatcher.evaluateMatchingRules(item.matchingRules, messageID: item.id, fromRules: config.rules)
            let exclusionResult = remoteMessagingConfigMatcher.evaluateExclusionRules(item.exclusionRules, messageID: item.id, fromRules: config.rules)

            return matchingResult == .match && exclusionResult == .fail
        }

        return RemoteMessageModel(
            id: message.id,
            surfaces: message.surfaces,
            content: .promoList(
                mainTitleText: titleText,
                items: matchingItems,
                primaryActionText: primaryActionText,
                primaryAction: primaryAction
            ),
            matchingRules: message.matchingRules,
            exclusionRules: message.exclusionRules,
            isMetricsEnabled: message.isMetricsEnabled
        )
    }
}
