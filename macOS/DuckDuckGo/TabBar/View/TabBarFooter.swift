//
//  TabBarFooter.swift
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
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

import Cocoa
import Combine

final class TabBarFooter: NSView, NSCollectionViewElement {

    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TabBarFooter")

    private var styleCancellable: AnyCancellable?
    private let styleManager = NSApp.delegateTyped.visualStyleManager

    let addButton = MouseOverButton(image: .add, target: nil, action: #selector(TabBarViewController.addButtonAction))

    var target: MouseOverButtonDelegate? {
        get {
            addButton.delegate
        }
        set {
            addButton.target = newValue
            addButton.delegate = newValue
        }
    }

    var isEnabled: Bool {
        get {
            addButton.isEnabled
        }
        set {
            addButton.isEnabled = newValue
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)

        identifier = Self.identifier
        translatesAutoresizingMaskIntoConstraints = false

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.isBordered = false
        addButton.bezelStyle = .shadowlessSquare
        addButton.imagePosition = .imageOnly
        addButton.imageScaling = .scaleNone
        addButton.registerForDraggedTypes([.string])
        addButton.toolTip = UserText.newTabTooltip
        addButton.setAccessibilityIdentifier("NewTabButton")
        addButton.setAccessibilityTitle(UserText.newTabTooltip)

        toolTip = UserText.newTabTooltip

        addSubview(addButton)

        subscribeToStyleChanges()
     }

    required init?(coder: NSCoder) {
        fatalError("TabBarFooter: Bad initializer")
    }

    override func layout() {
        super.layout()

        let buttonSize = styleManager.style.tabBarButtonSize

        addButton.frame = NSRect(x: ((bounds.width - buttonSize) * 0.5).rounded(), y: ((bounds.height - buttonSize) * 0.5).rounded(), width: buttonSize, height: buttonSize)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        addButton.cell?.setAccessibilityParent(addButton.superview?.superview) // make the AddButton a direct child of the TabBarCollectionView
    }

    private func subscribeToStyleChanges() {
        styleCancellable = styleManager.$style
            .receive(on: DispatchQueue.main)
            .sink { [weak self] style in
                self?.applyStyle(style: style)
            }
    }

    private func applyStyle(style: VisualStyleProviding) {
        let colorProvider = style.colorsProvider

        addButton.normalTintColor = colorProvider.iconsColor
        addButton.mouseDownColor = colorProvider.buttonMouseDownColor
        addButton.mouseOverColor = colorProvider.buttonMouseOverColor
        addButton.cornerRadius = style.toolbarButtonsCornerRadius
    }
}

#if DEBUG
extension TabBarFooter {
    final class PreviewViewController: NSViewController {
        override func loadView() {
            view = NSView()
            view.addSubview(TabBarFooter(frame: NSRect(x: 4, y: 2, width: 32, height: 32)))
        }
    }
}
@available(macOS 14.0, *)
#Preview(traits: .fixedLayout(width: 40, height: 40)) {
    TabBarFooter.PreviewViewController()
        ._preview_hidingWindowControlsOnAppear()
}
#endif
