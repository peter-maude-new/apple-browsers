//
//  OTPPromptViewController.swift
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

import UIKit
import BrowserServicesKit
import SwiftUI

class OTPPromptViewController: UIViewController {
    private let account: SecureVaultModels.WebsiteAccount
    private let completion: (String?) -> Void

    internal init(account: SecureVaultModels.WebsiteAccount, completion: @escaping (String?) -> Void) {
        self.account = account
        self.completion = completion

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(designSystemColor: .surface)

        setupOTPPromptView()
    }

    private func setupOTPPromptView() {
        let otpPromptViewModel = OTPPromptViewModel(account: account)
        otpPromptViewModel.delegate = self

        let otpPromptView = OTPPromptView(viewModel: otpPromptViewModel)
        let controller = UIHostingController(rootView: otpPromptView)
        controller.view.backgroundColor = .clear
        presentationController?.delegate = self
        installChildViewController(controller)
    }

}

extension OTPPromptViewController: OTPPromptViewModelDelegate {
    func otpPromptViewModelDidSelect(_ viewModel: OTPPromptViewModel, otp: String) {
        dismiss(animated: true) { [weak self] in
            self?.completion(otp)
        }
    }

    func otpPromptViewModelDidCancel(_ viewModel: OTPPromptViewModel) {
        dismiss(animated: true) { [weak self] in
            self?.completion(nil)
        }
    }

    func otpPromptViewModelDidResizeContent(_ viewModel: OTPPromptViewModel, contentHeight: CGFloat) {
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = self.presentationController as? UISheetPresentationController {
                sheetPresentationController.animateChanges {
                    sheetPresentationController.detents = [.custom(resolver: { _ in contentHeight })]
                }
            }
        }
    }
}

extension OTPPromptViewController: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismiss(animated: true) { [weak self] in
            self?.completion(nil)
        }
    }
}
