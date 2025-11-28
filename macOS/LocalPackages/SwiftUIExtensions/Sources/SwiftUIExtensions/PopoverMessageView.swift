//
//  PopoverMessageView.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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

import AppKit
import Foundation
import SwiftUI

public enum PopoverStyle {
    case basic
    case featureDiscovery
}

public final class PopoverMessageViewModel: ObservableObject {
    @Published var title: String?
    @Published var message: String
    @Published var image: NSImage?
    @Published var buttonText: String?
    @Published public var buttonAction: (() -> Void)?
    @Published var maxWidth: CGFloat?
    var shouldShowCloseButton: Bool
    var shouldPresentMultiline: Bool
    var clickAction: (() -> Void)?
    var onClick: (() -> Void)?
    public var dismissAction: (() -> Void)?
    public var onDismiss: (() -> Void)?

    public init(title: String?,
                message: String,
                image: NSImage? = nil,
                buttonText: String? = nil,
                buttonAction: (() -> Void)? = nil,
                shouldShowCloseButton: Bool = false,
                shouldPresentMultiline: Bool = true,
                maxWidth: CGFloat? = nil,
                clickAction: (() -> Void)? = nil,
                dismissAction: (() -> Void)? = nil,
                onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.image = image
        self.buttonText = buttonText
        self.buttonAction = buttonAction
        self.shouldShowCloseButton = shouldShowCloseButton
        self.shouldPresentMultiline = shouldPresentMultiline
        self.maxWidth = maxWidth
        self.clickAction = clickAction
        self.dismissAction = dismissAction
        self.onDismiss = onDismiss
    }
}

public struct PopoverMessageView: View {
    @ObservedObject public var viewModel: PopoverMessageViewModel
    var popoverStyle: PopoverStyle

    public init(viewModel: PopoverMessageViewModel,
                popoverStyle: PopoverStyle = .basic) {
        self.viewModel = viewModel
        self.popoverStyle = popoverStyle
    }

    public var body: some View {
        contentView
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.clickAction?()
                viewModel.dismissAction?()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch popoverStyle {
        case .basic:
            if let title = viewModel.title {
                messageWithTitleBody(title)
            } else {
                messageBody
            }
        case .featureDiscovery:
            featureDiscovery
        }
    }

    @ViewBuilder
    private var messageBody: some View {
        HStack(alignment: .top) {
            if let image = viewModel.image {
                Image(nsImage: image)
                    .padding(.top, 3)
            }

            Text(viewModel.message)
                .font(.body)
                .fontWeight(.bold)
                .padding(.leading, 2)
                .frame(minHeight: 22)
                .lineLimit(nil)
                .if(viewModel.shouldPresentMultiline) { view in
                    view.frame(width: viewModel.maxWidth ?? 160, alignment: .leading)
                }

            if let text = viewModel.buttonText,
               let action = viewModel.buttonAction {
                Button(text, action: {
                    action()
                    viewModel.dismissAction?()
                })
                .padding(.top, 2)
                .padding(.leading, 4)
            }

            if viewModel.shouldShowCloseButton {
                Button(action: {
                    viewModel.dismissAction?()
                }) {
                    Image(.updateNotificationClose)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, viewModel.buttonText != nil ? 4 : 0)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func messageWithTitleBody(_ title: String) -> some View {
        HStack(spacing: 12) {
            if let image = viewModel.image {
                Image(nsImage: image)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.bold)
                    .frame(minHeight: 22)
                    .lineLimit(nil)
                Text(viewModel.message)
                    .font(.body)
                    .frame(minHeight: 22)
                    .lineLimit(nil)
            }
            .padding(.leading, 8)
            .if(viewModel.shouldPresentMultiline) { view in
                view.frame(width: viewModel.maxWidth ?? 300, alignment: .leading)
            }

            if let text = viewModel.buttonText,
               let action = viewModel.buttonAction {
                Button(text, action: {
                    action()
                    viewModel.dismissAction?()
                })
                .padding(.top, 2)
                .padding(.leading, 4)
            }

            if viewModel.shouldShowCloseButton {
                VStack(spacing: 0) {
                    Button(action: {
                        viewModel.dismissAction?()
                    }) {
                        Image(.updateNotificationClose)
                        .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, -4)
                    .padding(.trailing, -8)

                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var featureDiscovery: some View {
        HStack(spacing: 8) {
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: -4) {
                if let title = viewModel.title {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(minHeight: 22)
                        .lineLimit(nil)
                        .padding(.bottom, -1)
                }
                Text(viewModel.message)
                    .font(.body)
                    .frame(minHeight: 22)
                    .lineLimit(nil)
            }
            .if(viewModel.shouldPresentMultiline) { view in
                view.frame(width: viewModel.maxWidth ?? 300, alignment: .leading)
            }

            if let text = viewModel.buttonText,
               let action = viewModel.buttonAction {
                Button(text, action: {
                    action()
                    viewModel.dismissAction?()
                })
                .padding(.top, 2)
                .padding(.leading, 4)
            }

            if viewModel.shouldShowCloseButton {
                VStack(spacing: 0) {
                    Button(action: {
                        viewModel.dismissAction?()
                    }) {
                        Image(.updateNotificationClose)
                        .frame(width: 16, height: 16)
                    }
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                    .padding(.leading, -6)
                    .padding(.trailing, 2)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
    }
}
