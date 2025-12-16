//
//  ActiveDownloadsTerminationDecider.swift
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

import AppKit
import Foundation

/// Decider that checks for active downloads and shows a confirmation dialog if any exist.
@MainActor
struct ActiveDownloadsTerminationDecider: ApplicationTerminationDecider {
    let downloadManager: FileDownloadManagerProtocol
    let downloadListCoordinator: DownloadListCoordinator

    func shouldTerminate(isAsync: Bool) -> TerminationQuery {
        guard !downloadManager.downloads.isEmpty else {
            return .sync(.next)
        }

        // if there're downloads without location chosen yet (save dialog should display) - ignore them
        let activeDownloads = Set(downloadManager.downloads.filter { $0.state.isDownloading })
        guard !activeDownloads.isEmpty else {
            return .sync(.next)
        }

        // If another decider already delayed termination, just cancel downloads without showing alert
        if isAsync {
            return .async(Task { @MainActor in
                await downloadManager.cancelAll()
                downloadListCoordinator.sync()
                return .next
            })
        }

        // Show modal alert in async task
        return .async(Task { @MainActor in
            let alert = NSAlert.activeDownloadsTerminationAlert(for: downloadManager.downloads)

            // Observe downloads finishing to auto-dismiss alert
            let downloadsFinishedCancellable = FileDownloadManager.observeDownloadsFinished(activeDownloads) {
                // Close alert when all downloads finished
                NSApp.stopModal(withCode: .OK)
            }

            // Run modal - this blocks the task but not the termination handler
            let response = await alert.runModal()
            downloadsFinishedCancellable.cancel()

            if response == .cancel {
                return .cancel
            }

            await downloadManager.cancelAll()
            downloadListCoordinator.sync()

            return .next
        })
    }
}
