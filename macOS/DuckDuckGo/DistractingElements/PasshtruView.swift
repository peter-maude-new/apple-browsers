//
//  PasshtruView.swift
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

protocol PasshtruViewDelegate: AnyObject {
    func onMouseMoved(source: PasshtruView, locationInWindow: NSPoint)
}

final class PasshtruView: NSView {

    private var tracking: NSTrackingArea?
    weak var delegate: PasshtruViewDelegate?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }

        let targetTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInActiveApp, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(targetTrackingArea)
        tracking = targetTrackingArea
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let collision = super.hitTest(point) else {
            return nil
        }

        return collision != self ? collision : nil
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        delegate?.onMouseMoved(source: self, locationInWindow: event.locationInWindow)
    }
}
