//
//  MockCSSCommunicationDelegate.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import DataBrokerProtectionCore
import WebKit

public final class MockCSSCommunicationDelegate: CCFCommunicationDelegate {
    public var lastError: Error?
    public var didReceiveError = false
    public var profiles: [ExtractedProfile]?
    public var meta: [String: Any]?
    public var url: URL?
    public var captchaInfo: GetCaptchaInfoResponse?
    public var solveCaptchaResponse: SolveCaptchaResponse?
    public var successActionId: String?
    public var successActionType: ActionType?
    public var onErrorCallback: ((Error) -> Void)?

    public init() {}

    public func loadURL(url: URL) async {
        self.url = url
    }

    public func extractedProfiles(profiles: [ExtractedProfile], meta: [String: Any]?) async {
        self.profiles = profiles
        self.meta = meta
    }

    public func success(actionId: String, actionType: ActionType) async {
        self.successActionId = actionId
        self.successActionType = actionType
    }

    public func captchaInformation(captchaInfo: GetCaptchaInfoResponse) async {
        self.captchaInfo = captchaInfo
    }

    public func onError(error: Error) async {
        self.lastError = error
        didReceiveError = true
        onErrorCallback?(error)
    }

    public func solveCaptcha(with response: SolveCaptchaResponse) async {
        self.solveCaptchaResponse = response
    }

    public func reset() {
        lastError = nil
        didReceiveError = false
        url = nil
        profiles = nil
        meta = nil
        successActionId = nil
        successActionType = nil
        captchaInfo = nil
        solveCaptchaResponse = nil
        onErrorCallback = nil
    }
} 