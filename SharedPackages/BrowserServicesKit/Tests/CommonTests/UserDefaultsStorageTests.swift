//
//  UserDefaultsStorageTests.swift
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
@testable import Common

final class UserDefaultsStorageTests: XCTestCase {

    struct CustomCodable: Codable, Equatable {
        let name: String
        let count: Int
    }

    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "UserDefaultsStorageTests")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "UserDefaultsStorageTests")
        userDefaults = nil
        super.tearDown()
    }

    func testReturnsDefaultValueWhenNoValueIsStored() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "boolKey", defaultValue: true)
        var testBool: Bool

        XCTAssertEqual(testBool, true)
    }

    func testStoresAndRetrievesBool() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "boolKey", defaultValue: false)
        var testBool: Bool

        testBool = true
        XCTAssertEqual(testBool, true)
    }

    func testStoresAndRetrievesString() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "stringKey", defaultValue: "default")
        var testString: String

        testString = "stored"
        XCTAssertEqual(testString, "stored")
    }

    func testStoresAndRetrievesCustomCodableType() {
        let original = CustomCodable(name: "Duck", count: 42)

        @UserDefaultsStorage(userDefaults: userDefaults, key: "customKey", defaultValue: CustomCodable(name: "Default", count: 0))
        var custom: CustomCodable

        custom = original
        XCTAssertEqual(custom, original)
    }

//    func testReturnsDefaultAndTriggersAssertionForCorruptedData() {
//        let key = "corruptedKey"
//        userDefaults.set(Data([0x00, 0x01, 0x02]), forKey: key)
//
//        @UserDefaultsStorage(userDefaults: userDefaults, key: key, defaultValue: "fallback")
//        var value: String
//
//        // You won't *see* the assertion failure unless running with assertions enabled
//        XCTAssertEqual(value, "fallback")
//    }

    func testWorksWithCustomUserDefaultsInstance() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "customInstance", defaultValue: 10)
        var testInt: Int

        testInt = 99
        XCTAssertEqual(userDefaults.data(forKey: "customInstance")?.isEmpty, false)
        XCTAssertEqual(testInt, 99)
    }

    func testValuePersistsAcrossWrapperInstances() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "persist", defaultValue: 0)
        var first: Int

        first = 100

        @UserDefaultsStorage(userDefaults: userDefaults, key: "persist", defaultValue: 0)
        var second: Int

        XCTAssertEqual(second, 100)
    }

    func testRemovingUnderlyingKeyReturnsDefault() {
        @UserDefaultsStorage(userDefaults: userDefaults, key: "testKey", defaultValue: "abc")
        var testValue: String

        testValue = "123"
        XCTAssertEqual(testValue, "123")

        userDefaults.removeObject(forKey: "tempKey")

        XCTAssertEqual(testValue, "abc")
    }

    class TestClass {
        @UserDefaultsStorage(userDefaults: .standard,
                             key: "testCorrectUserDefaultOverride.testKey",
                             defaultValue: "defaultValue",
                             getter: { value in  },
                             setter: { newValue in }
        )
        var testVariable: String
    }

    func testCorrectUserDefaultOverride() {

        let key = "testCorrectUserDefaultOverride.testKey"
        TestingUserDefaultsOverrider.shared.setOverride(userDefaults: userDefaults, forKey: key)
        let testClass = TestClass()
        XCTAssertEqual(testClass.testVariable, "defaultValue")

        var storedValue = userDefaults.value(forKey: key) as? String
        XCTAssertEqual(storedValue, "defaultValue")

        testClass.testVariable = "newValue"

        storedValue = userDefaults.value(forKey: key) as? String
        XCTAssertEqual(storedValue, "newValue")
    }
}
