//
//  ModalPromptDispatcher.swift
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

import DesignResourcesKitIcons
import DuckUI
import SwiftUI
import UIKit
import Combine
import RemoteMessaging

final class ModalPromptDispatcherService {
    private let remoteMessageStore: RemoteMessagingStoring
    private let notificationCenter: NotificationCenter

    private var cancellable: AnyCancellable?

    init(remoteMessageStore: RemoteMessagingStoring, notificationCenter: NotificationCenter = .default) {
        self.remoteMessageStore = remoteMessageStore
        self.notificationCenter = notificationCenter
    }

    func presentModalPromptIfNeeded(from viewController: UIViewController) {
        guard
            let modalRemoteMessageToPresent = remoteMessageStore.fetchScheduledRemoteMessage(surfaces: .modal),
            let contentType = modalRemoteMessageToPresent.content,
            case .promoList(let mainTitleText, let items, let primaryActionText, let primaryAction) = contentType
        else {
            return
        }
        Logger.remoteMessaging.info("Remote message to show: \(modalRemoteMessageToPresent.id)")

        // Present the full screen from the root controller or from the presented screen if any. (E.g. settings)
        let presentingViewController = viewController.presentedViewController ?? viewController

        let remoteMessageActionHandler = DefaultRemoteMessageActionHandler(messageNavigator: nil)

        let promoItems = items.map { remoteListItem in
            PromoListDisplayModel.Item(
                icon: Image(.VPN),
                title: remoteListItem.titleText,
                subtitle: remoteListItem.descriptionText,
                disclosureIcon: Image(uiImage: DesignSystemImages.Glyphs.Size24.chevronRightSmall),
                onTap: { [weak presentingViewController] in
                    Task {
                        guard
                            let remoteAction = remoteListItem.action,
                            let presenter = await presentingViewController?.presentedViewController
                        else {
                            return
                        }
                        await remoteMessageActionHandler.executeAction(remoteAction, presenter: presenter)
                    }
                }
            )
        }

        let dismiss: () -> Void = { [weak self, weak presentingViewController] in
            // self?.remoteMessageStore.dismissRemoteMessage(withID: modalRemoteMessageToPresent.id)
            presentingViewController?.dismiss(animated: true)
        }

        let displayAction: (title: String, action: () -> Void)? = primaryAction.flatMap { action in
            guard case .dismiss = action, let primaryActionText else { return nil }
            return (primaryActionText, dismiss)
        }

        let displayModel = PromoListDisplayModel(
            screenTitle: mainTitleText,
            items: promoItems,
            primaryAction: displayAction
        )

        let promoListView = PromoListView(displayModel: displayModel)
        let hostingController = WhatsNewHostingController(rootView: promoListView)
        hostingController.onDismiss = dismiss
        let navigationController = UINavigationController(rootViewController: hostingController)
        presentingViewController.present(navigationController, animated: true)
    }

}

extension UIViewController: RemoteMessageActionPresenter {

    func presentInContext(url: URL) {
        self.show(WebSupportViewController(url: url), sender: nil)
    }

}

private extension ModalPromptDispatcherService {

}

final class WhatsNewHostingController<Content: View>: UIHostingController<Content> {

    var onDismiss: () -> Void = {}

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeButton = UIBarButtonItem(image: DesignSystemImages.Glyphs.Size24.close, style: .plain, target: self, action: #selector(dismissModal))
        closeButton.tintColor = UIColor(designSystemColor: .textPrimary)
        navigationItem.rightBarButtonItem = closeButton
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .portrait
        case .pad:
            return .all
        default:
            return .all
        }
    }

    @objc
    private func dismissModal() {
        onDismiss()
    }
}

// MARK: -

struct PromoListDisplayModel {
    let screenTitle: String
    let items: [PromoListDisplayModel.Item]
    let primaryAction: (title: String, action: () -> Void)?
}

extension PromoListDisplayModel {

    struct Item {
        let icon: Image
        let title: String
        let subtitle: String
        let disclosureIcon: Image
        let onTap: () -> Void
    }

}

struct PromoListItemDisplayModel {
    let icon: Image
    let title: String
    let subtitle: String
    let disclosureIcon: Image
}

struct PromoListView: View {
    let displayModel: PromoListDisplayModel

    var body: some View {
        VStack(spacing: 20) {
            Text(displayModel.screenTitle)
                .font(.system(size: 28, weight: .bold))
                .kerning(0.38)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(displayModel.items.indices, id: \.self) { index in
                        let item = displayModel.items[index]
                        WhatsNewSectionView(
                            icon: item.icon,
                            title: item.title,
                            subtitle: item.subtitle,
                            disclosureIcon: Image(uiImage: DesignSystemImages.Glyphs.Size24.chevronRightSmall),
                            background: AnyView(WhatsNewGradient())
                        )
                        .onTapGesture {
                            item.onTap()
                        }
                    }
                }
            }

            Spacer()

            if let primaryAction = displayModel.primaryAction {
                Button(action: primaryAction.action) {
                    Text(verbatim: primaryAction.title)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }
}

struct WhatsNewSectionView: View {
    let icon: Image
    let title: String
    let subtitle: String
    let disclosureIcon: Image
    let background: AnyView

    var body: some View {
        HStack(alignment: .top, spacing: 12.0) {
            VStack(alignment: .leading) {
                icon
                    .resizable()
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading) {
                Text(verbatim: title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text(verbatim: subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                disclosureIcon
            }
        }
        .padding([.leading, .top], 12)
        .padding([.trailing, .bottom], 16)
        .frame(maxWidth: .infinity, minHeight: 110.0)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 0.5))
        .border(Color.black.opacity(0.05))
        .cornerRadius(12.0)
    }
}

struct WhatsNewHeaderView: View {
    let icon: Image
    let title: String
    let subtitle: String
    let actionButtonTitle: String

    let action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            icon
                .resizable()
                .frame(width: 128, height: 96)

            Text(verbatim: title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            Text(verbatim: subtitle)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)

            Button(action: action) {
                Text(actionButtonTitle)
                    .font(.system(size: 13))
                    .underline(true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(designSystemColor: .accent))
            }
            .frame(height: 44)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 42)
        .frame(maxWidth: .infinity, minHeight: 110.0)
        .background(WhatsNewGradient())
        .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 0.5))
        .border(Color.black.opacity(0.05))
        .cornerRadius(12.0)
    }
}

struct WhatsNewGradient: View {

    var body: some View {
        AngularGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.8, green: 0.85, blue: 1), location: 0.00),
                Gradient.Stop(color: Color(red: 0.96, green: 0.96, blue: 0.96), location: 0.59),
                Gradient.Stop(color: Color(red: 0.88, green: 0.82, blue: 0.93), location: 1.00),
            ],
            center: UnitPoint(x: 0.5, y: 0.5),
            angle: Angle(degrees: 80.67)
        )
        .blur(radius: 58)
    }

}

import WebKit

final class WebSupportViewController: UIViewController {
    private let webView: WKWebView

    init(url: URL) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.load(URLRequest(url: url))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        let closeButton = UIBarButtonItem(title: UserText.MoreProtections.dismissCTA, style: .plain, target: self, action: #selector(dismissModal))
//        closeButton.tintColor = UIColor(designSystemColor: .textPrimary)
//        navigationItem.leftBarButtonItem = closeButton

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc
    private func dismissModal() {
        presentingViewController?.dismiss(animated: true)
    }

}
