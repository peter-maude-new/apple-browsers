//
//  TabBarDragSessionDelegate.swift
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

import AppKit

@MainActor
class TabBarDragSessionDelegate {

    private unowned let collectionView: NSCollectionView
    private var draggedItemView: NSView?
    private var previousDragLocation: NSPoint = .zero
    private var draggingToNewWindow = false

    private var clearDraggingImage: NSImage?
    private var defaultDraggingImage: NSImage?

    init(collectionView: NSCollectionView) {
        self.collectionView = collectionView
    }

    private func convertToLocalCoordinates(screenPoint: NSPoint) -> NSPoint? {
        guard let pointInWindow = collectionView.window?.convertPoint(fromScreen: screenPoint) else {
            return nil
        }

        return collectionView.convert(pointInWindow, from: nil)
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        guard let selectedTabIndex = collectionView.selectionIndexPaths.first, let draggedItem = collectionView.item(at: selectedTabIndex) as? TabBarViewItem else {
            return
        }

        guard let scrollView = collectionView.enclosingScrollView else {
            return
        }

        let draggedImage = snapshotImage(for: draggedItem.view)
        let draggedImageView = NSImageView(image: draggedImage)
        scrollView.addSubview(draggedImageView)

        let updatedOrigin = scrollView.convert(draggedItem.view.frame.origin, from: collectionView)
        draggedImageView.frame = draggedItem.view.frame
        draggedImageView.frame.origin.x = updatedOrigin.x

        draggedItemView = draggedImageView
        previousDragLocation = screenPoint
        draggingToNewWindow = false

        clearDraggingImage = draggedItem.clearDraggingImage
        defaultDraggingImage = draggedImage

        refreshDraggingItemContents(session: session, draggingToNewWindow: false)
    }

    func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        guard let draggedItemView else {
            return
        }

        refreshDraggedViewLocation(draggedItemView, screenPoint: screenPoint)
        previousDragLocation = screenPoint

        let latestDraggingToNewWindow = isDraggingToNewWindow(screenPoint: screenPoint)
        guard draggingToNewWindow != latestDraggingToNewWindow else {
            return
        }

        refreshDraggingItemContents(session: session, draggingToNewWindow: latestDraggingToNewWindow)

        draggedItemView.isHidden = latestDraggingToNewWindow
        draggingToNewWindow = latestDraggingToNewWindow
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggedItemView?.removeFromSuperview()
        draggedItemView = nil
    }
}

private extension TabBarDragSessionDelegate {

    func snapshotImage(for view: NSView) -> NSImage {
        view.isHidden = false
        let draggedImage = view.imageRepresentation()
        view.isHidden = true

        return draggedImage
    }

    func refreshDraggedViewLocation(_ draggedView: NSView, screenPoint: NSPoint) {
        draggedView.frame.origin.x += screenPoint.x - previousDragLocation.x
    }

    func isDraggingToNewWindow(screenPoint: NSPoint) -> Bool {
        guard let locationInView = convertToLocalCoordinates(screenPoint: screenPoint) else {
            return false
        }

        return collectionView.frame.contains(locationInView) == false
    }

    func refreshDraggingItemContents(session: NSDraggingSession, draggingToNewWindow: Bool) {
        let contents = draggingToNewWindow ? defaultDraggingImage : clearDraggingImage

        session.enumerateDraggingItems(options: [], for: nil, classes: [NSPasteboardItem.self], searchOptions: [:]) { draggingItem, index, stop in
            draggingItem.setDraggingFrame(draggingItem.draggingFrame, contents: contents)
        }
    }
}

private extension NSCollectionViewItem {

    var clearDraggingImage: NSImage {
        let clearImage = NSImage(size: view.bounds.size)
        clearImage.lockFocus()
        clearImage.unlockFocus()
        return clearImage
    }

    var defaultDraggingImage: NSImage? {
        draggingImageComponents.first?.contents as? NSImage
    }
}
