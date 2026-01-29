//
//  TabLockOverlayContent.swift
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

import SwiftUI
import AppKit

// MARK: - ViewModel

@MainActor
final class TabLockOverlayViewModel: ObservableObject {
    @Published var isVisible = false
    @Published var shouldAnimateBounce = false
    var onUnlockRequested: (() -> Void)?

    func animateIn() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = true
        } else {
            shouldAnimateBounce = true
            withAnimation(.easeIn(duration: 0.36)) {
                isVisible = true
            }
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = false
            completion()
        } else {
            withAnimation(.easeIn(duration: 0.6)) {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                completion()
            }
        }
    }

    func showImmediately() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shouldAnimateBounce = false
            isVisible = true
        }
    }

    func hideImmediately() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isVisible = false
        }
    }
}

// MARK: - SwiftUI View

struct TabLockOverlayContent: View {
    @ObservedObject var viewModel: TabLockOverlayViewModel

    @State private var blob1Rotation: Double = .random(in: 0..<360)
    @State private var blob2Rotation: Double = .random(in: 0..<360)
    @State private var blob3Rotation: Double = .random(in: 0..<360)
    @State private var panelBounceOffset: CGFloat = 0

    private let baseAnimation = Animation.easeOut(duration: 0.72)
    private let blobAnimation = Animation.easeOut(duration: 0.7).delay(0.1)
    private let contentAnimation = Animation.easeOut(duration: 0.36).delay(0.5)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectView(material: .fullScreenUI, blendingMode: .behindWindow)

                leftPanelView
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: viewModel.isVisible
                        ? -geometry.size.width * 0.25 - panelBounceOffset
                        : -geometry.size.width)

                rightPanelView
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: viewModel.isVisible
                        ? geometry.size.width * 0.25 + panelBounceOffset
                        : geometry.size.width)

                centerContent
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.onUnlockRequested?()
            }
        }
        .onAppear {
            startBlobRotations()
        }
        .onChange(of: viewModel.isVisible) { isVisible in
            guard isVisible else {
                panelBounceOffset = 0
                return
            }
            guard viewModel.shouldAnimateBounce else { return }
            guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

            // Phase 2: Bounce outward (after 360ms slam)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                withAnimation(.easeOut(duration: 0.12)) {
                    panelBounceOffset = 10
                }
            }
            // Phase 3: Settle back (after 480ms)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    panelBounceOffset = 0
                }
            }
        }
    }

    // MARK: - Subviews

    private var leftPanelView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.949, green: 0.949, blue: 0.949), // #F2F2F2
                Color(red: 0.878, green: 0.878, blue: 0.878)  // #E0E0E0
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Rectangle()
                .frame(width: 1.5)
                .foregroundColor(Color.black.opacity(0.09)),
            alignment: .trailing
        )
        .frame(maxHeight: .infinity)
    }

    private var rightPanelView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.949, green: 0.949, blue: 0.949), // #F2F2F2
                Color(red: 0.878, green: 0.878, blue: 0.878)  // #E0E0E0
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Rectangle()
                .frame(width: 1.5)
                .foregroundColor(Color.white.opacity(0.5)),
            alignment: .leading
        )
        .frame(maxHeight: .infinity)
    }

    private var centerContent: some View {
        ZStack {
            // Blobs BEHIND base (z-order: first = back)
            blobView(imageName: "TabLock-Blob1", rotation: blob1Rotation, size: 210)
            blobView(imageName: "TabLock-Blob2", rotation: blob2Rotation, size: 206)
            blobView(imageName: "TabLock-Blob3", rotation: blob3Rotation, size: 204)

            // Base circle - dark gradient with white border (drawn, not image)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.2, opacity: 0.9),
                            Color(white: 0.1, opacity: 0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 198, height: 198)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .scaleEffect(viewModel.isVisible ? 1 : 0.3)
                .opacity(viewModel.isVisible ? 1 : 0)
                .animation(baseAnimation, value: viewModel.isVisible)

            // Lock icon and label - on top
            VStack(spacing: 12) {
                Image("TabLock-Illus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 118, height: 68)

                Text(UserText.tabLockClickToUnlock)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .opacity(viewModel.isVisible ? 1 : 0)
            .offset(y: viewModel.isVisible ? 0 : 16)
            .animation(contentAnimation, value: viewModel.isVisible)
        }
    }

    private func blobView(imageName: String, rotation: Double, size: CGFloat) -> some View {
        Image(imageName)
            .resizable()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(viewModel.isVisible ? 1 : 0.3)
            .opacity(viewModel.isVisible ? 1 : 0)
            .animation(blobAnimation, value: viewModel.isVisible)
    }

    // MARK: - Blob Rotations

    private func startBlobRotations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            blob1Rotation += 360
        }
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            blob2Rotation -= 360
        }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            blob3Rotation += 360
        }
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

