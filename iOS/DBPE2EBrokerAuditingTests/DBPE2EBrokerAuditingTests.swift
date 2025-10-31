//
//  DBPE2EBrokerAuditingTests.swift
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

import BrowserServicesKit
import Combine
import Common
import PixelKitTestingUtilities
import XCTest

@testable import DataBrokerProtection_iOS
@testable import DataBrokerProtectionCore
@testable import DuckDuckGo
@testable import PixelKit

/*
 These tests run on all REAL brokers to allow us to audit broker breakage
 They run scans and opt outs

 These tests exist in a seperate target to the regular DBP end to end tests as they are not
 intended to be run on CI/automatically.

 Whilst the intention is to be able to reuse them in the short and medium term, they are not
 fully automatic or actively maintained.
 */
// swiftlint:disable force_try

final class DBPE2EBrokerAuditingTests: XCTestCase {

    var dbpManager: DataBrokerProtectionIOSManager!
    var database: DataBrokerProtectionRepository?
    var testUserDefault: UserDefaults! = UserDefaults(suiteName: #function)

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        testUserDefault = nil
    }

    /*
     Adapted from the end to end tests.
     Most of the original checks are preserved to help with debugging
     (although moved to a seperate function to aid readability)
     */
    func testWhenProfileIsSaved_ThenEachStepHappensInSequence() async throws {
        // Given

        // Local state set up
        let databaseExists = expectation(description: "Database exists")

        await awaitFulfillment(of: databaseExists,
                               withTimeout: 3,
                               whenCondition: {
            await (UIApplication.shared.delegate as? AppDelegate)?.dbpTestingInterface != nil
        })


        let testingInterface = await (UIApplication.shared.delegate as? AppDelegate)!.dbpTestingInterface!
        let database = testingInterface.databaseForTests()
        try database.deleteProfileData()
        XCTAssert(try database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: false).isEmpty)

        // When
        /*
         1/ We save a profile
         */

        /*
        this needs to set editable partial profile on view model. None of this communictor stuff anymore
        communicator.profile = mockProfile
        Task { @MainActor in
            _ = try await communicationLayer.saveProfile(params: [], original: WKScriptMessage())
        }*/
        try await testingInterface.saveProfile(mockProfile)

        // Then
        try await checkInitSteps()
        try await checkScanningSteps()

        try await checkOptOutSteps()

        // TODO how to check for success? I think we just have to go off the number of results and errors
        // Should collect this and put in CSV automatically somehow
    }

    func checkInitSteps() async throws {
        let database = await (UIApplication.shared.delegate as? AppDelegate)!.dbpTestingInterface!.databaseForTests()
        let profileSavedExpectation = expectation(description: "Profile saved in DB")
        let profileQueriesCreatedExpectation = expectation(description: "Profile queries created")

        await awaitFulfillment(of: profileSavedExpectation,
                               withTimeout: 3,
                               whenCondition: {
            autoreleasepool { // All autoreleasepool uses have been added as part of https://app.asana.com/0/1193060753475688/1209661386167901 in order to bring down the memory usage from 20Gb+ to 60-70Mb
                try! database.fetchProfile() != nil
            }
        })
        await awaitFulfillment(of: profileQueriesCreatedExpectation,
                               withTimeout: 3,
                               whenCondition: {
            autoreleasepool {
                try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: false).count > 0
            }
        })

        print("Stage 1 passed: We save a profile")
    }

    func checkScanningSteps() async throws {
        let database = await (UIApplication.shared.delegate as? AppDelegate)!.dbpTestingInterface!.databaseForTests()
        /*
        2/ We scan brokers
        */

        // Check we start scanning
        let aBrokerScannedExpectation = expectation(description: "A broker scanned")

        await awaitFulfillment(of: aBrokerScannedExpectation,
                               withTimeout: 30,
                               whenCondition: {
            autoreleasepool {
                let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true)
                let scanJobs = queries.compactMap { $0.scanJobData }
                let scansRun = scanJobs.filter { $0.lastRunDate != nil }
                return scansRun.count > 0
            }
        })

        print("Stage 2.1 passed: We start scanning brokers")

        // Check we finish all scans
        let allBrokersScannedExpectation = expectation(description: "All brokers scanned")

        await awaitFulfillment(of: allBrokersScannedExpectation,
                               withTimeout: 600,
                               whenCondition: {
            autoreleasepool {
                let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true)
                let scanJobs = queries.compactMap { $0.scanJobData }
                let scansNotYetRun = scanJobs.filter { $0.lastRunDate == nil }
                return scansNotYetRun.count == 0
            }
        })

        print("Stage 2.2 passed: We finish scanning all brokers")

        /*
        3/ We find and save extracted profiles
        */
        let extractedProfilesFoundExpectation = expectation(description: "Extracted profiles found and saved in DB")

        await awaitFulfillment(of: extractedProfilesFoundExpectation,
                               withTimeout: 120,
                               whenCondition: {
            autoreleasepool {
                let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true) // Only check non-removed brokers
                let brokerIDs = queries.compactMap { $0.dataBroker.id }
                let extractedProfiles = brokerIDs.flatMap { try! database.fetchExtractedProfiles(for: $0) }
                return extractedProfiles.count > 0
            }
        })

        print("Stage 3 passed: We find and save extracted profiles")
    }

    func checkOptOutSteps() async throws {
        let database = await (UIApplication.shared.delegate as? AppDelegate)!.dbpTestingInterface!.databaseForTests()
        /*
         4/ We create opt out jobs
         */
        let optOutJobsCreatedExpectation = expectation(description: "Opt out jobs created")

        await awaitFulfillment(of: optOutJobsCreatedExpectation,
                               withTimeout: 120,
                               whenCondition: {
            autoreleasepool {
                let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true)
                let optOutJobs = queries.flatMap { $0.optOutJobData }
                return optOutJobs.count > 0
            }
        })

        print("Stage 4 passed: We create opt out jobs")

        /*
         5/ We run those opt out jobs
         For now we check the lastRunDate on the optOutJob, but that could always be wrong. Ideally we need this information from the fake broker
         */
        let optOutJobsRunExpectation = expectation(description: "Opt out jobs run")

        await awaitFulfillment(of: optOutJobsRunExpectation,
                               withTimeout: 300,
                               whenCondition: {
            autoreleasepool {
                let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true) // Only check non-removed brokers
                let optOutJobs = queries.flatMap { $0.optOutJobData }
                let runOptOutJobs = optOutJobs.filter { $0.lastRunDate != nil }
                return runOptOutJobs.count > 0
            }
        })
        print("Stage 5.1 passed: We start running the opt out jobs")

        let optOutRequestedExpectation = expectation(description: "Opt out requested")
        var jobsRemaining = -1
        await awaitFulfillment(of: optOutRequestedExpectation,
                               withTimeout: 1200,
                               whenCondition: {
            let queries = try! database.fetchAllBrokerProfileQueryData(shouldFilterRemovedBrokers: true)
            let optOutJobs = queries.flatMap { $0.optOutJobData }
            let optOutsThatShouldRunButHaveNot = optOutJobs.filter { $0.preferredRunDate != nil && $0.lastRunDate == nil }
            if jobsRemaining != optOutsThatShouldRunButHaveNot.count {
                print("Opt out jobs remaining: \(jobsRemaining)")
            }
            jobsRemaining = optOutsThatShouldRunButHaveNot.count

            return optOutsThatShouldRunButHaveNot.count == 0
        })
        print("Stage 5 passed: We finish running the opt out jobs")
    }
}

