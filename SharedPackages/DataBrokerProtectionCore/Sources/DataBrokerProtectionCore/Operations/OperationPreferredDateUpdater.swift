//
//  OperationPreferredDateUpdater.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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

enum OperationPreferredDateUpdaterOrigin {
    case optOut
    case scan
}

protocol OperationPreferredDateUpdating {
    var database: DataBrokerProtectionRepository { get }

    func updateOperationDataDates(origin: OperationPreferredDateUpdaterOrigin,
                                  brokerId: Int64,
                                  profileQueryId: Int64,
                                  extractedProfileId: Int64?,
                                  schedulingConfig: DataBrokerScheduleConfig) throws

    func updateChildrenBrokerForParentBroker(_ parentBroker: DataBroker, profileQueryId: Int64) throws
}

struct OperationPreferredDateUpdater: OperationPreferredDateUpdating {

    let database: DataBrokerProtectionRepository
    private let calculator = OperationPreferredDateCalculator()

    func updateOperationDataDates(origin: OperationPreferredDateUpdaterOrigin,
                                  brokerId: Int64,
                                  profileQueryId: Int64,
                                  extractedProfileId: Int64?,
                                  schedulingConfig: DataBrokerScheduleConfig) throws {

        guard let brokerProfileQuery = try database.brokerProfileQueryData(for: brokerId,
                                                                           and: profileQueryId) else { return }

        try updateScanJobDataDates(origin: origin,
                                   brokerId: brokerId,
                                   profileQueryId: profileQueryId,
                                   extractedProfileId: extractedProfileId,
                                   schedulingConfig: schedulingConfig,
                                   brokerProfileQuery: brokerProfileQuery)

        // We only need to update the optOut date if we have an extracted profile ID
        if let extractedProfileId = extractedProfileId {
            try updateOptOutJobDataDates(origin: origin,
                                         brokerId: brokerId,
                                         profileQueryId: profileQueryId,
                                         extractedProfileId: extractedProfileId,
                                         schedulingConfig: schedulingConfig,
                                         brokerProfileQuery: brokerProfileQuery)
        }
    }

