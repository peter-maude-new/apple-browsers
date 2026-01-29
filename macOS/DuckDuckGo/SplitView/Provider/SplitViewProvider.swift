//
//  SplitViewProvider.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

/// Provides split view state management for a window.
/// The split view model is "docked" - the secondary tab stays visible
/// regardless of which primary tab is selected in the tab bar.
@MainActor
protocol SplitViewProviding: AnyObject {
    /// The currently docked secondary tab, or nil if split view is not active
    var dockedTab: Tab? { get }

    /// The original index of the docked tab (for restoring to original position)
    var originalTabIndex: Int? { get }

    /// Whether split view is currently showing
    var isShowingSplitView: Bool { get }

    /// Dock a tab to the secondary pane (activates split view)
    func dockTab(_ tab: Tab, originalIndex: Int?)

    /// Undock the secondary tab (deactivates split view)
    /// Returns the previously docked tab and its original index so it can be restored
    @discardableResult
    func undockTab() -> (tab: Tab, originalIndex: Int?)?
}

@MainActor
final class SplitViewProvider: SplitViewProviding {

    /// The tab docked to the secondary pane
    private(set) var dockedTab: Tab?

    /// The original index of the docked tab (for restoring to original position)
    private(set) var originalTabIndex: Int?

    var isShowingSplitView: Bool {
        dockedTab != nil
    }

    func dockTab(_ tab: Tab, originalIndex: Int? = nil) {
        dockedTab = tab
        originalTabIndex = originalIndex
        print("🔲 SplitView: Docked tab \(tab.uuid) from index \(originalIndex ?? -1)")
    }

    @discardableResult
    func undockTab() -> (tab: Tab, originalIndex: Int?)? {
        guard let tab = dockedTab else { return nil }
        let index = originalTabIndex
        dockedTab = nil
        originalTabIndex = nil
        print("🔲 SplitView: Undocked tab \(tab.uuid), original index was \(index ?? -1)")
        return (tab, index)
    }
}
