//
//  DebugDependencies.swift
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
import BrowserServicesKit
import Configuration
import DDGSync
import Persistence
import SystemSettingsPiPTutorial
import DataBrokerProtection_iOS

/// Dependencies passed through to individual debug screens
/// Individual debug screens (like SyncDebugViewController, CookieDebugViewController, etc.)
/// receive these dependencies to perform their specific debug operations
public protocol DebugDependenciesProviding {
    
    associatedtype TabManagerType
    associatedtype TipKitDebugOptionsUIActionHandlingType
    associatedtype FireproofingType
    associatedtype DaxDialogsManagingType
    
    var syncService: DDGSyncing { get }
    var bookmarksDatabase: CoreDataDatabase { get }
    var internalUserDecider: InternalUserDecider { get }
    var tabManager: TabManagerType { get }
    var tipKitUIActionHandler: TipKitDebugOptionsUIActionHandlingType { get }
    var fireproofing: FireproofingType { get }
    var customConfigurationURLProvider: CustomConfigurationURLProviding { get }
    var keyValueStore: ThrowingKeyValueStoring { get }
    var systemSettingsPiPTutorialManager: SystemSettingsPiPTutorialManaging { get }
    var daxDialogManager: DaxDialogsManagingType { get }
    var databaseDelegate: DBPIOSInterface.DatabaseDelegate? { get }
    var debuggingDelegate: DBPIOSInterface.DebuggingDelegate? { get }
    var runPrequisitesDelegate: DBPIOSInterface.RunPrerequisitesDelegate? { get }
}
