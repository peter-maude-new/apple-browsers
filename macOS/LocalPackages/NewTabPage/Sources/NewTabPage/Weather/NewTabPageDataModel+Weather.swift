//
//  NewTabPageDataModel+Weather.swift
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

    struct WeatherGetDataRequest: Codable {
        let location: String
    }

    // MARK: - Response to web

    struct WeatherData: Encodable {
        let temperature: Double
        let apparentTemperature: Double?
        let conditionCode: String
        let location: String
        let humidity: Double?
        let windSpeed: Double?
        let high: Double?
        let low: Double?
        let forecast: [ForecastDay]?
    }

    struct ForecastDay: Encodable {
        let day: String
        let high: Double
        let conditionCode: String
    }

    // MARK: - Internal API response parsing

    struct WeatherAPIResponse: Decodable {
        let currentWeather: CurrentWeather
        let forecastDaily: ForecastDaily?

        struct CurrentWeather: Decodable {
            let temperature: Double
            let temperatureApparent: Double
            let conditionCode: String
            let humidity: Double
            let windSpeed: Double
        }

        struct ForecastDaily: Decodable {
            let days: [DayForecast]

            struct DayForecast: Decodable {
                let forecastStart: String
                let temperatureMax: Double
                let temperatureMin: Double
                let conditionCode: String
            }
        }
    }
}
