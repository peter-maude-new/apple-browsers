//
//  BrowsingMenuSheetView.swift
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

import SwiftUI
import UIKit
import DesignResourcesKit
import DesignResourcesKitIcons

typealias BrowsingMenuSheetViewController = UIHostingController<BrowsingMenuSheetView>

struct BrowsingMenuModel {
    var headerItems: [BrowsingMenuModel.Entry]
    var sections: [BrowsingMenuModel.Section]
    var footerItems: [BrowsingMenuModel.Entry]
}

struct BrowsingMenuSheetView: View {

    @Environment(\.presentationMode) var presentationMode

    private let model: BrowsingMenuModel
    private let onDismiss: () -> Void

    @State private var actionToPerform: () -> Void

    init(model: BrowsingMenuModel, onDismiss: @escaping () -> Void) {
        self.model = model
        self.onDismiss = onDismiss
        self.actionToPerform = { }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    if !model.headerItems.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(model.headerItems) { headerItem in
                                MenuHeaderButton(entryData: headerItem) {
                                    actionToPerform = { headerItem.action() }
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .background((Color(designSystemColor: .background)))
                    }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))

                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            MenuRowButton(entryData: item) {
                                actionToPerform = { item.action() }
                                presentationMode.wrappedValue.dismiss()
                            }
//                            .background(Color(designSystemColor: .surface))
                        }
                    }
                }
//                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .compactSectionSpacingIfAvailable()
            .applyInsetGroupedListStyle()
            .onDisappear(perform: {
                actionToPerform()
                onDismiss()
            })
        }
        .tint(Color(designSystemColor: .textPrimary))
        .background((Color(designSystemColor: .background)))
    }
}

extension BrowsingMenuModel {
    struct Section: Identifiable {
        let id = UUID()
        let items: [BrowsingMenuModel.Entry]
    }

    struct Entry: Identifiable, Equatable {
        let id: UUID = UUID()
        let name: String
        let accessibilityLabel: String?
        let image: UIImage
        let showNotificationDot: Bool
        let customDotColor: UIColor?
        let action: () -> Void
        let tag: Tag?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: BrowsingMenuModel.Entry, rhs: BrowsingMenuModel.Entry) -> Bool {
            lhs.id == rhs.id
        }

        enum Tag {
            case favorite
        }
    }
}

extension BrowsingMenuModel.Entry {
    init(_ browsingMenuEntry: BrowsingMenuEntry, tag: Tag? = nil) {
        switch browsingMenuEntry {
        case .separator:
            assertionFailure(#function + " should not be called for .separator")

            self.init(name: "", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {}, tag: tag)

        case .regular(let name, let accessibilityLabel, let image, let showNotificationDot, let customDotColor, let action):
            self.init(
                name: name,
                accessibilityLabel: accessibilityLabel,
                image: image,
                showNotificationDot: showNotificationDot,
                customDotColor: customDotColor,
                action: action,
                tag: tag
            )
        }
    }
}

private struct MenuRowButton: View {

    fileprivate let entryData: BrowsingMenuModel.Entry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(uiImage: entryData.image)
                Text(entryData.name)

                if entryData.showNotificationDot {
                    Circle().fill(entryData.customDotColor.map({ Color($0) }) ?? Color(designSystemColor: .accent))
                        .frame(width: 8, height: 8)
                        .padding(.leading, 6)
                        .padding(.trailing, 12)

                    Spacer()
                }
            }
        }
        .accessibilityLabel(entryData.accessibilityLabel ?? entryData.name)
    }
}

private struct MenuHeaderButton: View {

    fileprivate let entryData: BrowsingMenuModel.Entry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(uiImage: entryData.image)
                    .tint(Color(designSystemColor: .icons))
                Text(entryData.name)
                    .daxFootnoteRegular()
                    .foregroundStyle(Color(designSystemColor: .textSecondary))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(Color(designSystemColor: .surface))
            .clipShape(RoundedRectangle(cornerRadius: Constant.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: Constant.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entryData.accessibilityLabel ?? entryData.name)
    }

    private enum Constant {
        static let cornerRadius: CGFloat = 4
    }

}

struct FloatingToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, content: {
                createBottomToolbar()
            })
    }

    @ViewBuilder
    private func createBottomToolbar() -> some View {
        HStack(spacing: 4) {
            Image(uiImage: DesignSystemImages.Glyphs.Size24.settings)
                .padding(8)

            Image(uiImage: DesignSystemImages.Glyphs.Size24.add)
                .padding(8)

            Image(uiImage: DesignSystemImages.Glyphs.Size24.aiChat)
                .padding(8)
        }
        .background(Color(designSystemColor: .surfaceCanvas))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(designSystemColor: .shadowSecondary), radius: 4, x: 0, y: 4)
        .shadow(color: Color(designSystemColor: .shadowSecondary), radius: 2, x: 0, y: 1)
        .fixedSize(horizontal: true, vertical: true)
    }
}
