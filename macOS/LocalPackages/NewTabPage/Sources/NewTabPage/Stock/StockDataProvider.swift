//
//  StockDataProvider.swift
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

public protocol StockDataProviding {
    func fetchStock(symbol: String) async throws -> NewTabPageDataModel.StockData
}

public final class StockDataProvider: StockDataProviding {

    private let urlSession: URLSession
    private let baseURL: URL
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15 Ddg/26.2"

    public init(urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://18eac2aae4cb.ngrok-free.app")!) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    public func fetchStock(symbol: String) async throws -> NewTabPageDataModel.StockData {
        var components = URLComponents(url: baseURL.appendingPathComponent("stocks.js"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "quote"),
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "query", value: "$\(symbol.lowercased())")
        ]

        guard let url = components?.url else {
            throw StockDataProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(NewTabPageDataModel.StockData.self, from: data)
    }
}

public enum StockDataProviderError: Error {
    case invalidURL
}
