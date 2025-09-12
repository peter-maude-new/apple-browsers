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

        let actionHandler = DefaultRemoteMessageActionHandler(messageNavigator: navigator)
        let homeMessageActionHandler = HomeMessageRemoteActionHandlerAdapter(actionHandler: actionHandler)

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
                        action: homeMessageActionHandler.handle(
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
                        action: homeMessageActionHandler.handle(
                            remoteAction: secondaryAction,
                            buttonAction: .secondaryAction(isShare: secondaryAction.isShare),
                            onDidClose: onDidClose
                        )
                    ),

                    HomeMessageButtonViewModel(
                        title: primaryActionText,
                        actionStyle: primaryActionStyle,
                        buttonStyle: buttonStyle(forModelType: content, actionStyle: primaryActionStyle),
                        action: homeMessageActionHandler.handle(
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
                        action: homeMessageActionHandler.handle(
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

        case .appStore, .url, .urlInContext, .survey, .navigation:
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

protocol RemoteMessageActionPresenter {
    func presentInContext(url: URL)
}

protocol RemoteMessageActionHandler {
    func executeAction(_ remoteAction: RemoteAction, presenter: RemoteMessageActionPresenter?) async
}

extension RemoteMessageActionHandler {
    func executeAction(_ remoteAction: RemoteAction) async {
        await executeAction(remoteAction, presenter: nil)
    }
}

final class DefaultRemoteMessageActionHandler: RemoteMessageActionHandler {
    private let messageNavigator: MessageNavigator?

    init(messageNavigator: MessageNavigator?) {
        self.messageNavigator = messageNavigator
    }

    @MainActor
    func executeAction(_ remoteAction: RemoteAction, presenter: RemoteMessageActionPresenter?) async {
        switch remoteAction {
        case .share, .dismiss:
            break

        case .url(let value):
            LaunchTabNotification.postLaunchTabNotification(urlString: value)

        case .urlInContext(let value):
            guard let url = URL(string: value) else {
                assertionFailure("Not a URL")
                return
            }
            presenter?.presentInContext(url: url)
        case .survey(let value):
            let refreshedURL = refreshLastSearchState(in: value)
            LaunchTabNotification.postLaunchTabNotification(urlString: refreshedURL)

        case .appStore:
            let url = URL.appStore
            if UIApplication.shared.canOpenURL(url as URL) {
                UIApplication.shared.open(url)
            }
        case .navigation(let target):
            messageNavigator?.navigateTo(target)
        }
    }

    private func refreshLastSearchState(in urlString: String) -> String {
        let lastSearchDate = AutofillUsageStore().searchDauDate
        return DefaultRemoteMessagingSurveyURLBuilder.refreshLastSearchState(in: urlString, lastSearchDate: lastSearchDate)
    }
}

struct HomeMessageRemoteActionHandlerAdapter {
    private let actionHandler: RemoteMessageActionHandler

    init(actionHandler: RemoteMessageActionHandler) {
        self.actionHandler = actionHandler
    }

    func handle(
        remoteAction: RemoteAction,
        buttonAction: HomeMessageViewModel.ButtonAction,
        onDidClose: @escaping (HomeMessageViewModel.ButtonAction?) async -> Void
    ) -> () async -> Void {
        return { @MainActor in
            await self.actionHandler.executeAction(remoteAction)
            await onDidClose(buttonAction)
        }
    }
}
