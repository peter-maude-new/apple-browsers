//
//  AIChatDeleteOperation.swift
//  DuckDuckGo
//
//  Created for integrating AI Chat deletion into Sync operations.
//

import DDGSync
import Foundation

final class AIChatDeleteOperation: SyncCustomOperation {

    private weak var cleaner: (any SyncAIChatsCleaning)?

    init(cleaner: any SyncAIChatsCleaning) {
        self.cleaner = cleaner
    }

    func run() async throws {
        await cleaner?.deleteIfNeeded()
    }
}
