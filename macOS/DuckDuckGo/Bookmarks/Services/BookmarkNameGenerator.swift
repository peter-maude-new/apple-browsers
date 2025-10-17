//
//  BookmarkNameGenerator.swift
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
import FoundationModels

/// Generates concise, descriptive bookmark names using the local LLM
@available(macOS 26.0, *)
@MainActor
final class BookmarkNameGenerator {

    /// Generates a better bookmark name from the webpage title and URL
    /// - Parameters:
    ///   - pageTitle: The original webpage title
    ///   - url: The webpage URL
    /// - Returns: A concise, descriptive bookmark name. Falls back to original title if generation fails.
    func generateName(from pageTitle: String, url: URL) async -> String {
        // If title is already short enough, just return it
        if pageTitle.count <= 50 {
            return pageTitle
        }

        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            // Model not available, return original title
            return pageTitle
        }

        do {
            let prompt = """
            Generate a short, descriptive bookmark name (max 50 characters) from this webpage title and URL.
            Focus on the main topic or purpose. Remove marketing fluff, dates, and "- Site Name" suffixes.

            Webpage title: "\(pageTitle)"
            URL: \(url.absoluteString)

            Respond with ONLY the bookmark name, nothing else.
            """

            // Create a session for one-shot generation
            let session = LanguageModelSession(tools: []) { prompt }

            // Stream the response and collect it
            let stream = session.streamResponse(to: "Generate the bookmark name.")
            var generatedName = ""

            for try await snapshot in stream {
                generatedName = snapshot.content
            }

            generatedName = generatedName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate the generated name
            guard !generatedName.isEmpty,
                  generatedName.count <= 50,
                  !generatedName.localizedCaseInsensitiveContains("error"),
                  !generatedName.localizedCaseInsensitiveContains("cannot") else {
                return pageTitle
            }

            return generatedName

        } catch {
            // Generation failed, return original title
            return pageTitle
        }
    }
}
