//
//  Event+Performance.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

// MARK: - Datasets Info

public struct SingleDataSetUpdateInfo: Equatable, CustomDebugStringConvertible {
    /// The threat category being updated (malware, phishing, or scam)
    public let category: ThreatKind
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The revision number before the update
    public let fromRevision: Int
    /// The revision number after the update
    public let toRevision: Int
    /// The time spent processing the update (encoding + disk writes), in seconds
    public let processingTimeSeconds: TimeInterval
    /// The amount of data written to disk, in megabytes
    public let diskWritesMB: Double
    /// The configured update frequency for this dataset type, in minutes
    public let updateFrequencyMinutes: Double
    /// Whether this was a full dataset replacement (true) or incremental update (false)
    public let isFullReplacement: Bool
    /// Performance bucket classification (fast, normal, slow, outlier)
    public let bucket: String

    public var debugDescription: String {
        let updateType = isFullReplacement ? "replace" : "incremental"
        return "SingleDataSetUpdateInfo(category: \(category.rawValue), type: \(type.rawValue), rev: \(fromRevision)→\(toRevision), time: \(String(format: "%.3f", processingTimeSeconds))s, disk: \(String(format: "%.2f", diskWritesMB))MB, frequency: \(updateFrequencyMinutes)min, updateType: \(updateType), bucket: \(bucket))"
    }

    public init(
        category: ThreatKind,
        type: DataManager.StoredDataType.Kind,
        fromRevision: Int,
        toRevision: Int,
        processingTimeSeconds: TimeInterval,
        diskWritesMB: Double,
        updateFrequencyMinutes: Double,
        isFullReplacement: Bool,
        bucket: String
    ) {
        self.category = category
        self.type = type
        self.fromRevision = fromRevision
        self.toRevision = toRevision
        self.processingTimeSeconds = processingTimeSeconds
        self.diskWritesMB = diskWritesMB
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.isFullReplacement = isFullReplacement
        self.bucket = bucket
    }

}

public struct AggregateDataSetsUpdateInfo: Equatable, CustomDebugStringConvertible {
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The total time spent processing all threat categories for this dataset type, in seconds
    public let totalTimeSeconds: Double
    /// The total amount of data written to disk across all threats, in megabytes
    public let totalDiskWritesMB: Double
    /// The number of threat categories that updated successfully
    public let successCount: Int
    /// The total number of threat categories attempted
    public let totalCount: Int
    /// Performance bucket classification (fast, normal, slow, outlier)
    public let bucket: String

    public init(
        type: DataManager.StoredDataType.Kind,
        totalTimeSeconds: TimeInterval,
        totalDiskWritesMB: Double,
        successCount: Int,
        totalCount: Int,
        bucket: String
    ) {
        self.type = type
        self.totalTimeSeconds = totalTimeSeconds
        self.totalDiskWritesMB = totalDiskWritesMB
        self.successCount = successCount
        self.totalCount = totalCount
        self.bucket = bucket
    }

    public var debugDescription: String {
        return "AggregateDataSetsUpdateInfo(type: \(type.rawValue), totalTime: \(String(format: "%.3f", totalTimeSeconds))s, disk: \(String(format: "%.2f", totalDiskWritesMB))MB, success: \(successCount)/\(totalCount), bucket: \(bucket))"
    }
}

// MARK: - Performance Buckets

/// Performance bucket categorisation for malicious site protection dataset updates.
enum DataSetUpdatePerformanceBucket: String {
    case fast = "fast"
    case normal = "normal"
    case slow = "slow"
    case outlier = "outlier"

    /// Determines the performance bucket for a dataset update.
    ///
    /// Note: Both incremental and full replacement updates use the same thresholds because
    /// processing time is dominated by loading/saving the entire dataset, not by the number
    /// of items being added or replaced.
    static func bucketForSingleDataSetUpdate(
        type: DataManager.StoredDataType.Kind,
        processingTime: TimeInterval
    ) -> DataSetUpdatePerformanceBucket {
        switch type {
        case .hashPrefixSet:
            if processingTime < Thresholds.HashPrefixSingle.fast {
                return .fast
            } else if processingTime < Thresholds.HashPrefixSingle.normal {
                return .normal
            } else if processingTime < Thresholds.HashPrefixSingle.slow {
                return .slow
            } else {
                return .outlier
            }

        case .filterSet:
            if processingTime < Thresholds.FilterSetSingle.fast {
                return .fast
            } else if processingTime < Thresholds.FilterSetSingle.normal {
                return .normal
            } else if processingTime < Thresholds.FilterSetSingle.slow {
                return .slow
            } else {
                return .outlier
            }
        }
    }

