//
//  DaxEasterEggLogoCache.swift
//  DuckDuckGo
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
import os.log
import UserScript
import WebKit

/// Protocol for caching DaxEasterEgg logos
protocol DaxEasterEggLogoCaching {
    /// Store a logo URL for the given search query
    func storeLogo(_ logoURL: String, for searchQuery: String)
    
    /// Retrieve a cached logo URL for the given search query
    func getLogo(for searchQuery: String) -> String?
}

/// In-memory cache for DaxEasterEgg logos, mapping search queries to logo URLs.
final class DaxEasterEggLogoCache: DaxEasterEggLogoCaching {
    
    // MARK: - Properties
    
    /// Thread-safe cache storage: searchQuery (lowercased) → logoURL (absolute)
    private var logoCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "dax-easter-egg-logo-cache", attributes: .concurrent)
    private let maxCacheSize = 100 // Prevent memory bloat
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Store a logo URL for the given search query
    /// - Parameters:
    ///   - logoURL: The processed, absolute logo URL
    ///   - searchQuery: The raw search query from the URL
    func storeLogo(_ logoURL: String, for searchQuery: String) {
        let normalizedQuery = normalize(query: searchQuery)
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Simple size management - clear cache if it gets too large
            if self.logoCache.count >= self.maxCacheSize {
                self.logoCache.removeAll()
                Logger.daxEasterEgg.debug("DaxEasterEggLogoCache: Cache cleared due to size limit")
            }
            
            self.logoCache[normalizedQuery] = logoURL
            Logger.daxEasterEgg.debug("DaxEasterEggLogoCache: Stored logo for query '\(normalizedQuery)' -> \(logoURL)")
        }
    }
    
    /// Retrieve a cached logo URL for the given search query
    /// - Parameter searchQuery: The raw search query from the URL
    /// - Returns: The cached logo URL if found, nil otherwise
    func getLogo(for searchQuery: String) -> String? {
        let normalizedQuery = normalize(query: searchQuery)
        
        return cacheQueue.sync {
            let logoURL = logoCache[normalizedQuery]
            if let logoURL = logoURL {
                Logger.daxEasterEgg.debug("DaxEasterEggLogoCache: Cache HIT for query '\(normalizedQuery)' -> \(logoURL)")
            } else {
                Logger.daxEasterEgg.debug("DaxEasterEggLogoCache: Cache MISS for query '\(normalizedQuery)'")
            }
            return logoURL
        }
    }
    
    // MARK: - Private Methods
    
    /// Normalize search query for consistent cache keys
    /// - Parameter query: Raw search query
    /// - Returns: Normalized cache key (lowercased, trimmed)
    private func normalize(query: String) -> String {
        return query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Content Scope Scripts integration

final class DaxEasterEggLogosSubfeature: Subfeature {

    typealias UpdateHandler = (_ logoURL: String?, _ pageURL: String) -> Void

    private enum Methods {
        static let logoUpdate = "logoUpdate"
    }

    var messageOriginPolicy: MessageOriginPolicy = .only(rules: [
        .exact(hostname: "duckduckgo.com")
    ])

    var featureName: String = "daxEasterEggLogos"
    weak var broker: UserScriptMessageBroker?

    private let onUpdate: UpdateHandler

    init(onUpdate: @escaping UpdateHandler) {
        self.onUpdate = onUpdate
    }

    func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    func handler(forMethodNamed methodName: String) -> Handler? {
        guard methodName == Methods.logoUpdate else { return nil }
        return logoUpdate
    }

    @MainActor
    private func logoUpdate(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let dict = params as? [String: Any],
              let pageURL = dict["pageURL"] as? String else {
            return nil
        }

        let logoURL: String?
        switch dict["logoURL"] {
        case let s as String:
            logoURL = s
        default:
            logoURL = nil
        }

        onUpdate(logoURL, pageURL)
        return nil
    }
}
