//
//  HomeMessageViewModelBuilder.swift
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
import Core
import RemoteMessaging

struct HomeMessageViewModelBuilder {

    private enum Images {
        static let announcement = "RemoteMessageAnnouncement"
        static let ddgAnnouncement = "RemoteMessageDDGAnnouncement"
        static let appUpdate = "RemoteMessageAppUpdate"
        static let criticalAppUpdate = "RemoteMessageCriticalAppUpdate"
        static let macComputer = "RemoteMessageMacComputer"
    }

    static func build(for remoteMessage: RemoteMessageModel,
                      with privacyProDataReporter: PrivacyProDataReporting?,
                      navigator: MessageNavigator,
                      onDidClose: @escaping (HomeMessageViewModel.ButtonAction?) async -> Void,
                      onDidAppear: @escaping () -> Void) -> HomeMessageViewModel? {

        guard let content = remoteMessage.content else { return nil }

        switch content {
        case .small(let titleText, let descriptionText):
            return HomeMessageViewModel(
                messageId: remoteMessage.id,
                image: nil,
                title: titleText,
                subtitle: makeSubtitle(text: descriptionText),
                buttons: [],
                shouldPresentModally: remoteMessage.surfaces.contains(.modal),
                sendPixels: remoteMessage.isMetricsEnabled,
                onDidClose: onDidClose,
                onDidAppear: onDidAppear,
                onAttachAdditionalParameters: { useCase, params in
                    privacyProDataReporter?.mergeRandomizedParameters(for: useCase, with: params) ?? params
                }
            )

        case .medium(let titleText, let descriptionText, let placeholder):
            return HomeMessageViewModel(
                messageId: remoteMessage.id,
                image: placeholder.rawValue,
                title: titleText,
                subtitle: makeSubtitle(text: descriptionText),
                buttons: [],
                shouldPresentModally: remoteMessage.surfaces.contains(.modal),
                sendPixels: remoteMessage.isMetricsEnabled,
                onDidClose: onDidClose,
                onDidAppear: onDidAppear,
                onAttachAdditionalParameters: { useCase, params in
                    privacyProDataReporter?.mergeRandomizedParameters(for: useCase, with: params) ?? params
                }
            )

        case .bigSingleAction(let titleText, let descriptionText, let placeholder, let primaryActionText, let primaryAction):
            let actionStyle = primaryAction.actionStyle()

            return HomeMessageViewModel(
                messageId: remoteMessage.id,
                image: placeholder.rawValue,
                title: titleText,
                subtitle: makeSubtitle(text: descriptionText),
                buttons: [
                    HomeMessageButtonViewModel(
                        title: primaryActionText,
                        actionStyle: actionStyle,
                        buttonStyle: buttonStyle(forModelType: content, actionStyle: actionStyle),
                        action: RemoteMessageActionHandler(messageNavigator: navigator).handle(
                            remoteAction: primaryAction,
                            buttonAction: .primaryAction(isShare: primaryAction.isShare),
                            onDidClose: onDidClose
                        )
                    )
                ],
                shouldPresentModally: remoteMessage.surfaces.contains(.modal),
                sendPixels: remoteMessage.isMetricsEnabled,
                onDidClose: onDidClose,
                onDidAppear: onDidAppear,
                onAttachAdditionalParameters: { useCase, params in
                    privacyProDataReporter?.mergeRandomizedParameters(for: useCase, with: params) ?? params
                }
            )
        case .bigTwoAction( let titleText, let descriptionText, let placeholder, let primaryActionText, let primaryAction, let secondaryActionText, let secondaryAction):
            let primaryActionStyle = primaryAction.actionStyle()
            let secondaryActionStyle = secondaryAction.actionStyle(isSecondaryAction: true)

            return HomeMessageViewModel(
                messageId: remoteMessage.id,
                image: placeholder.rawValue,
                title: titleText,
                subtitle: makeSubtitle(text: descriptionText),
                buttons: [
                    HomeMessageButtonViewModel(
                        title: secondaryActionText,
                        actionStyle: secondaryActionStyle,
                        buttonStyle: buttonStyle(forModelType: content, actionStyle: secondaryActionStyle),
                        action: RemoteMessageActionHandler(messageNavigator: navigator).handle(
                            remoteAction: secondaryAction,
                            buttonAction: .secondaryAction(isShare: secondaryAction.isShare),
                            onDidClose: onDidClose
                        )
                    ),

                    HomeMessageButtonViewModel(
                        title: primaryActionText,
                        actionStyle: primaryActionStyle,
                        buttonStyle: buttonStyle(forModelType: content, actionStyle: primaryActionStyle),
                        action: RemoteMessageActionHandler(messageNavigator: navigator).handle(
                            remoteAction: primaryAction,
                            buttonAction: .primaryAction(isShare: primaryAction.isShare),
                            onDidClose: onDidClose
                        )
                    )
                ],
                shouldPresentModally: remoteMessage.surfaces.contains(.modal),
                sendPixels: remoteMessage.isMetricsEnabled,
                onDidClose: onDidClose,
                onDidAppear: onDidAppear,
                onAttachAdditionalParameters: { useCase, params in
                    privacyProDataReporter?.mergeRandomizedParameters(for: useCase, with: params) ?? params
                }
            )
        case .promoSingleAction(let titleText, let descriptionText, let placeholder, let actionText, let action):
            let actionStyle = action.actionStyle()

            return HomeMessageViewModel(
                messageId: remoteMessage.id,
                layout: .titleImage,
                image: placeholder.rawValue,
                title: titleText,
                subtitle: makeSubtitle(text: descriptionText),
                buttons: [
                    HomeMessageButtonViewModel(
                        title: actionText,
                        actionStyle: actionStyle,
                        buttonStyle: buttonStyle(forModelType: content, actionStyle: actionStyle),
                        action: RemoteMessageActionHandler(messageNavigator: navigator).handle(
                            remoteAction: action,
                            buttonAction: .action(isShare: action.isShare),
                            onDidClose: onDidClose
                        )
                    )
                ],
                shouldPresentModally: remoteMessage.surfaces.contains(.modal),
                sendPixels: remoteMessage.isMetricsEnabled,
                onDidClose: onDidClose,
                onDidAppear: onDidAppear,
                onAttachAdditionalParameters: { useCase, params in
                    privacyProDataReporter?.mergeRandomizedParameters(for: useCase, with: params) ?? params
                }
            )
        case .promoList:
            return nil
        }
    }

}

