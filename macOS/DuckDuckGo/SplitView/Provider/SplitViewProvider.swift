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

    /// Whether split view is currently showing
    var isShowingSplitView: Bool { get }

    /// Dock a tab to the secondary pane (activates split view)
    func dockTab(_ tab: Tab)

    /// Undock the secondary tab (deactivates split view)
    /// Returns the previously docked tab so it can be restored to the tab bar
    @discardableResult
    func undockTab() -> Tab?
}

@MainActor
final class SplitViewProvider: SplitViewProviding {

    /// The tab docked to the secondary pane
    private(set) var dockedTab: Tab?

    var isShowingSplitView: Bool {
        dockedTab != nil
    }

    func dockTab(_ tab: Tab) {
        dockedTab = tab
        print("🔲 SplitView: Docked tab \(tab.uuid)")
    }

    @discardableResult
    func undockTab() -> Tab? {
        let tab = dockedTab
        dockedTab = nil
        if let tab = tab {
            print("🔲 SplitView: Undocked tab \(tab.uuid)")
        }
        return tab
    }
}
