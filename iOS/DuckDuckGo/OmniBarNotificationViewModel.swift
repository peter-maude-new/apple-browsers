//
//  OmniBarNotificationViewModel.swift
//  DuckDuckGo
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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

final class OmniBarNotificationViewModel: ObservableObject {

    enum Duration {
        static let notificationSlide: TimeInterval = 0.3
        static let iconAnimationDelay: TimeInterval = notificationSlide * 0.75
        static let notificationCloseDelay: TimeInterval = 2.5
        static let notificationFadeOutDelay: TimeInterval = notificationCloseDelay + 2 * notificationSlide
    }

    let animationName: String
    let eventCount: Int

    @Published var text: String
    @Published var isOpen: Bool = false
    @Published var isAnimating: Bool = false

    init(text: String, animationName: String, eventCount: Int = 0) {
        // Initialize with full text including count
        self.text = text
        self.animationName = animationName
        self.eventCount = eventCount
    }
    
    func showNotification(completion: @escaping () -> Void) {
        // Open the notification
        self.isOpen = true

        // Start animation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Duration.iconAnimationDelay) {
            self.isAnimating = true
            
            // If we have an event count, animate from 50% to 100% over 500ms with easeInOut
            // This needs to be dome in the viewModel as the SwiftUI animation is flaky when updating the text
            if self.eventCount > 0 {
                let baseText = self.text
                let totalDuration: TimeInterval = 0.5 // 500ms total
                let steps = 10
                let startPercent = 0.5 // Start at 50% of total
                
                for i in 1...steps {
                    // Use linear timing for delays, but ease the count progression
                    let progress = Double(i) / Double(steps)
                    let delay = progress * totalDuration

                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // Apply aggressive easeOut to the 50%→100% range: very fast at start, very slow at end
                        // Quartic curve covers ~75% of numbers in first 25% of time
                        let easedProgress = self.easeOutQuart(progress)
                        // Interpolate from 50% to 100% of eventCount
                        let countProgress = startPercent + (easedProgress * (1.0 - startPercent))
                        let currentCount = Int(ceil(Double(self.eventCount) * countProgress))
                        self.text = "\(currentCount) \(baseText)"
                    }
                }
            }
        }

        // Close the notification
        DispatchQueue.main.asyncAfter(deadline: .now() + Duration.notificationCloseDelay) {
            self.isOpen = false
        }

        // Fire completion after everything
        DispatchQueue.main.asyncAfter(deadline: .now() + Duration.notificationFadeOutDelay) {
            completion()
        }
    }
    
    // EaseOut function: very fast at start, very slow at end (quartic for aggressive deceleration)
    // Covers ~75% of numbers in first 25% of time, perfect for large counts
    private func easeOutQuart(_ t: Double) -> Double {
        return 1 - pow(1 - t, 4)
    }
}
