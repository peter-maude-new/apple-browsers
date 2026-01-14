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

// MARK: - Performance Event Info

/// Information about dataset update performance (time-based metrics only).
public struct SingleDataSetUpdatePerformanceInfo: Equatable, CustomDebugStringConvertible {
    /// The threat category being updated (malware, phishing, or scam)
    public let category: ThreatKind
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The revision number before the update
    public let fromRevision: Int
    /// The revision number after the update
    public let toRevision: Int
    /// Whether this was a full dataset replacement (true) or incremental update (false)
    public let isFullReplacement: Bool
    /// The configured update frequency for this dataset type, in minutes
    public let updateFrequencyMinutes: Double
    /// Performance bucket classification (fast, normal, slow, outlier)
    public let performanceBucket: String

    public init(
        category: ThreatKind,
        type: DataManager.StoredDataType.Kind,
        fromRevision: Int,
        toRevision: Int,
        isFullReplacement: Bool,
        updateFrequencyMinutes: Double,
        performanceBucket: String
    ) {
        self.category = category
        self.type = type
        self.fromRevision = fromRevision
        self.toRevision = toRevision
        self.isFullReplacement = isFullReplacement
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.performanceBucket = performanceBucket
    }

    public var debugDescription: String {
        let updateType = isFullReplacement ? "replace" : "incremental"
        return "SingleDataSetUpdatePerformanceInfo(category: \(category.rawValue), type: \(type.rawValue), rev: \(fromRevision)→\(toRevision), updateType: \(updateType), frequency: \(updateFrequencyMinutes)min, bucket: \(performanceBucket))"
    }
}

/// Information about dataset update disk usage (disk-based metrics only).
public struct SingleDataSetUpdateDiskUsageInfo: Equatable, CustomDebugStringConvertible {
    /// The threat category being updated (malware, phishing, or scam)
    public let category: ThreatKind
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The revision number after the update
    public let toRevision: Int
    /// The configured update frequency for this dataset type, in minutes
    public let updateFrequencyMinutes: Double
    /// Disk usage bucket classification (small, medium, large, xlarge)
    public let diskUsageBucket: String

    public init(
        category: ThreatKind,
        type: DataManager.StoredDataType.Kind,
        toRevision: Int,
        updateFrequencyMinutes: Double,
        diskUsageBucket: String
    ) {
        self.category = category
        self.type = type
        self.toRevision = toRevision
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.diskUsageBucket = diskUsageBucket
    }

    public var debugDescription: String {
        return "SingleDataSetUpdateDiskUsageInfo(category: \(category.rawValue), type: \(type.rawValue), rev: \(toRevision), frequency: \(updateFrequencyMinutes)min, bucket: \(diskUsageBucket))"
    }
}

/// Information about aggregate dataset update performance across all threat categories.
public struct AggregateDataSetPerformanceInfo: Equatable, CustomDebugStringConvertible {
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The configured update frequency for this dataset type, in minutes
    public let updateFrequencyMinutes: Double
    /// Performance bucket classification (fast, normal, slow, outlier)
    public let performanceBucket: String

    public init(
        type: DataManager.StoredDataType.Kind,
        updateFrequencyMinutes: Double,
        performanceBucket: String
    ) {
        self.type = type
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.performanceBucket = performanceBucket
    }

    public var debugDescription: String {
        return "AggregateDataSetPerformanceInfo(type: \(type.rawValue), bucket: \(performanceBucket))"
    }
}

/// Information about aggregate dataset update disk usage across all threat categories.
public struct AggregateDataSetUpdateDiskUsageInfo: Equatable, CustomDebugStringConvertible {
    /// The type of dataset being updated (hashPrefixSet or filterSet)
    public let type: DataManager.StoredDataType.Kind
    /// The configured update frequency for this dataset type, in minutes
    public let updateFrequencyMinutes: Double
    /// Disk usage bucket classification (small, medium, large, xlarge)
    public let diskUsageBucket: String

    public init(
        type: DataManager.StoredDataType.Kind,
        updateFrequencyMinutes: Double,
        diskUsageBucket: String
    ) {
        self.type = type
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.diskUsageBucket = diskUsageBucket
    }

    public var debugDescription: String {
        return "AggregateUpdateDiskUsageInfo(type: \(type.rawValue), bucket: \(diskUsageBucket))"
    }
}

// MARK: - Performance Buckets

/// Performance bucket categorisation for malicious site protection dataset updates.
enum DataSetUpdatePerformanceBucket: String {
    case fast = "fast"
    case normal = "normal"
    case slow = "slow"
    case outlier = "outlier"

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
    /// - Small vs large incremental updates perform identically (time dominated by dataset I/O)
    ///
    /// Bucket Design Philosophy:
    /// - fast: Device test baseline
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
            static let slow: TimeInterval = 1.0        // slow × 2 (device under load)
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

// MARK: - Disk Usage Buckets

/// Disk usage bucket categorisation for malicious site protection dataset updates.
enum DataSetUpdateDiskUsageBucket: String {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case xlarge = "xlarge"

