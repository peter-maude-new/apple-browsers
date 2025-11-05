//
//  MouseBlockingView.swift
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

import Cocoa

/// A view that blocks all mouse events from passing through to views behind it,
/// while still allowing its subviews to receive mouse events normally.
class MouseBlockingView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMouseBlocking()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMouseBlocking()
    }
    
    private func setupMouseBlocking() {
        wantsLayer = true
        // Ensure we're above other views in terms of event handling
        layer?.zPosition = 100
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // CRITICAL: Check bounds FIRST
        guard bounds.contains(point) else {
            #if DEBUG
            // Point is outside our bounds
            #endif
            return nil
        }
        
        // Now check if any interactive subview should handle the event
        let hitView = super.hitTest(point)
        
        // If a subview other than self wants the event, let it have it
        if let hitView = hitView, hitView != self {
            #if DEBUG
            print("MouseBlockingView: Passing event to subview: \(type(of: hitView))")
            #endif
            return hitView
        }
        
        // Otherwise, we capture it to prevent passthrough
        #if DEBUG
        print("MouseBlockingView: BLOCKING event at point \(point) in bounds \(bounds)")
        #endif
        return self
    }
    
    // Block all mouse events from passing through to views behind
    override func mouseDown(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingView: mouseDown BLOCKED - event consumed")
        #endif
        // Consume the event - don't call super
    }
    
    override func mouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func rightMouseDown(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func rightMouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func otherMouseDown(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func otherMouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Consume the event - don't call super
    }
    
    override func mouseExited(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func updateTrackingAreas() {
           super.updateTrackingAreas()
           trackingAreas.forEach { removeTrackingArea($0) }

           let trackingArea = NSTrackingArea(
               rect: bounds,
               options: [.mouseEnteredAndExited, .activeAlways],
               owner: self,
               userInfo: nil
           )
           addTrackingArea(trackingArea)
       }
}