extension HomeMessageViewModelBuilder {

    static func makeSubtitle(text: String) -> String {
        text
            .replacingOccurrences(of: "<b>", with: "**")
            .replacingOccurrences(of: "</b>", with: "**")
    }

    static func buttonStyle(forModelType modelType: RemoteMessageModelType, actionStyle: HomeMessageButtonViewModel.ActionStyle) -> HomeMessageButtonViewModel.ButtonStyle {
        if case .promoSingleAction = modelType {
            return .cancel
        }

        if case .cancel = actionStyle {
            return .cancel
        }

        return .primary
    }

}

extension RemoteAction {

    func actionStyle(isSecondaryAction: Bool = false) -> HomeMessageButtonViewModel.ActionStyle {
        switch self {
        case .share(let value, let title):
            return .share(value: value, title: title)

        case .appStore, .url, .survey, .navigation:
            if isSecondaryAction {
                return .cancel
            }
            return .default

        case .dismiss:
            return .cancel
        }
    }

}

private extension RemoteAction {
    var isShare: Bool {
        if case .share = self.actionStyle() {
            return true
        }
        return false
    }
}

protocol RemoteActionHandler {
     func handle(
        remoteAction: RemoteAction,
        buttonAction: HomeMessageViewModel.ButtonAction,
        onDidClose: @escaping (HomeMessageViewModel.ButtonAction?) async -> Void
     ) -> () async -> Void
 }

struct RemoteMessageActionHandler: RemoteActionHandler {
    private let messageNavigator: MessageNavigator

    init(messageNavigator: MessageNavigator) {
        self.messageNavigator = messageNavigator
    }

    func handle(
       remoteAction: RemoteAction,
       buttonAction: HomeMessageViewModel.ButtonAction,
       onDidClose: @escaping (HomeMessageViewModel.ButtonAction?) async -> Void
    ) -> () async -> Void {
        switch remoteAction {
        case .share:
            return { @MainActor in
                await onDidClose(buttonAction)
            }
        case .url(let value):
            return { @MainActor in
                LaunchTabNotification.postLaunchTabNotification(urlString: value)
                await onDidClose(buttonAction)
            }
        case .survey(let value):
            return { @MainActor in
                let refreshedURL = refreshLastSearchState(in: value)
                LaunchTabNotification.postLaunchTabNotification(urlString: refreshedURL)
                await onDidClose(buttonAction)
            }
        case .appStore:
            return { @MainActor in
                let url = URL.appStore
                if UIApplication.shared.canOpenURL(url as URL) {
                    UIApplication.shared.open(url)
                }
                await onDidClose(buttonAction)
            }
        case .dismiss:
            return { @MainActor in
                await onDidClose(buttonAction)
            }

        case .navigation(let target):
            return { @MainActor in
                messageNavigator.navigateTo(target)
                await onDidClose(buttonAction)
            }
        }
    }

    /// If `last_search_state` is present, refresh before opening URL
    private func refreshLastSearchState(in urlString: String) -> String {
        let lastSearchDate = AutofillUsageStore().searchDauDate
        return DefaultRemoteMessagingSurveyURLBuilder.refreshLastSearchState(in: urlString, lastSearchDate: lastSearchDate)
    }
}
