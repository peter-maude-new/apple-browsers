//
//  NewTabPageDataModel+News.swift
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

    struct NewsGetDataRequest: Codable {
        let query: String
    }

    // MARK: - Response to web

    struct NewsData: Encodable {
        let results: [NewsItem]
    }

    struct NewsItem: Encodable {
        let title: String
        let url: String
        let source: String
        let relative_time: String?
        let excerpt: String?
        let image: String?
    }

    // MARK: - Internal API response parsing

    struct NewsAPIResponse: Decodable {
        let results: [NewsAPIItem]

        struct NewsAPIItem: Decodable {
            let title: String?
            let url: String?
            let source: String?
            let date: Int?
            let excerpt: String?
            let image: String?
        }
    }
}
