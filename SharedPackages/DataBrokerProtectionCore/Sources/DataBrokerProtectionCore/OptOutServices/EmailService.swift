//
//  EmailService.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import Common
import os.log

public enum EmailError: Error, Equatable, Codable {
    case cantGenerateURL
    case cantFindEmail
    case invalidEmailLink
    case cancelled
    case httpError(statusCode: Int)
    case unknownHTTPError
    case extractionError
    case requestError
    case serverError
    case retriesExceeded
}

public struct EmailData: Decodable {
    let pattern: String?
    let emailAddress: String

    public init(pattern: String?, emailAddress: String) {
        self.pattern = pattern
        self.emailAddress = emailAddress
    }
}

public protocol EmailServiceProtocol {
    func getEmail(dataBrokerURL: String, attemptId: UUID) async throws -> EmailData
}

public struct EmailService: EmailServiceProtocol {
    private struct Constants {
        static let endpointSubPath = "/dbp/em/v0"
    }

    public let urlSession: URLSession
    private let authenticationManager: DataBrokerProtectionAuthenticationManaging
    private let settings: DataBrokerProtectionSettings
    private let servicePixel: DataBrokerProtectionBackendServicePixels

    public init(urlSession: URLSession = URLSession.shared,
                authenticationManager: DataBrokerProtectionAuthenticationManaging,
                settings: DataBrokerProtectionSettings,
                servicePixel: DataBrokerProtectionBackendServicePixels) {
        self.urlSession = urlSession
        self.authenticationManager = authenticationManager
        self.settings = settings
        self.servicePixel = servicePixel
    }

    public func getEmail(dataBrokerURL: String, attemptId: UUID) async throws -> EmailData {
        Logger.service.log("✉️ [EmailService] Getting email for dataBroker: \(dataBrokerURL, privacy: .public), attemptId: \(attemptId.uuidString, privacy: .public)")

        var urlComponents = URLComponents(url: settings.endpointURL, resolvingAgainstBaseURL: true)
        urlComponents?.path += "\(Constants.endpointSubPath)/generate"
        urlComponents?.queryItems = [
            URLQueryItem(name: "dataBroker", value: dataBrokerURL),
            URLQueryItem(name: "attemptId", value: attemptId.uuidString)
        ]

        guard let url = urlComponents?.url else {
            throw EmailError.cantGenerateURL
        }

        var request = URLRequest(url: url)
        guard let authHeader = await authenticationManager.getAuthHeader() else {
            servicePixel.fireEmptyAccessToken(callSite: .getEmail)
            throw AuthenticationError.noAuthToken
        }

        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTPResponse(response)

        do {
            let emailData = try JSONDecoder().decode(EmailData.self, from: data)
            Logger.service.log("✉️ [EmailService] Successfully generated email: \(emailData.emailAddress, privacy: .public)")
            return emailData
        } catch {
            Logger.service.error("✉️ [EmailService] Failed to decode email data: \(error, privacy: .public)")
            throw EmailError.cantFindEmail
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                servicePixel.fireGenerateEmailHTTPError(statusCode: httpResponse.statusCode)
                throw EmailError.httpError(statusCode: httpResponse.statusCode)
            }
        } else {
            servicePixel.fireGenerateEmailHTTPError(statusCode: 0)
            throw EmailError.unknownHTTPError
        }
    }
}

extension EmailError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cantGenerateURL:
            return "Unable to generate URL"
        case .cantFindEmail:
            return "Unable to find email"
        case .invalidEmailLink:
            return "Invalid email confirmation link"
        case .cancelled:
            return "Email operation cancelled"
        case .httpError(let statusCode):
            return "Email HTTP error \(statusCode)"
        case .unknownHTTPError:
            return "Unknown email HTTP error"
        case .extractionError:
            return "Email extraction error"
        case .requestError:
            return "Email request error"
        case .serverError:
            return "Email server error"
        case .retriesExceeded:
            return "Email retries exceeded"
        }
    }
}