    /// Disk usage thresholds for malicious site protection dataset updates.
    ///
    /// All thresholds based on production JSON file sizes (as of Nov 2025, revision `1798895`).
    ///
    /// Current Production Dataset Sizes:
    /// - HashPrefix: 6.0 MB total (0.3 MB scam, 0.9 MB malware, 4.8 MB phishing)
    /// - FilterSet: 26.2 MB total (1.7 MB scam, 2.5 MB malware, 22 MB phishing)
    ///
    /// Bucket Design Philosophy:
    /// - small: Typical size for scam datasets (smallest threat category)
    /// - medium: Typical size for malware datasets (mid-sized threat category)
    /// - large: Typical size for phishing datasets (largest threat category)
    /// - xlarge: Indicates dataset growth or anomaly requiring investigation
    ///
    /// The thresholds use production JSON file sizes to establish realistic baselines,
    /// with headroom for growth before triggering the next bucket tier.
    private enum DiskThresholds {
        /// Single HashPrefix update (per threat)
        /// Production sizes: scam ~0.3 MB, malware ~0.9 MB, phishing ~4.8 MB
        enum HashPrefixSingle {
            static let small: Double = 0.5      // < 0.5 MB (scam range)
            static let medium: Double = 2.0     // < 2.0 MB (malware range)
            static let large: Double = 8.0      // < 8.0 MB (phishing range with headroom)
        }
        
        /// Single FilterSet update (per threat)
        /// Production sizes: scam ~1.7 MB, malware ~2.5 MB, phishing ~22 MB
        enum FilterSetSingle {
            static let small: Double = 2.0      // < 2.0 MB (scam range)
            static let medium: Double = 5.0     // < 5.0 MB (malware range with headroom)
            static let large: Double = 30.0     // < 30 MB (phishing range with headroom)
        }
        
        /// Aggregate HashPrefix update (all 3 threats combined)
        /// Production total: ~6.0 MB
        enum HashPrefixAggregate {
            static let small: Double = 3.0      // < 3.0 MB (significantly below current)
            static let medium: Double = 6.0     // < 6.0 MB (current production baseline)
            static let large: Double = 12.0     // < 12.0 MB (2× current, significant growth)
        }
        
        /// Aggregate FilterSet update (all 3 threats combined)
        /// Production total: ~26.2 MB
        enum FilterSetAggregate {
            static let small: Double = 15.0     // < 15.0 MB (significantly below current)
            static let medium: Double = 30.0    // < 30.0 MB (current production baseline)
            static let large: Double = 50.0     // < 50.0 MB (2× current, significant growth)
        }
    }

    /// Determines the disk usage bucket for a single dataset update (per threat).
    static func bucketForSingleDataSetUpdate(
        type: DataManager.StoredDataType.Kind,
        diskWritesMB: Double
    ) -> DataSetUpdateDiskUsageBucket {
        switch type {
        case .hashPrefixSet:
            if diskWritesMB < DiskThresholds.HashPrefixSingle.small {
                return .small
            } else if diskWritesMB < DiskThresholds.HashPrefixSingle.medium {
                return .medium
            } else if diskWritesMB < DiskThresholds.HashPrefixSingle.large {
                return .large
            } else {
                return .xlarge
            }

        case .filterSet:
            if diskWritesMB < DiskThresholds.FilterSetSingle.small {
                return .small
            } else if diskWritesMB < DiskThresholds.FilterSetSingle.medium {
                return .medium
            } else if diskWritesMB < DiskThresholds.FilterSetSingle.large {
                return .large
            } else {
                return .xlarge
            }
        }
    }

    /// Determines the disk usage bucket for an aggregate update (all 3 threat categories combined).
    static func bucketForAggregateDataSetsUpdate(
        type: DataManager.StoredDataType.Kind,
        totalDiskWritesMB: Double
    ) -> DataSetUpdateDiskUsageBucket {
        switch type {
        case .hashPrefixSet:
            if totalDiskWritesMB < DiskThresholds.HashPrefixAggregate.small {
                return .small
            } else if totalDiskWritesMB < DiskThresholds.HashPrefixAggregate.medium {
                return .medium
            } else if totalDiskWritesMB < DiskThresholds.HashPrefixAggregate.large {
                return .large
            } else {
                return .xlarge
            }

        case .filterSet:
            if totalDiskWritesMB < DiskThresholds.FilterSetAggregate.small {
                return .small
            } else if totalDiskWritesMB < DiskThresholds.FilterSetAggregate.medium {
                return .medium
            } else if totalDiskWritesMB < DiskThresholds.FilterSetAggregate.large {
                return .large
            } else {
                return .xlarge
            }
        }
    }
}
