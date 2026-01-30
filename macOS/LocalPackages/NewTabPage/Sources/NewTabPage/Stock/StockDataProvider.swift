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
    func fetchStocks(symbols: [String]) async -> [NewTabPageDataModel.StockData]
}

public final class StockDataProvider: StockDataProviding {

    private let urlSession: URLSession
    private let baseURL: URL
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15 Ddg/26.2"

    public init(urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://randerson.duck.co")!) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    public func fetchStock(symbol: String) async throws -> NewTabPageDataModel.StockData {
        // TODO: Remove mock data when dev server supports closed markets
        if let mockData = Self.mockData[symbol.uppercased()] {
            return mockData
        }

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

        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(NewTabPageDataModel.StockData.self, from: data)
    }

    // MARK: - Mock Data (TODO: Remove when dev server supports closed markets)

    private static let mockData: [String: NewTabPageDataModel.StockData] = [
        "AAPL": NewTabPageDataModel.StockData(
            symbol: "AAPL",
            companyName: "Apple Inc",
            latestPrice: 258.28,
            change: 1.84,
            changePercent: 0.007175,
            currency: "USD",
            previousClose: 258.28,
            open: 258,
            high: 259.65,
            low: 254.41,
            week52High: 288.62,
            week52Low: 169.2101,
            latestUpdate: 1769721300000,
            primaryExchange: "NSQ",
            peRatio: 34.7778,
            marketCap: nil,
            avgTotalVolume: nil,
            assetType: "stock"
        ),
        "MSFT": NewTabPageDataModel.StockData(
            symbol: "MSFT",
            companyName: "Microsoft Corp",
            latestPrice: 433.5,
            change: -48.13,
            changePercent: -0.099931,
            currency: "USD",
            previousClose: 433.5,
            open: 439.99,
            high: 442.5,
            low: 421.02,
            week52High: 555.45,
            week52Low: 344.79,
            latestUpdate: 1769720400000,
            primaryExchange: "NSQ",
            peRatio: 27.1235,
            marketCap: nil,
            avgTotalVolume: nil,
            assetType: "stock"
        ),
        "NVDA": NewTabPageDataModel.StockData(
            symbol: "NVDA",
            companyName: "NVIDIA Corp",
            latestPrice: 192.51,
            change: 0.99,
            changePercent: 0.005169,
            currency: "USD",
            previousClose: 192.51,
            open: 191.34,
            high: 193.48,
            low: 186.06,
            week52High: 212.1899,
            week52Low: 86.62,
            latestUpdate: 1769720400000,
            primaryExchange: "NSQ",
            peRatio: 47.6811,
            marketCap: nil,
            avgTotalVolume: nil,
            assetType: "stock"
        )
    ]

    public func fetchStocks(symbols: [String]) async -> [NewTabPageDataModel.StockData] {
        await withTaskGroup(of: NewTabPageDataModel.StockData?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try? await self.fetchStock(symbol: symbol)
                }
            }

            var results: [NewTabPageDataModel.StockData] = []
            for await result in group {
                if let stockData = result {
                    results.append(stockData)
                }
            }
            return results
        }
    }
}

public enum StockDataProviderError: Error {
    case invalidURL
}
