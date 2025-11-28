//
//  MaliciousSiteProtectionPerformanceTests.swift
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

import XCTest
@testable import MaliciousSiteProtection

final class MaliciousSiteProtectionPerformanceTests: XCTestCase {

    static let tempDir: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    static let metrics: [any XCTMetric] = [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric(), XCTStorageMetric()]

    override class func setUp() {
        super.setUp()

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            XCTFail("Could not prepare test directory: \(error)")
        }
    }

    override class func tearDown() {
        super.tearDown()

        do {
            try FileManager.default.removeItem(at: tempDir)
        } catch {
            XCTFail("Could not cleanup test directory: \(error)")
        }
    }

    // MARK: - Stress Tests (Single Dataset)

    func testInitialHashPrefix_LargeDataset() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_large_\(dataType.kind)_\(dataType.threatKind).json" })
        let initialDataSet = makeHashPrefixSet(itemCount: 700_000, revision: 0)
        let changeSet = APIClient.ChangeSetResponse(
            insert: Array(initialDataSet.set),
            delete: [],
            revision: 1,
            replace: true
        )

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    try await dataManager.updateDataSet(with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam), changeSet: changeSet)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testInitialHashPrefix_ExtraLargeDataset() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_extra-large_\(dataType.kind)_\(dataType.threatKind).json" })
        let initialDataSet = makeHashPrefixSet(itemCount: 1_400_000, revision: 0)
        let changeSet = APIClient.ChangeSetResponse(
            insert: Array(initialDataSet.set),
            delete: [],
            revision: 1,
            replace: true
        )

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    try await dataManager.updateDataSet(with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam), changeSet: changeSet)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testInitialFilterSet_LargeDataset() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_large_\(dataType.kind)_\(dataType.threatKind).json" })
        let initialDataSet = makeFilterSet(itemCount: 700_000, revision: 0)
        var filters: [Filter] = []
        for (hash, regexSet) in initialDataSet.filters {
            for regex in regexSet {
                filters.append(Filter(hash: hash, regex: regex))
            }
        }

        let changeSet = APIClient.ChangeSetResponse(
            insert: filters,
            delete: [],
            revision: 1,
            replace: true
        )

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    try await dataManager.updateDataSet(with: DataManager.StoredDataType.FilterSet(threatKind: .scam), changeSet: changeSet)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testInitialFilterSet_ExtraLargeDataset() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_extra-large_\(dataType.kind)_\(dataType.threatKind).json" })
        let initialDataSet = makeFilterSet(itemCount: 1_400_000, revision: 0)
        var filters: [Filter] = []
        for (hash, regexSet) in initialDataSet.filters {
            for regex in regexSet {
                filters.append(Filter(hash: hash, regex: regex))
            }
        }

        let changeSet = APIClient.ChangeSetResponse(
            insert: filters,
            delete: [],
            revision: 1,
            replace: true
        )

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    try await dataManager.updateDataSet(with: DataManager.StoredDataType.FilterSet(threatKind: .scam), changeSet: changeSet)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }

    // MARK: - Real-World Scenarios (Multiple Threats)

    func testFirstLaunch_AllThreats_AllDatasets() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_first_launch_\(dataType.kind)_\(dataType.threatKind).json" })

        // Simulate real production dataset sizes for all three threats
        let scamHashPrefixes = makeScamHashPrefix(revision: 0)
        let malwareHashPrefixes = makeMalwareHashPrefix(revision: 0)
        let phishingHashPrefixes = makePhishingHashPrefix(revision: 0)

        let scamFilterSet = makeScamFilterSet(revision: 0)
        let malwareFilterSet = makeMalwareFilterSet(revision: 0)
        let phishingFilterSet = makePhishingFilterSet(revision: 0)

        let scamFilters = filtersArray(from: scamFilterSet)
        let malwareFilters = filtersArray(from: malwareFilterSet)
        let phishingFilters = filtersArray(from: phishingFilterSet)

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    // First launch: process all 6 datasets (3 HashPrefixes + 3 FilterSets)
                    // HashPrefixes
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(scamHashPrefixes.set), delete: [], revision: 1, replace: true)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(malwareHashPrefixes.set), delete: [], revision: 1, replace: true)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(phishingHashPrefixes.set), delete: [], revision: 1, replace: true)
                    )

                    // FilterSets
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: scamFilters, delete: [], revision: 1, replace: true)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: malwareFilters, delete: [], revision: 1, replace: true)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: phishingFilters, delete: [], revision: 1, replace: true)
                    )

                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 120.0)
        }
    }

    func testIncrementalUpdate_AllThreats_HashPrefixes() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_incremental_hashprefixes_\(dataType.kind)_\(dataType.threatKind).json" })

        // Setup: Initialise all three threats with production-like sizes
        let scamDataSet = makeScamHashPrefix(revision: 1)
        let malwareDataSet = makeMalwareHashPrefix(revision: 1)
        let phishingDataSet = makePhishingHashPrefix(revision: 1)

        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
            changeSet: APIClient.ChangeSetResponse(insert: Array(scamDataSet.set), delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
            changeSet: APIClient.ChangeSetResponse(insert: Array(malwareDataSet.set), delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
            changeSet: APIClient.ChangeSetResponse(insert: Array(phishingDataSet.set), delete: [], revision: 1, replace: true)
        )

        // Create change sets for each threat (400 items - simulates 8-hour gap with 10 items every 20 min)
        let scamChanges = makeNewHashPrefixes(from: scamDataSet, count: 400)
        let malwareChanges = makeNewHashPrefixes(from: malwareDataSet, count: 400)
        let phishingChanges = makeNewHashPrefixes(from: phishingDataSet, count: 400)

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    // Typical foreground update: process all three HashPrefixes with INSERT operations
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(scamChanges), delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(malwareChanges), delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(phishingChanges), delete: [], revision: 2, replace: false)
                    )

                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testIncrementalUpdate_AllThreats_FilterSets() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_incremental_filtersets_\(dataType.kind)_\(dataType.threatKind).json" })

        // Setup: Initialise all three threats with production-like sizes
        let scamDataSet = makeScamFilterSet(revision: 1)
        let malwareDataSet = makeMalwareFilterSet(revision: 1)
        let phishingDataSet = makePhishingFilterSet(revision: 1)

        let scamFilters = filtersArray(from: scamDataSet)
        let malwareFilters = filtersArray(from: malwareDataSet)
        let phishingFilters = filtersArray(from: phishingDataSet)

        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
            changeSet: APIClient.ChangeSetResponse(insert: scamFilters, delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
            changeSet: APIClient.ChangeSetResponse(insert: malwareFilters, delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
            changeSet: APIClient.ChangeSetResponse(insert: phishingFilters, delete: [], revision: 1, replace: true)
        )

        // Create change sets for each threat (400 items - simulates 8-hour gap with 10 items every 20 min)
        let scamChanges = makeNewFilters(from: scamDataSet, count: 400, shouldCreateNewHashes: true)
        let malwareChanges = makeNewFilters(from: malwareDataSet, count: 400, shouldCreateNewHashes: true)
        let phishingChanges = makeNewFilters(from: phishingDataSet, count: 400, shouldCreateNewHashes: true)

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    // FilterSet update: process all three FilterSets with INSERT operations
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: scamChanges, delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: malwareChanges, delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: phishingChanges, delete: [], revision: 2, replace: false)
                    )

                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 60.0)
        }
    }

    func testIncrementalUpdate_AllThreats_AllDatasets_Coincide() async throws {
        let dataManager = makeDataManager(fileNameProvider: { dataType in "test_incremental_all_\(dataType.kind)_\(dataType.threatKind).json" })

        // Setup: Initialise all six datasets with production-like sizes
        let scamHashPrefixes = makeScamHashPrefix(revision: 1)
        let malwareHashPrefixes = makeMalwareHashPrefix(revision: 1)
        let phishingHashPrefixes = makePhishingHashPrefix(revision: 1)

        let scamFilterSet = makeScamFilterSet(revision: 1)
        let malwareFilterSet = makeMalwareFilterSet(revision: 1)
        let phishingFilterSet = makePhishingFilterSet(revision: 1)

        let scamFilters = filtersArray(from: scamFilterSet)
        let malwareFilters = filtersArray(from: malwareFilterSet)
        let phishingFilters = filtersArray(from: phishingFilterSet)

        // Initialise all datasets
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
            changeSet: APIClient.ChangeSetResponse(insert: Array(scamHashPrefixes.set), delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
            changeSet: APIClient.ChangeSetResponse(insert: Array(malwareHashPrefixes.set), delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
            changeSet: APIClient.ChangeSetResponse(insert: Array(phishingHashPrefixes.set), delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
            changeSet: APIClient.ChangeSetResponse(insert: scamFilters, delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
            changeSet: APIClient.ChangeSetResponse(insert: malwareFilters, delete: [], revision: 1, replace: true)
        )
        try await dataManager.updateDataSet(
            with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
            changeSet: APIClient.ChangeSetResponse(insert: phishingFilters, delete: [], revision: 1, replace: true)
        )

        // Create change sets for all 6 datasets (400 items each - simulates 8-hour gap when both HashPrefixes and FilterSets need updating)
        let scamHashChanges = makeNewHashPrefixes(from: scamHashPrefixes, count: 400)
        let malwareHashChanges = makeNewHashPrefixes(from: malwareHashPrefixes, count: 400)
        let phishingHashChanges = makeNewHashPrefixes(from: phishingHashPrefixes, count: 400)

        let scamFilterChanges = makeNewFilters(from: scamFilterSet, count: 400, shouldCreateNewHashes: true)
        let malwareFilterChanges = makeNewFilters(from: malwareFilterSet, count: 400, shouldCreateNewHashes: true)
        let phishingFilterChanges = makeNewFilters(from: phishingFilterSet, count: 400, shouldCreateNewHashes: true)

        measure(metrics: Self.metrics) {
            let expectation = self.expectation(description: "Update completes")

            Task {
                do {
                    // Worst-case incremental: all 6 datasets update at once with INSERT operations (e.g., app dormant for 8+ hours)
                    // HashPrefixes
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(scamHashChanges), delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(malwareHashChanges), delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: Array(phishingHashChanges), delete: [], revision: 2, replace: false)
                    )

                    // FilterSets
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
                        changeSet: APIClient.ChangeSetResponse(insert: scamFilterChanges, delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
                        changeSet: APIClient.ChangeSetResponse(insert: malwareFilterChanges, delete: [], revision: 2, replace: false)
                    )
                    try await dataManager.updateDataSet(
                        with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
                        changeSet: APIClient.ChangeSetResponse(insert: phishingFilterChanges, delete: [], revision: 2, replace: false)
                    )

                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to update dataset: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 90.0)
        }
    }

    func testSmallIncrementalUpdate_AllThreats_HashPrefixes() async throws {
          let dataManager = makeDataManager(fileNameProvider: { dataType in
      "test_small_incremental_hashprefixes_\(dataType.kind)_\(dataType.threatKind).json" })

          // Setup: Initialise all three threats with production-like sizes
          let scamDataSet = makeScamHashPrefix(revision: 1)
          let malwareDataSet = makeMalwareHashPrefix(revision: 1)
          let phishingDataSet = makePhishingHashPrefix(revision: 1)

          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
              changeSet: APIClient.ChangeSetResponse(insert: Array(scamDataSet.set), delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
              changeSet: APIClient.ChangeSetResponse(insert: Array(malwareDataSet.set), delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
              changeSet: APIClient.ChangeSetResponse(insert: Array(phishingDataSet.set), delete: [], revision: 1, replace: true)
          )

          // Create change sets for each threat (10 items - simulates current 20-min interval)
          let scamChanges = makeNewHashPrefixes(from: scamDataSet, count: 10)
          let malwareChanges = makeNewHashPrefixes(from: malwareDataSet, count: 10)
          let phishingChanges = makeNewHashPrefixes(from: phishingDataSet, count: 10)

          measure(metrics: Self.metrics) {
              let expectation = self.expectation(description: "Update completes")

              Task {
                  do {
                      // Small incremental update: process all three HashPrefixes with INSERT operations (current 20-min behavior)
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(scamChanges), delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(malwareChanges), delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(phishingChanges), delete: [], revision: 2, replace: false)
                      )

                      expectation.fulfill()
                  } catch {
                      XCTFail("Failed to update dataset: \(error)")
                      expectation.fulfill()
                  }
              }

              wait(for: [expectation], timeout: 30.0)
          }
      }

      func testSmallIncrementalUpdate_AllThreats_FilterSets() async throws {
          let dataManager = makeDataManager(fileNameProvider: { dataType in
      "test_small_incremental_filtersets_\(dataType.kind)_\(dataType.threatKind).json" })

          // Setup: Initialise all three threats with production-like sizes
          let scamDataSet = makeScamFilterSet(revision: 1)
          let malwareDataSet = makeMalwareFilterSet(revision: 1)
          let phishingDataSet = makePhishingFilterSet(revision: 1)

          let scamFilters = filtersArray(from: scamDataSet)
          let malwareFilters = filtersArray(from: malwareDataSet)
          let phishingFilters = filtersArray(from: phishingDataSet)

          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
              changeSet: APIClient.ChangeSetResponse(insert: scamFilters, delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
              changeSet: APIClient.ChangeSetResponse(insert: malwareFilters, delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
              changeSet: APIClient.ChangeSetResponse(insert: phishingFilters, delete: [], revision: 1, replace: true)
          )

          // Create change sets for each threat (10 items - simulates current 20-min interval)
          let scamChanges = makeNewFilters(from: scamDataSet, count: 10, shouldCreateNewHashes: true)
          let malwareChanges = makeNewFilters(from: malwareDataSet, count: 10, shouldCreateNewHashes: true)
          let phishingChanges = makeNewFilters(from: phishingDataSet, count: 10, shouldCreateNewHashes: true)

          measure(metrics: Self.metrics) {
              let expectation = self.expectation(description: "Update completes")

              Task {
                  do {
                      // Small incremental FilterSet update: process all three FilterSets with INSERT operations (current 20-min behavior)
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
                          changeSet: APIClient.ChangeSetResponse(insert: scamChanges, delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
                          changeSet: APIClient.ChangeSetResponse(insert: malwareChanges, delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
                          changeSet: APIClient.ChangeSetResponse(insert: phishingChanges, delete: [], revision: 2, replace: false)
                      )

                      expectation.fulfill()
                  } catch {
                      XCTFail("Failed to update dataset: \(error)")
                      expectation.fulfill()
                  }
              }

              wait(for: [expectation], timeout: 60.0)
          }
      }

      func testSmallIncrementalUpdate_AllThreats_AllDatasets_Coincide() async throws {
          let dataManager = makeDataManager(fileNameProvider: { dataType in "test_small_incremental_all_\(dataType.kind)_\(dataType.threatKind).json" })

          // Setup: Initialise all six datasets with production-like sizes
          let scamHashPrefixes = makeScamHashPrefix(revision: 1)
          let malwareHashPrefixes = makeMalwareHashPrefix(revision: 1)
          let phishingHashPrefixes = makePhishingHashPrefix(revision: 1)

          let scamFilterSet = makeScamFilterSet(revision: 1)
          let malwareFilterSet = makeMalwareFilterSet(revision: 1)
          let phishingFilterSet = makePhishingFilterSet(revision: 1)

          let scamFilters = filtersArray(from: scamFilterSet)
          let malwareFilters = filtersArray(from: malwareFilterSet)
          let phishingFilters = filtersArray(from: phishingFilterSet)

          // Initialise all datasets
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
              changeSet: APIClient.ChangeSetResponse(insert: Array(scamHashPrefixes.set), delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
              changeSet: APIClient.ChangeSetResponse(insert: Array(malwareHashPrefixes.set), delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
              changeSet: APIClient.ChangeSetResponse(insert: Array(phishingHashPrefixes.set), delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
              changeSet: APIClient.ChangeSetResponse(insert: scamFilters, delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
              changeSet: APIClient.ChangeSetResponse(insert: malwareFilters, delete: [], revision: 1, replace: true)
          )
          try await dataManager.updateDataSet(
              with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
              changeSet: APIClient.ChangeSetResponse(insert: phishingFilters, delete: [], revision: 1, replace: true)
          )

          // Create change sets for all 6 datasets (10 items each - simulates current 20-min interval when both coincide)
          let scamHashChanges = makeNewHashPrefixes(from: scamHashPrefixes, count: 10)
          let malwareHashChanges = makeNewHashPrefixes(from: malwareHashPrefixes, count: 10)
          let phishingHashChanges = makeNewHashPrefixes(from: phishingHashPrefixes, count: 10)

          let scamFilterChanges = makeNewFilters(from: scamFilterSet, count: 10, shouldCreateNewHashes: true)
          let malwareFilterChanges = makeNewFilters(from: malwareFilterSet, count: 10, shouldCreateNewHashes: true)
          let phishingFilterChanges = makeNewFilters(from: phishingFilterSet, count: 10, shouldCreateNewHashes: true)

          measure(metrics: Self.metrics) {
              let expectation = self.expectation(description: "Update completes")

              Task {
                  do {
                      // Small incremental: all 6 datasets update at once with INSERT operations (current 20-min behavior when both coincide)
                      // HashPrefixes
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .scam),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(scamHashChanges), delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .malware),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(malwareHashChanges), delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.HashPrefixes(threatKind: .phishing),
                          changeSet: APIClient.ChangeSetResponse(insert: Array(phishingHashChanges), delete: [], revision: 2, replace: false)
                      )

                      // FilterSets
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .scam),
                          changeSet: APIClient.ChangeSetResponse(insert: scamFilterChanges, delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .malware),
                          changeSet: APIClient.ChangeSetResponse(insert: malwareFilterChanges, delete: [], revision: 2, replace: false)
                      )
                      try await dataManager.updateDataSet(
                          with: DataManager.StoredDataType.FilterSet(threatKind: .phishing),
                          changeSet: APIClient.ChangeSetResponse(insert: phishingFilterChanges, delete: [], revision: 2, replace: false)
                      )

                      expectation.fulfill()
                  } catch {
                      XCTFail("Failed to update dataset: \(error)")
                      expectation.fulfill()
                  }
              }

              wait(for: [expectation], timeout: 90.0)
          }
      }

}

