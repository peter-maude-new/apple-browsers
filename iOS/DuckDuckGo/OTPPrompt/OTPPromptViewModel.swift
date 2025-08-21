//
//  OTPPromptViewModel.swift
//  DuckDuckGo
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
import BrowserServicesKit
import SwiftOTP
import Common

protocol OTPPromptViewModelDelegate: AnyObject {
    func otpPromptViewModelDidSelect(_ viewModel: OTPPromptViewModel, otp: String)
    func otpPromptViewModelDidCancel(_ viewModel: OTPPromptViewModel)
    func otpPromptViewModelDidResizeContent(_ viewModel: OTPPromptViewModel, contentHeight: CGFloat)
}

class OTPPromptViewModel: ObservableObject {

    weak var delegate: OTPPromptViewModelDelegate?

    var contentHeight: CGFloat = AutofillViews.otpPromptMinHeight {
        didSet {
            guard contentHeight != oldValue else {
                return
            }
            delegate?.otpPromptViewModelDidResizeContent(self,
                                                         contentHeight: max(contentHeight, AutofillViews.otpPromptMinHeight))
        }
    }

    let account: SecureVaultModels.WebsiteAccount
    @Published var generatedOTP: String = ""
    @Published var timeRemaining: Int = 30
    
    private var totpTimer: Timer?

    internal init(account: SecureVaultModels.WebsiteAccount) {
        self.account = account
        
        // Generate TOTP code if account has a TOTP secret
        if let totpSecret = account.totp, !totpSecret.isEmpty {
            // Set initial time remaining before starting timer
            timeRemaining = calculateTimeRemaining()
            startTOTPTimer()
        }
    }
    
    deinit {
        stopTOTPTimer()
    }
    
    private func startTOTPTimer() {
        generateTOTPCode()
        
        // Update every second for countdown
        totpTimer?.invalidate()
        totpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTOTPDisplay()
        }
    }
    
    private func stopTOTPTimer() {
        totpTimer?.invalidate()
        totpTimer = nil
    }
    
    private func updateTOTPDisplay() {
        let newTimeRemaining = calculateTimeRemaining()
        
        // Generate new code when we transition to a new period
        // This happens when timeRemaining jumps from 1 to 30
        if timeRemaining == 1 && newTimeRemaining == 30 {
            generateTOTPCode()
        }
        
        timeRemaining = newTimeRemaining
    }
    
    private func calculateTimeRemaining(date: Date = Date(), period: TimeInterval = 30) -> Int {
        let elapsed = Int(date.timeIntervalSince1970) % Int(period)
        return Int(period) - elapsed
    }
    
    private func generateTOTPCode() {
        guard let totpSecret = account.totp, !totpSecret.isEmpty else {
            generatedOTP = ""
            return
        }
        
        guard let data = base32DecodeToData(totpSecret) else {
            generatedOTP = ""
            return
        }
        
        if let totpGenerator = TOTP(secret: data), let code = totpGenerator.generate(time: Date()) {
            generatedOTP = code
        } else {
            generatedOTP = ""
        }
    }

    func useOTPPressed() {
        delegate?.otpPromptViewModelDidSelect(self, otp: generatedOTP)
    }

    func cancelButtonPressed() {
        delegate?.otpPromptViewModelDidCancel(self)
    }
}