    /// 1, This method fetches scan operations with the profileQueryId and with child sites of parentBrokerId
    /// 2. Then for each one it updates the preferredRunDate of the scan to its confirm scan
    func updateChildrenBrokerForParentBroker(_ parentBroker: DataBroker, profileQueryId: Int64) throws {
        do {
            let childBrokers =  try database.fetchChildBrokers(for: parentBroker.name)

            try childBrokers.forEach { childBroker in
                if let childBrokerId = childBroker.id {
                    let confirmOptOutScanDate = Date().addingTimeInterval(childBroker.schedulingConfig.confirmOptOutScan.hoursToSeconds)
                    Logger.dataBrokerProtection.log("🏴‍☠️ CHILD BROKER UPDATE: Updating preferredRunDate for child broker [\(childBroker.name, privacy: .public)] of parent [\(parentBroker.name, privacy: .public)] to confirmOptOutScanDate: \(confirmOptOutScanDate.description, privacy: .public)")
                    try database.updatePreferredRunDate(confirmOptOutScanDate,
                                                        brokerId: childBrokerId,
                                                        profileQueryId: profileQueryId)
                }
            }
        } catch {
            Logger.dataBrokerProtection.error("OperationPreferredDateUpdaterUseCase error: updateChildrenBrokerForParentBroker, error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func updateScanJobDataDates(origin: OperationPreferredDateUpdaterOrigin,
                                        brokerId: Int64,
                                        profileQueryId: Int64,
                                        extractedProfileId: Int64?,
                                        schedulingConfig: DataBrokerScheduleConfig,
                                        brokerProfileQuery: BrokerProfileQueryData) throws {

        let currentScanPreferredRunDate = brokerProfileQuery.scanJobData.preferredRunDate

        var newScanPreferredRunDate = try calculator.dateForScanOperation(currentPreferredRunDate: currentScanPreferredRunDate,
                                                                          historyEvents: brokerProfileQuery.events,
                                                                          extractedProfileID: extractedProfileId,
                                                                          schedulingConfig: schedulingConfig,
                                                                          isDeprecated: brokerProfileQuery.profileQuery.deprecated)
        if let newDate = newScanPreferredRunDate, origin == .optOut {
            newScanPreferredRunDate = returnMostRecentDate(currentScanPreferredRunDate, newDate)
        }

        if newScanPreferredRunDate != currentScanPreferredRunDate {
            Logger.dataBrokerProtection.log("🏴‍☠️ SCAN DATE UPDATE: [\(brokerProfileQuery.dataBroker.name, privacy: .public)] Updating scan preferredRunDate from \(currentScanPreferredRunDate?.description ?? "nil", privacy: .public) to \(newScanPreferredRunDate?.description ?? "nil", privacy: .public), origin: \(String(describing: origin), privacy: .public)")
            try updatePreferredRunDate(newScanPreferredRunDate,
                                       brokerId: brokerId,
                                       profileQueryId: profileQueryId,
                                       extractedProfileId: nil)
        } else {
            Logger.dataBrokerProtection.log("🏴‍☠️ SCAN DATE UPDATE: [\(brokerProfileQuery.dataBroker.name, privacy: .public)] Scan preferredRunDate unchanged: \(currentScanPreferredRunDate?.description ?? "nil", privacy: .public), origin: \(String(describing: origin), privacy: .public)")
        }
    }

    private func updateOptOutJobDataDates(origin: OperationPreferredDateUpdaterOrigin,
                                          brokerId: Int64,
                                          profileQueryId: Int64,
                                          extractedProfileId: Int64?,
                                          schedulingConfig: DataBrokerScheduleConfig,
                                          brokerProfileQuery: BrokerProfileQueryData) throws {

        let optOutJob = brokerProfileQuery.optOutJobData.filter { $0.extractedProfile.id == extractedProfileId }.first
        let currentOptOutPreferredRunDate = optOutJob?.preferredRunDate

        var newOptOutPreferredDate = try calculator.dateForOptOutOperation(currentPreferredRunDate: currentOptOutPreferredRunDate,
                                                                           historyEvents: brokerProfileQuery.events,
                                                                           extractedProfileID: extractedProfileId,
                                                                           schedulingConfig: schedulingConfig,
                                                                           attemptCount: optOutJob?.attemptCount)

        if let newDate = newOptOutPreferredDate, origin == .scan {
            newOptOutPreferredDate = returnMostRecentDate(currentOptOutPreferredRunDate, newDate)
        }

        if newOptOutPreferredDate != currentOptOutPreferredRunDate {
            Logger.dataBrokerProtection.log("🏴‍☠️ OPTOUT DATE UPDATE: [\(brokerProfileQuery.dataBroker.name, privacy: .public)] Updating optOut preferredRunDate from \(currentOptOutPreferredRunDate?.description ?? "nil", privacy: .public) to \(newOptOutPreferredDate?.description ?? "nil", privacy: .public), origin: \(String(describing: origin), privacy: .public), extractedProfileId: \(extractedProfileId ?? -1, privacy: .public)")
            try updatePreferredRunDate(newOptOutPreferredDate,
                                       brokerId: brokerId,
                                       profileQueryId: profileQueryId,
                                       extractedProfileId: extractedProfileId)
        } else {
            Logger.dataBrokerProtection.log("🏴‍☠️ OPTOUT DATE UPDATE: [\(brokerProfileQuery.dataBroker.name, privacy: .public)] OptOut preferredRunDate unchanged: \(currentOptOutPreferredRunDate?.description ?? "nil", privacy: .public), origin: \(String(describing: origin), privacy: .public), extractedProfileId: \(extractedProfileId ?? -1, privacy: .public)")
        }

        if let extractedProfileId = extractedProfileId,
           let optOutJob = optOutJob,
           let lastEvent = brokerProfileQuery.events.last,
           lastEvent.type == .optOutRequested && optOutJob.submittedSuccessfullyDate == nil
        {
            let submittedSuccessfullyDate = SystemDate().now
            Logger.dataBrokerProtection.log("🏴‍☠️ OPTOUT DATE UPDATE: [\(brokerProfileQuery.dataBroker.name, privacy: .public)] Updating submittedSuccessfullyDate to \(submittedSuccessfullyDate.description, privacy: .public), extractedProfileId: \(extractedProfileId, privacy: .public)")
            try database.updateSubmittedSuccessfullyDate(submittedSuccessfullyDate, forBrokerId: brokerId, profileQueryId: profileQueryId, extractedProfileId: extractedProfileId)
        }
    }

    private func returnMostRecentDate(_ date1: Date?, _ date2: Date?) -> Date? {
        guard let date1 = date1 else { return date2 }
        guard let date2 = date2 else { return date1 }

        return min(date1, date2)
    }

    private func updatePreferredRunDate(_ date: Date?,
                                        brokerId: Int64,
                                        profileQueryId: Int64,
                                        extractedProfileId: Int64?) throws {
        do {
            if let extractedProfileId = extractedProfileId {
                try database.updatePreferredRunDate(date, brokerId: brokerId, profileQueryId: profileQueryId, extractedProfileId: extractedProfileId)
            } else {
                try database.updatePreferredRunDate(date, brokerId: brokerId, profileQueryId: profileQueryId)
            }
        } catch {
            Logger.dataBrokerProtection.error("OperationPreferredDateUpdaterUseCase error: updatePreferredRunDate, error: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        Logger.dataBrokerProtection.log("Updating preferredRunDate on operation with brokerId \(brokerId.description, privacy: .public) and profileQueryId \(profileQueryId.description, privacy: .public)")
    }
}
