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
    /// Baselines defined using performance tests and production measurements on device.
    /// All production metrics measure wall time (includes I/O, actor coordination, system overhead).
    ///
    /// Key Findings:
    /// - Incremental and full replacement updates have identical performance (both load/save entire dataset)
    /// - Small vs large incremental updates perform identically (time dominated by existing dataset I/O)
    ///
    /// Bucket Pattern (2× multiplier):
    /// - fast: < baseline × 2
    /// - normal: < baseline × 4 (fast × 2)
    /// - slow: < baseline × 8 (normal × 2)
    /// - outlier: ≥ baseline × 8
    private enum Thresholds {
        /// Single HashPrefix update (per threat)
        /// Performance test baseline: ~0.1s (aggregate 0.293s ÷ 3 threats)
        enum HashPrefixSingle {
            static let fast: TimeInterval = 0.2        // 0.1 × 2
            static let normal: TimeInterval = 0.4      // 0.2 × 2
            static let slow: TimeInterval = 0.8        // 0.4 × 2
        }

        /// Single FilterSet update (per threat)
        /// Performance test baseline: ~1.4s (aggregate 4.252s ÷ 3 threats)
        enum FilterSetSingle {
            static let fast: TimeInterval = 2.8        // 1.4 × 2
            static let normal: TimeInterval = 5.6      // 2.8 × 2
            static let slow: TimeInterval = 11.2       // 5.6 × 2
        }

        /// Aggregate HashPrefix update (all 3 threats combined)
        /// Performance test CPU time: 0.293s (aggregate for all 3 threats)
        /// Production wall time: 1.4-2.0s (includes I/O, actor coordination, system overhead)
        /// Thresholds account for device variance and run-to-run variance (40-50%)
        enum HashPrefixAggregate {
            static let fast: TimeInterval = 2.5        // Baseline accounting for variance
            static let normal: TimeInterval = 5.0      // 2.5 × 2
            static let slow: TimeInterval = 10.0       // 5.0 × 2
        }

        /// Aggregate FilterSet update (all 3 threats combined)
        /// Performance test CPU time: 4.252s (aggregate for all 3 threats)
        /// Production wall time: 1.6-2.2s (includes I/O, actor coordination, system overhead)
        /// Thresholds account for device variance and run-to-run variance (40-50%)
        enum FilterSetAggregate {
            static let fast: TimeInterval = 3.0        // Baseline accounting for variance
            static let normal: TimeInterval = 6.0      // 3.0 × 2
            static let slow: TimeInterval = 12.0       // 6.0 × 2
        }
    }

}
