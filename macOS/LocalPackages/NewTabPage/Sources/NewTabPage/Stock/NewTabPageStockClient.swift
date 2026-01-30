//
//  NewTabPageStockClient.swift
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

import Common
import os.log
import UserScriptActionsManager
import WebKit

public final class NewTabPageStockClient: NewTabPageUserScriptClient {

    private let dataProvider: StockDataProviding

    public init(dataProvider: StockDataProviding) {
        self.dataProvider = dataProvider
        super.init()
    }

    enum MessageName: String, CaseIterable {
        case getData = "stock_getData"
    }

    public override func registerMessageHandlers(for userScript: NewTabPageUserScript) {
        userScript.registerMessageHandlers([
            MessageName.getData.rawValue: { [weak self] in try await self?.getData(params: $0, original: $1) }
        ])
    }

    @MainActor
    private func getData(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        Logger.general.debug("NTP Stock: Received getData request with params: \(String(describing: params), privacy: .public)")

        guard let request: NewTabPageDataModel.StockGetDataRequest = DecodableHelper.decode(from: params) else {
            Logger.general.error("NTP Stock: Failed to decode request params")
            return nil
        }

        Logger.general.debug("NTP Stock: Fetching stock for symbol: \(request.symbol, privacy: .public)")

        do {
            let data = try await dataProvider.fetchStock(symbol: request.symbol)
            Logger.general.debug("NTP Stock: Successfully fetched stock data - symbol: \(data.symbol, privacy: .public), price: \(data.latestPrice)")
            return data
        } catch {
            Logger.general.error("NTP Stock: Fetch error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
