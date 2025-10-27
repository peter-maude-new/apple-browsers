# Bucket Time-Since-Last-Update for Privacy

## Overview

Replace the precise `time_since_last_update_ms` millisecond value with privacy-safe time buckets to prevent tracking individual users across update events while maintaining analytical insight into update frequency patterns.

## Time Buckets

- `<30m` - Less than 30 minutes
- `<2h` - Less than 2 hours  
- `<6h` - Less than 6 hours
- `<1d` - Less than 1 day (24 hours)
- `<2d` - Less than 2 days
- `<1w` - Less than 1 week (7 days)
- `<1M` - Less than 1 month (30 days)
- `>=1M` - Greater than or equal to 1 month

## Implementation (All Changes Together)

All changes below should be made together as a single atomic change. The parameter key will be renamed from `time_since_last_update_ms` to `time_since_last_update` as part of the implementation.

### Step 1: Add TimeSinceUpdateBucket Enum

**File**: `macOS/DuckDuckGo/Updates/Sparkle/UpdateWideEventData.swift`

**Location**: After the existing `UpdateStep` enum definition (around line 112), add:

```swift
/// Time bucket for privacy-safe update frequency tracking.
enum TimeSinceUpdateBucket: String, Codable {
    case lessThan30Minutes = "<30m"
    case lessThan2Hours = "<2h"
    case lessThan6Hours = "<6h"
    case lessThan1Day = "<1d"
    case lessThan2Days = "<2d"
    case lessThan1Week = "<1w"
    case lessThan1Month = "<1M"
    case greaterThanOrEqual1Month = ">=1M"
    
    init(interval: TimeInterval) {
        let minutes = interval / 60.0
        let hours = minutes / 60.0
        let days = hours / 24.0
        let weeks = days / 7.0
        let months = days / 30.0
        
        if months >= 1 {
            self = .greaterThanOrEqual1Month
        } else if weeks >= 1 {
            self = .lessThan1Month
        } else if days >= 2 {
            self = .lessThan1Week
        } else if days >= 1 {
            self = .lessThan2Days
        } else if hours >= 6 {
            self = .lessThan1Day
        } else if hours >= 2 {
            self = .lessThan6Hours
        } else if minutes >= 30 {
            self = .lessThan2Hours
        } else {
            self = .lessThan30Minutes
        }
    }
    
    /// Convenience initializer that calculates the interval between two dates.
    init(from lastDate: Date, to currentDate: Date = Date()) {
        let interval = currentDate.timeIntervalSince(lastDate)
        self.init(interval: interval)
    }
}
```

### Step 2: Update Property

**File**: `macOS/DuckDuckGo/Updates/Sparkle/UpdateWideEventData.swift`  
**Line**: ~67

Replace:
```swift
var timeSinceLastUpdateMs: Int?
```

With:
```swift
var timeSinceLastUpdateBucket: TimeSinceUpdateBucket?
```

### Step 3: Update Init Parameter

**File**: `macOS/DuckDuckGo/Updates/Sparkle/UpdateWideEventData.swift`  
**Line**: ~126

Replace:
```swift
timeSinceLastUpdateMs: Int? = nil,
```

With:
```swift
timeSinceLastUpdateBucket: TimeSinceUpdateBucket? = nil,
```

### Step 4: Update Init Assignment

**File**: `macOS/DuckDuckGo/Updates/Sparkle/UpdateWideEventData.swift`  
**Line**: ~147

Replace:
```swift
self.timeSinceLastUpdateMs = timeSinceLastUpdateMs
```

With:
```swift
self.timeSinceLastUpdateBucket = timeSinceLastUpdateBucket
```

### Step 5: Update pixelParameters Method

**File**: `macOS/DuckDuckGo/Updates/Sparkle/UpdateWideEventData.swift`  
**Line**: ~205-207

Replace:
```swift
if let timeSinceUpdate = timeSinceLastUpdateMs {
    parameters["feature.data.ext.time_since_last_update_ms"] = String(timeSinceUpdate)
}
```

With:
```swift
if let bucket = timeSinceLastUpdateBucket {
    parameters["feature.data.ext.time_since_last_update"] = bucket.rawValue
}
```

### Step 6: Update Flow Logic

**File**: `macOS/DuckDuckGo/Updates/Sparkle/SparkleUpdateWideEvent.swift`  
**Line**: ~123-126

Replace:
```swift
if let lastUpdateDate = Self.lastSuccessfulUpdateDate {
    let timeSinceMs = Int(Date().timeIntervalSince(lastUpdateDate) * 1000)
    data.timeSinceLastUpdateMs = timeSinceMs
}
```

With:
```swift
if let lastUpdateDate = Self.lastSuccessfulUpdateDate {
    data.timeSinceLastUpdateBucket = UpdateWideEventData.TimeSinceUpdateBucket(from: lastUpdateDate)
}
```

### Step 7: Update Pixel Definition

**File**: `macOS/PixelDefinitions/pixels/update_flow_pixels.json5`  
**Line**: ~149-153

Replace:
```json5
{
    "key": "feature.data.ext.time_since_last_update_ms",
    "type": "string",
    "description": "Time since last successful update in milliseconds"
},
```

