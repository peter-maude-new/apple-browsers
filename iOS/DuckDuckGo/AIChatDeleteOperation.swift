//
//  AIChatDeleteOperation.swift
//  DuckDuckGo
//
//  Created for integrating AI Chat deletion into Sync operations.
//

import Foundation
import DDGSync

final class AIChatDeleteOperation: SyncCustomOperation {

    private weak var cleaner: (any SyncAIChatsCleaning)?

    init(cleaner: any SyncAIChatsCleaning) {
        self.cleaner = cleaner
    }

    func run() async throws {
        await cleaner?.deleteIfNeeded()
    }
}
