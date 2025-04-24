//
//  SetAsDefaultVideoTutorialView.swift
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

import SwiftUI

struct SetAsDefaultVideoTutorialView: View {
    private static let videoURL = Bundle.main.url(forResource: "set-as-default-browser-tutorial", withExtension: "mp4")!

    @StateObject private var videoPlayerModel = VideoPlayerViewModel(url: Self.videoURL, loopVideo: true)

    var isPlaying: Binding<Bool>
    var isPIPEnabled: Binding<Bool>
    var onPiPStarted: () -> Void

    var body: some View {
        videoPlayer
            .onChange(of: isPIPEnabled.wrappedValue) { newValue in
                if newValue {
                    print("~~~ Starting PIP")
                    videoPlayerModel.startPIP()
                    print("~~~ On PIP Started")
                    onPiPStarted()
                } else {
                    print("~~~ Stopping PIP")
                    stopPIP()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                stopPIP()
            }
    }

    private var videoPlayer: some View {
        return VideoPlayerView(model: videoPlayerModel, isPlaying: isPlaying)
    }

    private func startPIP() {
        videoPlayerModel.startPIP()
    }

    private func stopPIP() {
        videoPlayerModel.stopPIP()
        isPlaying.wrappedValue = false
        isPIPEnabled.wrappedValue = false
    }
}

#Preview {
    SetAsDefaultVideoTutorialView(isPlaying: .constant(true), isPIPEnabled: .constant(false), onPiPStarted: {})
}

