//
//  TabsSearch.swift
//  DuckDuckGo
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

import Foundation

/// Search implementation for tabs with scored matching
final class TabsSearch {

    private struct ScoredTab {
        let tab: Tab
        var score: Int
    }

    /// Search tabs by query string, returning results sorted by relevance
    /// - Parameters:
    ///   - query: The search query string
    ///   - tabs: Array of tabs to search through
    /// - Returns: Array of tabs sorted by relevance score (descending)
    func search(query: String, in tabs: [Tab]) -> [Tab] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        let lowercasedQuery = trimmed.lowercased()
        let tokens = lowercasedQuery.split(separator: " ").filter { !$0.isEmpty }.map { String($0) }

        var scoredTabs: [ScoredTab] = []

        for tab in tabs {
            let score = calculateScore(for: tab, query: lowercasedQuery, tokens: tokens)
            if score > 0 {
                scoredTabs.append(ScoredTab(tab: tab, score: score))
            }
        }

        // Sort by score descending, then by last viewed date for recently viewed bonus
        scoredTabs.sort { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            // Tie-break: more recently viewed tabs first
            let lhsDate = lhs.tab.lastViewedDate ?? Date.distantPast
            let rhsDate = rhs.tab.lastViewedDate ?? Date.distantPast
            return lhsDate > rhsDate
        }

        return scoredTabs.map { $0.tab }
    }

    private func calculateScore(for tab: Tab, query: String, tokens: [String]) -> Int {
        // Get searchable strings
        let title = (tab.link?.displayTitle ?? "New Tab").lowercased()
        let urlString = tab.link?.url.absoluteString.lowercased() ?? ""
        let domain = tab.link?.url.host?.droppingWwwPrefix().lowercased() ?? ""

        var score = 0

        // Domain match from start: +300 (highest priority)
        if !domain.isEmpty && domain.starts(with: query) {
            score += 300
        }

        // Title exact match from start: +200
        if title.leadingBoundaryStartsWith(query) {
            score += 200
        } else if title.contains(" \(query)") {
            // Title word boundary match: +100
            score += 100
        } else if title.contains(query) {
            // Title contains query anywhere: +30
            score += 30
        }

        // Domain contains query: +40
        if !domain.isEmpty && domain.contains(query) {
            score += 40
        }

        // URL contains query: +20
        if !domain.isEmpty && urlString.contains(query) {
            score += 20
        }

        // Tokenized matches (for multi-word queries)
        if tokens.count > 1 {
            var matchesAllTokens = true
            for token in tokens {
                let matchesTitle = title.leadingBoundaryStartsWith(token) || title.contains(" \(token)")
                let matchesDomain = !domain.isEmpty && domain.starts(with: token)

                if !matchesTitle && !matchesDomain {
                    matchesAllTokens = false
                    break
                }
            }

            if matchesAllTokens {
                score += 10

                // Boost if first token matches domain
                if let firstToken = tokens.first, !domain.isEmpty && domain.starts(with: firstToken) {
                    score += 300
                } else if let firstToken = tokens.first, title.leadingBoundaryStartsWith(firstToken) {
                    score += 50
                }
            }
        }

        // Recently viewed bonus: +10 (only if already matched)
        if score > 0,
           let lastViewed = tab.lastViewedDate,
           Date().timeIntervalSince(lastViewed) < 3600 { // Within last hour
            score += 10
        }

        return score
    }
}

private extension String {

    /// Matches strings that start with the given prefix, accounting for leading non-alphanumeric characters
    /// e.g. "Cats and Dogs" would match "Cats" or "\"Cats"
    func leadingBoundaryStartsWith(_ s: String) -> Bool {
        return starts(with: s) || trimmingCharacters(in: .alphanumerics.inverted).starts(with: s)
    }
}