With:
```json5
{
    "key": "feature.data.ext.time_since_last_update",
    "type": "string",
    "description": "Time since last successful update (bucketed for privacy)",
    "enum": ["<30m", "<2h", "<6h", "<1d", "<2d", "<1w", "<1M", ">=1M"]
},
```

### Step 8: Update Test

**File**: `macOS/UnitTests/Updates/SparkleUpdateWideEventTests.swift`  
**Line**: ~438

Replace the entire `test_updateFlow_updateFound_calculatesTimeSinceLastUpdate` method with:

```swift
func test_updateFlow_updateFound_calculatesTimeSinceLastUpdateBucket() {
    let lastUpdateDate = Date().addingTimeInterval(-TimeInterval.days(7))
    SparkleUpdateWideEvent.lastSuccessfulUpdateDate = lastUpdateDate
    sut.startFlow(initiationType: .automatic)
    
    sut.didFindUpdate(version: "1.0.0", build: "100", isCritical: false)
    
    let updatedData = mockWideEventManager.updates.first as? UpdateWideEventData
    XCTAssertNotNil(updatedData?.timeSinceLastUpdateBucket)
    XCTAssertEqual(updatedData?.timeSinceLastUpdateBucket, .lessThan1Month)
    
    let params = updatedData?.pixelParameters()
    XCTAssertEqual(params?["feature.data.ext.time_since_last_update"], "<1M")
    
    SparkleUpdateWideEvent.lastSuccessfulUpdateDate = nil
}
```

### Step 9: Add Bucket Tests

**File**: `macOS/UnitTests/Updates/UpdateWideEventDataTests.swift`

Add these three test methods at the end of the test class:

```swift
func test_timeSinceUpdateBucket_correctlyCategorizesAllTimeRanges() {
    let testCases: [(interval: TimeInterval, expectedBucket: String)] = [
        // <30m bucket
        (0, "<30m"),
        (.minutes(29), "<30m"),
        
        // <2h bucket
        (.minutes(30), "<2h"),
        (.minutes(119), "<2h"),
        
        // <6h bucket
        (.hours(2), "<6h"),
        (.hours(5), "<6h"),
        
        // <1d bucket
        (.hours(6), "<1d"),
        (.hours(23), "<1d"),
        
        // <2d bucket
        (.hours(24), "<2d"),
        (.hours(47), "<2d"),
        
        // <1w bucket
        (.days(2), "<1w"),
        (.days(6), "<1w"),
        
        // <1M bucket
        (.days(7), "<1M"),
        (.days(29), "<1M"),
        
        // >=1M bucket
        (.days(30), ">=1M"),
        (.days(365), ">=1M")
    ]
    
    for (interval, expectedBucket) in testCases {
        let bucket = UpdateWideEventData.TimeSinceUpdateBucket(interval: interval)
        XCTAssertEqual(bucket.rawValue, expectedBucket,
                      "Expected \(interval)s to be in bucket '\(expectedBucket)' but got '\(bucket.rawValue)'")
    }
}

func test_timeSinceUpdateBucket_convenienceInitializerWithDates() {
    // Test the convenience initializer that takes dates
    let now = Date()
    let sevenDaysAgo = now.addingTimeInterval(-TimeInterval.days(7))
    
    let bucket = UpdateWideEventData.TimeSinceUpdateBucket(from: sevenDaysAgo, to: now)
    XCTAssertEqual(bucket, .lessThan1Month)
    XCTAssertEqual(bucket.rawValue, "<1M")
    
    // Test with default parameter (current date)
    let thirtyDaysAgo = Date().addingTimeInterval(-TimeInterval.days(30))
    let bucketWithDefault = UpdateWideEventData.TimeSinceUpdateBucket(from: thirtyDaysAgo)
    XCTAssertEqual(bucketWithDefault, .greaterThanOrEqual1Month)
    XCTAssertEqual(bucketWithDefault.rawValue, ">=1M")
}

func test_timeSinceUpdateBucket_properlyEncodesInPixelParameters() {
    let contextData = WideEventContextData(name: "test", id: UUID().uuidString)
    let data = UpdateWideEventData(
        fromVersion: "1.0.0",
        fromBuild: "100",
        initiationType: .automatic,
        updateConfiguration: .automatic,
        isInternalUser: false,
        timeSinceLastUpdateBucket: .lessThan1Week,
        contextData: contextData
    )
    
    let params = data.pixelParameters()
    XCTAssertEqual(params["feature.data.ext.time_since_last_update"], "<1w")
}
```

## Summary

This change makes all modifications together:
- Adds bucketing enum with TimeInterval-based initializer and convenience date initializer
- Renames property from `timeSinceLastUpdateMs` to `timeSinceLastUpdateBucket`
- Changes pixel key from `time_since_last_update_ms` to `time_since_last_update`
- Updates all usages and tests

After these changes, compile and run tests to verify everything works.

## To-dos

- [ ] Add TimeSinceUpdateBucket enum with interval and convenience date initializers
- [ ] Replace timeSinceLastUpdateMs property with timeSinceLastUpdateBucket
- [ ] Update pixelParameters() to use bucket rawValue with new key time_since_last_update
- [ ] Update didFindUpdate() to use convenience date initializer  
- [ ] Update pixel definition with new key time_since_last_update and enum values
- [ ] Update test to verify bucket assignment using new property
- [ ] Add three tests: interval initializer, date initializer, and parameter encoding

