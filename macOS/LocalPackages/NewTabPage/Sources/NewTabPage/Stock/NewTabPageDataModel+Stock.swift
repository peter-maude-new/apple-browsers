//
//  NewTabPageDataModel+Stock.swift
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

public extension NewTabPageDataModel {

    // MARK: - Request from web

    struct StockGetDataRequest: Codable {
        let symbols: [String]
    }

    // MARK: - Response to web (matches API response directly)

    struct StockData: Codable {
        let symbol: String
        let companyName: String
        let latestPrice: Double
        let change: Double
        let changePercent: Double
        let currency: String
        let previousClose: Double?
        let open: Double?
        let high: Double?
        let low: Double?
        let week52High: Double?
        let week52Low: Double?
        let latestUpdate: Int?
        let primaryExchange: String?
        let peRatio: Double?
        let marketCap: Double?
        let avgTotalVolume: Double?
        let assetType: String?
    }
}
