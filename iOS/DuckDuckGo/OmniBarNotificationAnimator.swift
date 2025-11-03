//
//  OmniBarNotificationAnimator.swift
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

import UIKit

enum OmniBarNotificationType {
    case cookiePopupManaged
    case cookiePopupHidden
    case trackersBlocked(count: Int)
}

final class OmniBarNotificationAnimator: NSObject {
    
    func showNotification(_ type: OmniBarNotificationType, in omniBar: any OmniBarView, viewController: UIViewController) {

        omniBar.notificationContainer.alpha = 0
        omniBar.notificationContainer.prepareAnimation(type, in: viewController)
        omniBar.textField.alpha = 0
        
        let fadeDuration = Constants.Duration.fade
        let animationStartOffset = 2 * fadeDuration
        
        // First: Fade in the notification with the shield
        UIView.animate(withDuration: fadeDuration) {
            omniBar.notificationContainer.alpha = 1
        }
        
        // Then: Fade out the original privacy icon behind it
        UIView.animate(withDuration: fadeDuration, delay: fadeDuration) {
            omniBar.privacyInfoContainer.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationStartOffset) {
            
            omniBar.notificationContainer.startAnimation {
                // First: Fade in the original privacy icon (behind the notification)
                UIView.animate(withDuration: fadeDuration) {
                    omniBar.textField.alpha = 1
                    omniBar.privacyInfoContainer.alpha = 1
                }
                
                // Then: Fade out the notification
                UIView.animate(withDuration: fadeDuration, delay: fadeDuration) {
                    omniBar.notificationContainer.alpha = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2 * fadeDuration) {
                    omniBar.notificationContainer.removePreviousNotification()
                }
            }
        }
    }
    
    func cancelAnimations(in omniBar: any OmniBarView) {
        omniBar.notificationContainer.removePreviousNotification()
        omniBar.notificationContainer.alpha = 0
        omniBar.textField.alpha = 1
        omniBar.privacyInfoContainer.alpha = 1
    }
}

private enum Constants {
    enum Duration {
        static let fade: TimeInterval = 0.25
    }
}