// MARK: - Testing helpers and utilities

private extension DBPE2EBrokerAuditingTests {

    /*
     Used to check an Expectation continuously
     i.e. for Expectations when we don't know exactly when they will complete
     but don't want to have to wait unnecessarily since they may take some time
     */
    private func awaitFulfillment(of expectation: XCTestExpectation, withTimeout timeout: TimeInterval, whenCondition condition: @escaping () async -> Bool) async {
        let task = Task {
            await fulfillExpecation(expectation, whenCondition: condition)
        }

        await fulfillment(of: [expectation], timeout: timeout)
        task.cancel()
    }

    // Helper function for the above
    private func fulfillExpecation(_ expectation: XCTestExpectation, whenCondition condition: () async -> Bool) async {
        while await !condition() { }
        expectation.fulfill()
    }

    /*
     Used instead of using assert etc directly so we get better error messages
     in the log when they fail.
     When we adopt Swift 6 can likely be replaced
     */
    private func assertCondition(withExpectationDescription description: String, condition: () -> Bool) {
        let expectation = expectation(description: description)
        if condition() {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0)
    }

    typealias PixelExpectation = (pixel: DataBrokerProtectionSharedPixels, expectation: XCTestExpectation)

    private func pixelKitToTest(_ pixelExpectations: [PixelExpectation]) -> PixelKit {
        return PixelKit(dryRun: false,
                        appVersion: "1.0.0",
                        defaultHeaders: [:],
                        defaults: testUserDefault) { pixelName, _, _, _, _, _ in
            for pixelExpectation in pixelExpectations where pixelName.hasPrefix(pixelExpectation.pixel.name) {
                pixelExpectation.expectation.fulfill()
            }
        }
    }

    func validateFakeBrokerResponse(responseData: Data, response: URLResponse) {
        // swiftlint:disable:next force_cast
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 {
            prettyPrintJSONData(responseData)
            XCTFail("Response code indidcates failure. Check the printed response data above (if expected json)")
        }
    }

    // A useful function for debugging responses from the fake broker
    func prettyPrintJSONData(_ data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = jsonData.utf8String() {
            print(jsonString)
        } else {
            print("json data malformed")
        }
    }
}

// MARK: - Mocks

private extension DBPE2EBrokerAuditingTests {

    var mockProfile: DataBrokerProtectionProfile {
        // Use the current year to calculate age, since the fake broker is static (so will always list "63")
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        let birthYear = year - 63

        return .init(names: [.init(firstName: "John", lastName: "Smith")],
                     addresses: [.init(city: "Dallas", state: "TX")],
                     phones: [],
                     birthYear: birthYear)
    }
}

// swiftlint:enable force_try
