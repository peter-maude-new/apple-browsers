//
//  TabCrashIndicatorModel.swift
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

import Combine
import Foundation

final class TabCrashIndicatorModel: ObservableObject {
    private var cancellables: Set<AnyCancellable> = []
    private let resetRecentTabCrashSubject = PassthroughSubject<Void, Never>()

    func setUp(with tab: Tab) {
        let crashPublisher = tab.crashPublisher.map(TabCrashType?.some).share()

        let resetRecentTabCrash = crashPublisher
            .delay(for: .seconds(20), scheduler: RunLoop.main)
            .filter { [weak self] tabCrashType in
                return self?.isShowingPopover == false
            }
            .map { _ in TabCrashType?.none }

        let clearRecentTabCrashOnPopoverDismiss = $isShowingPopover.dropFirst()
            .filter { !$0 }
            .map { _ in TabCrashType?.none }

        Publishers.Merge3(crashPublisher, resetRecentTabCrash, clearRecentTabCrashOnPopoverDismiss)
            .removeDuplicates()
            .sink { [weak self] tabCrashType in
                print("Tab Crash Type: Setting \(String(reflecting: tabCrashType))")
                self?.recentTabCrash = tabCrashType
            }
            .store(in: &cancellables)
    }

    @Published var recentTabCrash: TabCrashType? {
        didSet {
            print("Tab Crash Type: New value set - \(String(reflecting: recentTabCrash))")
        }
    }
    @Published var isShowingPopover: Bool = false {
        didSet {
            print("Tab Crash Type: isShowingPopover \(isShowingPopover)")
        }
    }
}
