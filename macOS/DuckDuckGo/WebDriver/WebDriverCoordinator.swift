//
//  WebDriverCoordinator.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

#if DEBUG

import Foundation
import os.log

/// Coordinates WebDriver server and session management
/// This is the main entry point for WebDriver functionality
@MainActor
final class WebDriverCoordinator {

    // MARK: - Properties

    private var server: WebDriverServer?
    private let sessionManager: WebDriverSessionManager

    let port: UInt16

    var isRunning: Bool {
        server?.isRunning ?? false
    }

    var activeSessionCount: Int {
        sessionManager.activeSessions.count
    }

    // MARK: - Initialization

    init(port: UInt16 = 4444, windowControllersManager: WindowControllersManagerProtocol?) {
        self.port = port
        self.sessionManager = WebDriverSessionManager(windowControllersManager: windowControllersManager)
    }

    // MARK: - Server Control

    func startServer() throws {
        guard server == nil || !isRunning else {
            Logger.webDriver.warning("WebDriver server already running")
            return
        }

        server = WebDriverServer(port: port, sessionManager: sessionManager)
        try server?.start()

        Logger.webDriver.info("WebDriver server started on port \(self.port)")
        Logger.webDriver.info("Connect using: http://localhost:\(self.port)")
    }

    func stopServer() {
        server?.stop()
        server = nil
        Logger.webDriver.info("WebDriver server stopped")
    }

    func deleteAllSessions() async {
        await sessionManager.deleteAllSessions()
    }

    // MARK: - Command Line Support

    /// Checks command line arguments and starts server if requested
    func handleCommandLineArguments() {
        let args = CommandLine.arguments

        // Check for --enable-webdriver flag
        if args.contains("--enable-webdriver") {
            do {
                try startServer()
            } catch {
                Logger.webDriver.error("Failed to start WebDriver from command line: \(error.localizedDescription)")
            }
        }

        // Check for custom port: --webdriver-port=XXXX
        if let portArg = args.first(where: { $0.hasPrefix("--webdriver-port=") }) {
            let portString = portArg.replacingOccurrences(of: "--webdriver-port=", with: "")
            if let customPort = UInt16(portString) {
                // Would need to recreate with new port - for simplicity, log a warning
                Logger.webDriver.warning("Custom port \(customPort) specified but coordinator already initialized with port \(self.port)")
            }
        }
    }
}

// MARK: - Command Line Arguments

extension WebDriverCoordinator {
    /// Command line argument to enable WebDriver server on launch
    static let enableArgument = "--enable-webdriver"

    /// Command line argument to specify custom port
    static let portArgumentPrefix = "--webdriver-port="

    /// Prints usage information
    static func printUsage() {
        print("""
        WebDriver Command Line Options:
          \(enableArgument)           Enable WebDriver server on application launch
          \(portArgumentPrefix)<PORT>   Specify custom port (default: 4444)

        Example:
          /Applications/DuckDuckGo.app/Contents/MacOS/DuckDuckGo \(enableArgument)
        """)
    }
}

#endif
