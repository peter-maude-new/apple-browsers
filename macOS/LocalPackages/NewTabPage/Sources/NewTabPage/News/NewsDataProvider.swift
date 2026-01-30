//
//  NewsDataProvider.swift
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

public protocol NewsDataProviding {
    func fetchNews(query: String) async throws -> NewTabPageDataModel.NewsData
}

public final class NewsDataProvider: NewsDataProviding {

    private let urlSession: URLSession
    private let baseURL: URL
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15 Ddg/26.2"

    public init(urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://18eac2aae4cb.ngrok-free.app")!) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    public func fetchNews(query: String) async throws -> NewTabPageDataModel.NewsData {
        var components = URLComponents(url: baseURL.appendingPathComponent("news.js"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "o", value: "json"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "l", value: "au-en"),
            URLQueryItem(name: "p", value: "-1"),
            URLQueryItem(name: "noamp", value: "1"),
            URLQueryItem(name: "m", value: "30"),
            URLQueryItem(name: "nml", value: "1"),
            URLQueryItem(name: "u", value: "bing"),
            URLQueryItem(name: "uf", value: "0")
        ]

        guard let url = components?.url else {
            throw NewsDataProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, _) = try await urlSession.data(for: request)
        let response = try JSONDecoder().decode(NewTabPageDataModel.NewsAPIResponse.self, from: data)

        let allResults = response.results.compactMap { item -> NewTabPageDataModel.NewsItem? in
            guard let title = item.title, let url = item.url else { return nil }
            return NewTabPageDataModel.NewsItem(
                title: title,
                url: url,
                source: item.source ?? "Unknown",
                relative_time: item.date.map { formatRelativeTime($0) },
                excerpt: item.excerpt,
                image: item.image
            )
        }

        return NewTabPageDataModel.NewsData(
            results: Array(allResults.prefix(4))
        )
    }

    private func formatRelativeTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

public enum NewsDataProviderError: Error {
    case invalidURL
}
