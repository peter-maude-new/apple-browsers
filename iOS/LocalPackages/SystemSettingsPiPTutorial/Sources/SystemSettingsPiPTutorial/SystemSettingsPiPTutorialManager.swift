//
//  SystemSettingsPiPTutorialManager.swift
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

import AVFoundation
import AVKit
import Combine

/// Manages PiP tutorial playback and navigation within system settings.
///
/// This class coordinates video playback, URL provider management, and system settings navigation for PiP tutorials.
@MainActor
public final class SystemSettingsPiPTutorialManager {
    public let playerView: UIView
    private let videoPlayer: SystemSettingsPiPTutorialPlayer
    private let pipTutorialURLProvider: SystemSettingsPiPTutorialURLManaging
    private let isFeatureEnabled: () -> Bool
    private let urlOpener: SystemSettingsPiPURLOpener

    private var playerItemStatusCancellable: AnyCancellable?

    /// Creates a new PiP tutorial manager with the specified dependencies.
    ///
    /// - Parameters:
    ///   - playerView: The view that will display the video content.
    ///   - videoPlayer: The player responsible for video playback and PiP functionality.
    ///   - isFeatureEnabled: A closure that returns whether the PiP tutorial feature is currently enabled.
    public convenience init(
        playerView: UIView,
        videoPlayer: SystemSettingsPiPTutorialPlayer,
        isFeatureEnabled: @escaping () -> Bool,
    ) {
        self.init(
            playerView: playerView,
            videoPlayer: videoPlayer,
            pipTutorialURLProvider: SystemSettingsPiPTutorialURLProvider(),
            isFeatureEnabled: isFeatureEnabled,
            urlOpener: UIApplication.shared
        )
    }

    init(
        playerView: UIView,
        videoPlayer: SystemSettingsPiPTutorialPlayer,
        pipTutorialURLProvider: SystemSettingsPiPTutorialURLManaging,
        isFeatureEnabled: @escaping () -> Bool,
        urlOpener: SystemSettingsPiPURLOpener
    ) {
        self.playerView = playerView
        self.videoPlayer = videoPlayer
        self.pipTutorialURLProvider = pipTutorialURLProvider
        self.isFeatureEnabled = isFeatureEnabled
        self.urlOpener = urlOpener
    }
}

// MARK: - Private

private extension SystemSettingsPiPTutorialManager {

    func loadAndPlayPiPTutorialIfEnabled(for destination: SystemSettingsPiPTutorialDestination) {
        // Check if PiP feature is enabled, otherwise only open URL without loading the video.
        guard
            isFeatureEnabled(),
            videoPlayer.isPictureInPictureSupported()
        else {
            urlOpener.open(destination.url)
            return
        }
        
        do {
            let pipTutorialURL = try pipTutorialURLProvider.url(for: destination)

            // Observe status before loading
            playerItemStatusCancellable = videoPlayer.playerItemStatusPublisher
                .receive(on: DispatchQueue.main)
                .filter { $0 == .readyToPlay || $0 == .failed } // We're only interested if the item is ready to play or can't be played.
                .prefix(1) // If video loops `.readyToPlay` is emitted multiple times. We're only interested in the first event when the asset finished loading.
                .sink { [weak self] status in
                    guard let self else { return }
                    switch status {
                    case .readyToPlay:
                        self.videoPlayer.play()
                         Logger.pipTutorial.error("[PiP Tutorial Video] Opening Default Browser Settings")
                        self.urlOpener.open(destination.url)
                    case .failed:
                        Logger.pipTutorial.error("[PiP Tutorial Video] Could not play PiP video. Opening Default Browser Settings")
                        self.urlOpener.open(destination.url)
                    default:
                        break
                    }
                }

            videoPlayer.load(url: pipTutorialURL)

        } catch {
            Logger.pipTutorial.error("[PiP Tutorial Video] Failed to resolve tutorial URL: \(error.localizedDescription). Opening Default Browser Settings")
            urlOpener.open(destination.url)
        }
    }

}

// MARK: - SystemSettingsPiPTutorialProviderRegistering

extension SystemSettingsPiPTutorialManager: SystemSettingsPiPTutorialProviderRegistering {

    public func register(_ provider: PiPTutorialURLProvider, for destination: SystemSettingsPiPTutorialDestination) {
        pipTutorialURLProvider.register(provider, for: destination)
    }
}

// MARK: - SystemSettingsPiPTutorialManaging

extension SystemSettingsPiPTutorialManager: SystemSettingsPiPTutorialManaging {

    public func stopPiPTutorialIfNeeded() {
        // Do not check for feature enabled here as it may be turned off when the video is already playing and we may never stop the video.
        videoPlayer.stop()
    }

    public func playPiPTutorialAndNavigateTo(destination: SystemSettingsPiPTutorialDestination) {
        loadAndPlayPiPTutorialIfEnabled(for: destination)
    }
    
}