    /// Determines the performance bucket for an aggregate update (all 3 threat categories combined).
    static func bucketForAggregateDataSetsUpdate(
        type: DataManager.StoredDataType.Kind,
        totalProcessingTime: TimeInterval
    ) -> DataSetUpdatePerformanceBucket {
        switch type {
        case .hashPrefixSet:
            if totalProcessingTime < Thresholds.HashPrefixAggregate.fast {
                return .fast
            } else if totalProcessingTime < Thresholds.HashPrefixAggregate.normal {
                return .normal
            } else if totalProcessingTime < Thresholds.HashPrefixAggregate.slow {
                return .slow
            } else {
                return .outlier
            }

        case .filterSet:
            if totalProcessingTime < Thresholds.FilterSetAggregate.fast {
                return .fast
            } else if totalProcessingTime < Thresholds.FilterSetAggregate.normal {
                return .normal
            } else if totalProcessingTime < Thresholds.FilterSetAggregate.slow {
                return .slow
            } else {
                return .outlier
            }
        }
    }

}

// MARK: - Performance Thresholds

private extension DataSetUpdatePerformanceBucket {

    /// Performance thresholds for malicious site protection dataset updates.
    ///
    /// All thresholds based on clock time measurements from performance tests running on device
    /// with current production dataset sizes (as of Nov 2025, revision `1798895`).
    ///
    /// Current Dataset Sizes:
    /// - HashPrefix: 567K items total (29K scam, 84K malware, 454K phishing)
    /// - FilterSet: 165K items total (12K scam, 18K malware, 135K phishing)
    ///
    /// Device Performance Test Results (iPhone, clock time):
    /// - HashPrefix aggregate: 0.207s
    /// - FilterSet aggregate: 0.311s
    /// - Production measurements: HashPrefix ~1.6s, FilterSet ~1.9s (5-6× slower due to real-world overhead)
    ///
    /// Key Performance Findings:
    /// - Incremental and full replacement updates have identical performance (both load/save entire dataset)
    /// - Small vs large incremental updates perform identically (time dominated by existing dataset I/O)
    /// - Production overhead (5-6×) comes from: background processes, thermal throttling, I/O contention, actor coordination
    ///
    /// Bucket Design Philosophy:
    /// - fast: Device test baseline (optimal performance when device is idle, no background activity)
    /// - normal: Production typical (~4-5× device test, representing real-world overhead)
    /// - slow: 2× production typical (device under load, thermal throttling, or heavy I/O)
    /// - outlier: 4× production typical (indicates serious performance issues requiring investigation)
    private enum Thresholds {
        /// Single HashPrefix update (per threat)
        /// Device test baseline: ~0.069s per threat (0.207s aggregate ÷ 3 threats)
        /// Rounded to 0.25s for "fast" to account for measurement variance
        enum HashPrefixSingle {
            static let fast: TimeInterval = 0.25       // Device test baseline (optimal)
            static let normal: TimeInterval = 0.5      // 0.25 × 2 (typical production per-threat)
            static let slow: TimeInterval = 1.0        // 0.5 × 2 (device under load)
        }

        /// Single FilterSet update (per threat)
        /// Device test baseline: ~0.104s per threat (0.311s aggregate ÷ 3 threats)
        /// Rounded to 0.5s for "fast" to account for measurement variance
        enum FilterSetSingle {
            static let fast: TimeInterval = 0.5        // Device test baseline (optimal)
            static let normal: TimeInterval = 1.0      // 0.5 × 2 (typical production per-threat)
            static let slow: TimeInterval = 2.0        // 1.0 × 2 (device under load)
        }

        /// Aggregate HashPrefix update (all 3 threats combined)
        /// Device test baseline: 0.207s clock time
        /// Production typical: ~1.6s (falls into "normal" bucket: 1.0s < 1.6s < 2.0s)
        enum HashPrefixAggregate {
            static let fast: TimeInterval = 0.25       // Device test baseline (optimal)
            static let normal: TimeInterval = 1.0      // 0.25 × 4 (typical production with overhead)
            static let slow: TimeInterval = 2.0        // 1.0 × 2 (device under load)
        }

        /// Aggregate FilterSet update (all 3 threats combined)
        /// Device test baseline: 0.311s clock time
        /// Production typical: ~1.9s (falls into "normal" bucket: 1.5s < 1.9s < 3.0s)
        enum FilterSetAggregate {
            static let fast: TimeInterval = 0.5        // Device test baseline (optimal)
            static let normal: TimeInterval = 1.5      // 0.5 × 3 (typical production with overhead)
            static let slow: TimeInterval = 3.0        // 1.5 × 2 (device under load)
        }
    }

}
