//
//  MouseBlockingBackgroundView.swift
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

/// A view that aggressively blocks ALL mouse events from reaching views behind it.
/// Uses a local event monitor to intercept events and manually forwards them to subviews.
/// This prevents events from ever reaching views behind this one (like a webview).
final class MouseBlockingBackgroundView: NSView {
    
    private var localMonitor: Any?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        stopListening()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // Start listening when added to window, stop when removed
        if window != nil {
            startListening()
        } else {
            stopListening()
        }
    }
    
    /// Starts listening to mouse events. Call this when the view becomes visible.
    func startListening() {
        // Only set up if we don't already have a monitor
        guard localMonitor == nil else { return }
        setupEventBlocking()
        #if DEBUG
        print("MouseBlockingBackgroundView: Started listening to events")
        #endif
    }
    
    /// Stops listening to mouse events. Call this when the view is no longer visible.
    func stopListening() {
        guard let monitor = localMonitor else { return }
        NSEvent.removeMonitor(monitor)
        localMonitor = nil
        #if DEBUG
        print("MouseBlockingBackgroundView: Stopped listening to events")
        #endif
    }
    
    private func setupEventBlocking() {
        // Use a LOCAL monitor to intercept ALL events and manually dispatch to our subviews
        // This prevents events from reaching the webview behind us
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp, .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel]) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }
            
            // Only block if we're visible
            guard !self.isHidden else { return event }
            
            // Only block if event is in our window and the window is key or main
            // This allows normal window activation to happen when switching between windows
            guard let window = self.window, event.window === window, (window.isKeyWindow || window.isMainWindow) else { return event }
            
            // Convert event location to our coordinate system
            let locationInWindow = event.locationInWindow
            let locationInView = self.convert(locationInWindow, from: nil)
            
            // Check if event is within our bounds
            guard self.bounds.contains(locationInView) else { return event }
            
            // Check if there's a view on top of us - if so, let the event through
            if let contentView = window.contentView {
                let locationInContentView = contentView.convert(locationInWindow, from: nil)
                if let topHitView = contentView.hitTest(locationInContentView) {
                    // If the top hit view is not self or a descendant of self, there's a view on top
                    if topHitView != self && !topHitView.isDescendant(of: self) {
                        #if DEBUG
                        print("MouseBlockingBackgroundView: View on top detected, passing event through")
                        #endif
                        return event
                    }
                }
            }
            
            // Event is in our bounds - check if it should go to a subview
            if let hitView = self.hitTest(locationInView), hitView != self {
                // Manually send the event to the hit view
                #if DEBUG
                print("MouseBlockingBackgroundView: Forwarding event to \(hitView)")
                #endif
                
                // Send the event directly to the target view
                switch event.type {
                case .leftMouseDown:
                    // Make the hit view become first responder if it can accept it
                    if hitView.acceptsFirstResponder {
                        window.makeFirstResponder(hitView)
                    }
                    hitView.mouseDown(with: event)
                case .leftMouseUp:
                    hitView.mouseUp(with: event)
                case .rightMouseDown:
                    hitView.rightMouseDown(with: event)
                case .rightMouseUp:
                    hitView.rightMouseUp(with: event)
                case .otherMouseDown:
                    hitView.otherMouseDown(with: event)
                case .otherMouseUp:
                    hitView.otherMouseUp(with: event)
                case .mouseMoved:
                    hitView.mouseMoved(with: event)
                case .leftMouseDragged:
                    hitView.mouseDragged(with: event)
                case .rightMouseDragged:
                    hitView.rightMouseDragged(with: event)
                case .otherMouseDragged:
                    hitView.otherMouseDragged(with: event)
                case .scrollWheel:
                    hitView.scrollWheel(with: event)
                default:
                    break
                }
            }
            
            // ALWAYS block the event from continuing to the webview
            #if DEBUG
            print("MouseBlockingBackgroundView: BLOCKING event \(event.type.rawValue) from reaching webview")
            #endif
            return nil
        }
    }
    
    // Accept first mouse
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    // Override ALL mouse event methods to consume them completely
    override func mouseDown(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: mouseDown consumed")
        #endif
        // Don't call super - consume the event
    }
    
    override func mouseUp(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: mouseUp consumed")
        #endif
    }
    
    override func rightMouseDown(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: rightMouseDown consumed")
        #endif
    }
    
    override func rightMouseUp(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: rightMouseUp consumed")
        #endif
    }
    
    override func otherMouseDown(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: otherMouseDown consumed")
        #endif
    }
    
    override func otherMouseUp(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: otherMouseUp consumed")
        #endif
    }
    
    override func mouseMoved(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: mouseMoved consumed")
        #endif
    }
    
    override func mouseDragged(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: mouseDragged consumed")
        #endif
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: rightMouseDragged consumed")
        #endif
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: otherMouseDragged consumed")
        #endif
    }
    
    override func scrollWheel(with event: NSEvent) {
        #if DEBUG
        print("MouseBlockingBackgroundView: scrollWheel consumed")
        #endif
    }
    
    // Make this view accept being hit by hit tests
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Check if any subview should handle it first
        for subview in subviews.reversed() {
            if !subview.isHidden {
                let pointInSubview = subview.convert(point, from: self)
                if let hitView = subview.hitTest(pointInSubview) {
                    return hitView
                }
            }
        }
        
        // If we contain the point, return self to intercept the event
        if bounds.contains(point) {
            return self
        }
        
        return nil
    }
}

