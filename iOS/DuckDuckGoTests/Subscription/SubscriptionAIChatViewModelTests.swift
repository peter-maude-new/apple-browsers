//
//  SubscriptionAIChatViewModelTests.swift
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

import XCTest
import Combine
@testable import DuckDuckGo
@testable import Core
@testable import AIChat
import WebKit

final class SubscriptionAIChatViewModelTests: XCTestCase {
    
    private var viewModel: SubscriptionAIChatViewModel!
    private var mockNavigationCoordinator: MockHeadlessWebViewNavCoordinator!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockNavigationCoordinator = MockHeadlessWebViewNavCoordinator()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitializationConfiguresWebViewWithAIChatDomain() {
        // When
        viewModel = SubscriptionAIChatViewModel(isInternalUser: false)
        
        // Then
        let webViewSettings = viewModel.webViewModel.settings
        let expectedHost = AIChatSettings().aiChatURL.host
        
        XCTAssertNotNil(webViewSettings.allowedDomains)
        XCTAssertTrue(webViewSettings.allowedDomains?.contains(expectedHost ?? "") ?? false, 
                     "WebView should be configured to allow AI Chat domain")
        XCTAssertTrue(webViewSettings.bounces, "WebView should allow bouncing for better UX")
        XCTAssertFalse(webViewSettings.contentBlocking, "Content blocking should be disabled for AI Chat")
        XCTAssertFalse(viewModel.navigationError, "Should start with no navigation error")
    }

    func testOnFirstAppearNavigationOccurs() {
        // Given
        viewModel = SubscriptionAIChatViewModel(isInternalUser: false)
        viewModel.webViewModel.navigationCoordinator = mockNavigationCoordinator

        // When
        viewModel.onFirstAppear()

        // Then
        XCTAssertEqual(mockNavigationCoordinator.currentURL, AIChatSettings().aiChatURL)
    }

    func testOnNavigateBackNavigationOccurs() async {
        // Given
        viewModel = SubscriptionAIChatViewModel(isInternalUser: false)
        viewModel.webViewModel.navigationCoordinator = mockNavigationCoordinator

        // When
        await viewModel.navigateBack()

        // Then
        XCTAssertTrue(mockNavigationCoordinator.goBackCalled)
    }

    func testOnWebViewNavigationErrorViewModelNAvigationErrorIsTrue() async {
        // Given
        viewModel = SubscriptionAIChatViewModel(isInternalUser: false)
        let expectation = XCTestExpectation(description: "Wait for navigationError to be true")

        // When
        viewModel.webViewModel.navigationError = NSError(domain: "", code: 1)

        // Then
        Task {
            while !viewModel.navigationError {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(viewModel.navigationError)
    }
}
