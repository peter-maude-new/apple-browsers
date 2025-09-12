//
//  HomeMessageViewModel.swift
//  DuckDuckGo
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import RemoteMessaging
import UIKit

struct HomeMessageViewModel: Identifiable {
    var id: String {
        messageId
    }

    enum ButtonAction {
        case close
        case action(isShare: Bool) // a generic action that is specific to the type of message
        case primaryAction(isShare: Bool)
        case secondaryAction(isShare: Bool)
    }

    enum Layout {
        case titleImage
        case imageTitle
    }

    let messageId: String
    var layout: Layout = .imageTitle
    let image: String?
    let title: String
    let subtitle: String
    let buttons: [HomeMessageButtonViewModel]
    let shouldPresentModally: Bool
    let sendPixels: Bool
    let onDidClose: (ButtonAction?) async -> Void
    let onDidAppear: () -> Void
    let onAttachAdditionalParameters: ((_ useCase: PrivacyProDataReportingUseCase, _ params: [String: String]) -> [String: String])?

}

struct HomeMessageButtonViewModel {
    enum ActionStyle {
        case `default`
        case share(value: String, title: String?)
        case cancel
    }

    enum ButtonStyle {
        case primary
        case cancel
    }

    let title: String
    var actionStyle: ActionStyle = .default
    let buttonStyle: ButtonStyle
    let action: () async -> Void

}
