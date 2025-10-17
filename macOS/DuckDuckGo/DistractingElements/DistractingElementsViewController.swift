//
//  DistractingElementsViewController.swift
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
import AppKit

final class DistractingElementsViewController: NSViewController {

    private var highlightView: DistractingHighlightView!
    private var activeElement: DistractingElementDescriptor?

    weak var distractingElementsTabExtension: DistractingElementsExtensionProtocol? {
        didSet {
            distractingElementsTabExtension?.delegate = self
        }
    }

    override func loadView() {
        let targetView = PasshtruView()
        targetView.delegate = self

        let highlightView = DistractingHighlightView()
        highlightView.wantsLayer = true
        highlightView.layer?.zPosition = 9999
        highlightView.onClick = { [weak self] in
            self?.removeActiveElement()
        }

        targetView.addSubview(highlightView)

        self.view = targetView
        self.highlightView = highlightView
    }

    func attach(to parentViewController: NSViewController) {
        let parentView = parentViewController.view
        parentViewController.addChild(self)
        parentView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: parentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
        ])
    }
}

private extension DistractingElementsViewController {

    func removeActiveElement() {
        guard let activeElement else {
            return
        }

        distractingElementsTabExtension?.deleteElement(xpath: activeElement.xpath)
    }
}

extension DistractingElementsViewController: PasshtruViewDelegate {

    func onMouseMoved(source: PasshtruView, locationInWindow: NSPoint) {
        distractingElementsTabExtension?.processMouseMoved(at: locationInWindow)
    }
}

extension NSPoint {

    var rounded: NSPoint {
        NSPoint(x: x.rounded(), y: y.rounded())
    }
}

extension DistractingElementsViewController: DistractingElementsTabExtensionDelegate {

    func displayHighlight(for descriptor: DistractingElementDescriptor) {
        activeElement = descriptor
        highlightView.display(in: descriptor.frame)
    }

    func dismissHighlight() {
        activeElement = nil
        highlightView.isHidden = true
    }
}
