//
//  QuitSurveyViewModel.swift
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
import os.log
import Common

// MARK: - Survey Option Model

struct QuitSurveyOption: Identifiable, Hashable {
    let id: String
    let text: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: QuitSurveyOption, rhs: QuitSurveyOption) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Survey State

enum QuitSurveyState: Equatable {
    case initialQuestion
    case positiveResponse
    case negativeFeedback
}

// MARK: - View Model

@MainActor
final class QuitSurveyViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: QuitSurveyState = .initialQuestion
    @Published var selectedOptions: Set<String> = []
    @Published var feedbackText: String = ""
    @Published private(set) var autoQuitCountdown: Int = 5

    // MARK: - Configuration

    private static let allOptions: [QuitSurveyOption] = [
        QuitSurveyOption(id: "asked-to-disable-ad-blocker", text: "Asked to disable Ad Blocker"),
        QuitSurveyOption(id: "pages-froze", text: "Pages froze"),
        QuitSurveyOption(id: "pages-loaded-slowly", text: "Pages loaded slowly"),
        QuitSurveyOption(id: "more-captchas", text: "More CAPTCHAs"),
        QuitSurveyOption(id: "couldnt-check-out", text: "Couldn't check out"),
        QuitSurveyOption(id: "couldnt-sign-in-to-bank", text: "Couldn't sign in to bank"),
        QuitSurveyOption(id: "videos-didnt-play", text: "Videos didn't play"),
        QuitSurveyOption(id: "browser-crashed", text: "Browser crashed"),
        QuitSurveyOption(id: "tabs-opened-slowly", text: "Tabs opened slowly"),
        QuitSurveyOption(id: "slowed-my-computer", text: "Slowed my computer"),
        QuitSurveyOption(id: "slow-to-open", text: "Slow to open"),
        QuitSurveyOption(id: "couldnt-disable-ai", text: "Couldn't disable AI"),
        QuitSurveyOption(id: "bad-ai-responses", text: "Bad AI responses"),
        QuitSurveyOption(id: "hard-to-find-settings", text: "Hard to find Settings"),
        QuitSurveyOption(id: "hard-to-manage-downloads", text: "Hard to manage downloads"),
        QuitSurveyOption(id: "shortcuts-didnt-work", text: "Shortcuts didn't work"),
        QuitSurveyOption(id: "navigation-unfamiliar", text: "Navigation unfamiliar"),
        QuitSurveyOption(id: "fire-button-removed-too-much", text: "Fire Button removed too much"),
        QuitSurveyOption(id: "couldnt-find-incognito", text: "Couldn't find incognito"),
        QuitSurveyOption(id: "password-manager-unavailable", text: "Password manager unavailable"),
        QuitSurveyOption(id: "ad-blocker-didnt-work", text: "Ad Blocker didn't work"),
        QuitSurveyOption(id: "couldnt-skip-onboarding", text: "Couldn't skip onboarding"),
        QuitSurveyOption(id: "onboarding-wasnt-helpful", text: "Onboarding wasn't helpful"),
        QuitSurveyOption(id: "couldnt-import-bookmarks", text: "Couldn't import bookmarks"),
        QuitSurveyOption(id: "couldnt-import-passwords", text: "Couldn't import passwords"),
        QuitSurveyOption(id: "couldnt-import-pay-details", text: "Couldn't import pay details"),
        QuitSurveyOption(id: "couldnt-change-search-engine", text: "Couldn't change search engine"),
        QuitSurveyOption(id: "unexpected-search-results", text: "Unexpected search results"),
        QuitSurveyOption(id: "benefits-unclear", text: "Benefits unclear"),
        QuitSurveyOption(id: "privacy-concerns", text: "Privacy concerns"),
        QuitSurveyOption(id: "unsure-how-history-is-handled", text: "Unsure how history is handled"),
        QuitSurveyOption(id: "just-trying-it-out", text: "Just trying it out"),
        QuitSurveyOption(id: "not-ready-to-switch-browsers", text: "Not ready to switch browsers"),
        QuitSurveyOption(id: "had-to-re-sign-in", text: "Had to re-sign in"),
        QuitSurveyOption(id: "sign-in-hassles", text: "Sign in hassles")
    ]

    private static let somethingElseOption = QuitSurveyOption(id: "something-else", text: "Something else")

    let availableOptions: [QuitSurveyOption]

    private let feedbackSender: FeedbackSenderImplementing
    private let onQuit: () -> Void
    private var autoQuitTimer: Timer?

    // MARK: - Computed Properties

    var shouldShowTextInput: Bool {
        selectedOptions.contains("something-else")
    }

    var shouldEnableSubmit: Bool {
        !selectedOptions.isEmpty || !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Initialization

    init(
        feedbackSender: FeedbackSenderImplementing = FeedbackSender(),
        onQuit: @escaping () -> Void
    ) {
        self.feedbackSender = feedbackSender
        self.onQuit = onQuit

        // Select 8 random options + "Something else"
        let randomOptions = Array(Self.allOptions.shuffled().prefix(8))
        self.availableOptions = randomOptions + [Self.somethingElseOption]
    }

    // MARK: - Actions

    func selectPositiveResponse() {
        state = .positiveResponse
        startAutoQuitTimer()
    }

    func selectNegativeResponse() {
        state = .negativeFeedback
    }

    func goBack() {
        stopAutoQuitTimer()
        selectedOptions.removeAll()
        feedbackText = ""
        state = .initialQuestion
    }

    func toggleOption(_ optionId: String) {
        if selectedOptions.contains(optionId) {
            selectedOptions.remove(optionId)
        } else {
            selectedOptions.insert(optionId)
        }
    }

    func submitFeedback() {
        let feedback = Feedback.from(
            selectedPillIds: Array(selectedOptions),
            text: feedbackText,
            appVersion: AppVersion.shared.versionNumber,
            category: .bug,
            problemCategory: ProblemCategory.allCategories.first { $0.isSomethingElseCategory } ?? ProblemCategory.allCategories.first!
        )

        feedbackSender.sendFeedback(feedback)
        Logger.general.debug("Quit survey feedback submitted")

        quit()
    }

    func quit() {
        stopAutoQuitTimer()
        onQuit()
    }

    func closeAndQuit() {
        quit()
    }

    // MARK: - Auto Quit Timer

    private func startAutoQuitTimer() {
        autoQuitCountdown = 5
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.autoQuitCountdown -= 1
                if self.autoQuitCountdown <= 0 {
                    self.quit()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoQuitTimer = timer
    }

    private func stopAutoQuitTimer() {
        autoQuitTimer?.invalidate()
        autoQuitTimer = nil
    }

    deinit {
        autoQuitTimer?.invalidate()
    }
}