// MARK: - Test Data Generators

private extension MaliciousSiteProtectionPerformanceTests {

    func makeDataManager(fileNameProvider: @escaping (DataManager.StoredDataType) -> String) -> DataManager {
        let fileStore = FileStore(dataStoreURL: Self.tempDir)
        return DataManager(
            fileStore: fileStore,
            embeddedDataProvider: nil,
            fileNameProvider: fileNameProvider
        )
    }

    // MARK: - Production Dataset Generators (based on actual production sizes)

    func makeScamHashPrefix(revision: Int = 1) -> HashPrefixSet {
        makeHashPrefixSet(itemCount: 36_000, revision: revision)  // Scam: ~292 KB
    }

    func makeMalwareHashPrefix(revision: Int = 1) -> HashPrefixSet {
        makeHashPrefixSet(itemCount: 120_000, revision: revision)  // Malware: ~1.0 MB
    }

    func makePhishingHashPrefix(revision: Int = 1) -> HashPrefixSet {
        makeHashPrefixSet(itemCount: 900_000, revision: revision)  // Phishing: ~7.3 MB
    }

    func makeScamFilterSet(revision: Int = 1) -> FilterDictionary {
        makeFilterSet(itemCount: 200_000, revision: revision)  // Scam: ~1.6 MB
    }

