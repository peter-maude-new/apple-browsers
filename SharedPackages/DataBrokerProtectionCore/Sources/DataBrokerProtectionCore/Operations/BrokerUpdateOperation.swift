//
//  BrokerUpdateOperation.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
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
import BrowserServicesKit

public final class BrokerUpdateOperation: Operation, @unchecked Sendable {

    private let brokerService: BrokerJSONServiceProvider
    private let timeout: TimeInterval

    private let id = UUID()
    private var _isExecuting = false
    private var _isFinished = false

    public init(brokerService: BrokerJSONServiceProvider,
                timeout: TimeInterval = .minutes(5)) {
        self.brokerService = brokerService
        self.timeout = timeout
        super.init()
    }

    public override func start() {
        if isCancelled {
            finish()
            return
        }

        willChangeValue(forKey: #keyPath(isExecuting))
        _isExecuting = true
        didChangeValue(forKey: #keyPath(isExecuting))

        main()
    }

    public override var isAsynchronous: Bool {
        true
    }

    public override var isExecuting: Bool {
        _isExecuting
    }

    public override var isFinished: Bool {
        _isFinished
    }

    public override func main() {
        Task {
            await performUpdate()
            finish()
        }
    }

    private func performUpdate() async {
        // Check if cancelled
        guard !isCancelled else { return }

        do {
            try await withTimeout(timeout) {
                try await self.brokerService.checkForUpdates()
            }
            Logger.dataBrokerProtection.log("🧩 Broker update completed successfully")
        } catch is TimeoutError {
            Logger.dataBrokerProtection.log("🧩 Broker update timed out after \(self.timeout)s")
        } catch {
            Logger.dataBrokerProtection.log("🧩 Broker update failed: \(error)")
        }
    }

    private func finish() {
        willChangeValue(forKey: #keyPath(isExecuting))
        willChangeValue(forKey: #keyPath(isFinished))
        _isExecuting = false
        _isFinished = true
        didChangeValue(forKey: #keyPath(isExecuting))
        didChangeValue(forKey: #keyPath(isFinished))
    }
}
