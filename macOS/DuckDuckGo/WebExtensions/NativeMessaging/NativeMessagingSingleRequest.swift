//
//  NativeMessagingSingleRequest.swift
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
import WebKit

@available(macOS 15.4, *)
final class NativeMessagingSingleRequest {

    enum ConnectionError: Error {
        case disconnected
    }

    private let appPath: String
    private let arguments: [String]
    private let timeout: TimeInterval

    init(appPath: String, arguments: [String], timeout: TimeInterval = 30.0) {
        self.appPath = appPath
        self.arguments = arguments
        self.timeout = timeout
    }

    func send(messageData: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let lock = NSLock()

            let connection = NativeMessagingConnection(
                appPath: appPath,
                arguments: arguments,
                messageHandler: { data in
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: data)
                    }
                },
                disconnectHandler: { error in
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error ?? ConnectionError.disconnected)
                    }
                }
            )

            do {
                try connection.runProxyProcess()
                try connection.send(messageData: messageData)
            } catch {
                lock.lock()
                defer { lock.unlock() }
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