    func makeMalwareFilterSet(revision: Int = 1) -> FilterDictionary {
        makeFilterSet(itemCount: 350_000, revision: revision)  // Malware: ~2.5 MB
    }

    func makePhishingFilterSet(revision: Int = 1) -> FilterDictionary {
        makeFilterSet(itemCount: 2_000_000, revision: revision)  // Phishing: ~25 MB
    }

    func makeHashPrefixSet(itemCount: Int, revision: Int = 1) -> HashPrefixSet {
        let items = (0..<itemCount).map { i in
            String(format: "%08x", i)
        }
        return HashPrefixSet(revision: revision, items: items)
    }

    func makeFilterSet(itemCount: Int, revision: Int = 1) -> FilterDictionary {
        let items = (0..<itemCount).map { i in
            let hash = String(format: "%016x", i)
            let regex = ".*\(i).*"
            return Filter(hash: hash, regex: regex)
        }
        return FilterDictionary(revision: revision, items: items)
    }

    func filtersArray(from filterDictionary: FilterDictionary) -> [Filter] {
        var filters: [Filter] = []
        for (hash, regexSet) in filterDictionary.filters {
            for regex in regexSet {
                filters.append(Filter(hash: hash, regex: regex))
            }
        }
        return filters
    }

    // Generate new hash prefixes by shuffling existing ones (simulates new threats)
    func makeNewHashPrefixes(from dataset: HashPrefixSet, count: Int) -> [String] {
        Array(dataset.set).prefix(count).map { String($0.shuffled()) }
    }

    // Generate new filters - either with new hashes or new regex patterns for existing hashes
    func makeNewFilters(from filterDictionary: FilterDictionary, count: Int, shouldCreateNewHashes: Bool) -> [Filter] {
        // Add new regex patterns to existing hashes
        let filters = Array(filterDictionary.filters.keys.prefix(count))
        return filters.enumerated().map { i, hash in
            let newHash = shouldCreateNewHashes ? String(hash.shuffled()) : hash
            return Filter(hash: newHash, regex: ".*new_\(i).*")
        }
    }

}
