//
//  WeatherDataProvider.swift
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

public protocol WeatherDataProviding {
    func fetchWeather(location: String) async throws -> NewTabPageDataModel.WeatherData
}

public final class WeatherDataProvider: WeatherDataProviding {

    private let urlSession: URLSession
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15 Ddg/26.2"

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func fetchWeather(location: String) async throws -> NewTabPageDataModel.WeatherData {
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        guard let url = URL(string: "https://duckduckgo.com/weather.js?q=\(encodedLocation)&lang=en") else {
            throw WeatherDataProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await urlSession.data(for: request)

        let jsonData = try stripJSONPWrapper(data)
        let response = try JSONDecoder().decode(NewTabPageDataModel.WeatherAPIResponse.self, from: jsonData)

        // Extract today's high/low from first day of forecast
        let todayForecast = response.forecastDaily?.days.first
        let high = todayForecast?.temperatureMax
        let low = todayForecast?.temperatureMin

        // Build forecast array (up to 7 days)
        let forecast: [NewTabPageDataModel.ForecastDay]? = response.forecastDaily?.days.prefix(7).compactMap { day in
            guard let shortDay = formatShortDayName(from: day.forecastStart) else { return nil }
            return NewTabPageDataModel.ForecastDay(
                day: shortDay,
                high: day.temperatureMax,
                conditionCode: day.conditionCode
            )
        }

        return NewTabPageDataModel.WeatherData(
            temperature: response.currentWeather.temperature,
            apparentTemperature: response.currentWeather.temperatureApparent,
            conditionCode: response.currentWeather.conditionCode,
            location: location,
            humidity: response.currentWeather.humidity,
            windSpeed: response.currentWeather.windSpeed,
            high: high,
            low: low,
            forecast: forecast
        )
    }

    private func formatShortDayName(from isoDateString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoDateString) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            return dayFormatter.string(from: date)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoDateString) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            return dayFormatter.string(from: date)
        }
        return nil
    }

    private func stripJSONPWrapper(_ data: Data) throws -> Data {
        guard let string = String(data: data, encoding: .utf8) else {
            throw WeatherDataProviderError.invalidResponse
        }

        // JSONP format: ddg_spice_forecast({...})
        guard let startIndex = string.firstIndex(of: "("),
              let endIndex = string.lastIndex(of: ")") else {
            throw WeatherDataProviderError.invalidJSONPFormat
        }

        let jsonString = String(string[string.index(after: startIndex)..<endIndex])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw WeatherDataProviderError.invalidResponse
        }

        return jsonData
    }
}

public enum WeatherDataProviderError: Error {
    case invalidURL
    case invalidResponse
    case invalidJSONPFormat
}
