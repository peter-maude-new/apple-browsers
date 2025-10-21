//
//  DebugInterface.swift
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
import SwiftUI
import UIKit

public typealias DebugScreensProvider = () -> [DebugScreen]

// MARK: - DebugScreen

public protocol TabManaging {
    var count: Int { get }
}

public protocol TipKitDebugActionsHandling {
    func resetTipKitTapped()
}

public protocol DaxDialogsManagingSeam {}


// MARK: - DebugViewModel

public protocol ActionMessagePresenting {
    func present(message: String)
}

public protocol InternalUserStateOverriding {
    func setInternalUser(_ isInternal: Bool)
}

public protocol InspectableWebViewsManaging {
    var isEnabled: Bool { get set }
    func notifyToggled()
}

public protocol RemoteMessagingRefreshing {
    func refresh()
}

public protocol ConfigurationFetching {
    func fetchPrivacyConfiguration(isDebug: Bool, forceRefresh: Bool, completion: @escaping (ConfigurationFetchResult) -> Void)
}

public enum ConfigurationFetchResult { case assetsUpdated(Bool), noData }

public struct DebugScreensDeps {
    public let actionMessagePresenter: ActionMessagePresenting
    public let internalUserOverrider: InternalUserStateOverriding
    public var inspectableWebViewsManager: InspectableWebViewsManaging
    public let remoteMessagingRefresher: RemoteMessagingRefreshing
    public let configurationFetcher: ConfigurationFetching

    public init(
        actionMessagePresenter: ActionMessagePresenting,
        internalUserOverrider: InternalUserStateOverriding,
        inspectableWebViewsManager: InspectableWebViewsManaging,
        remoteMessagingRefresher: RemoteMessagingRefreshing,
        configurationFetcher: ConfigurationFetching
    ) {
        self.actionMessagePresenter = actionMessagePresenter
        self.internalUserOverrider = internalUserOverrider
        self.inspectableWebViewsManager = inspectableWebViewsManager
        self.remoteMessagingRefresher = remoteMessagingRefresher
        self.configurationFetcher = configurationFetcher
    }
}
