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
    #if DEBUG
    let animationSpeed: Double = 1.0  // 5x slower for debugging
    #else
    let animationSpeed: Double = 1.0
    #endif

    @Published var isVisible = false
    @Published var baseVisible = false
    @Published var blobsVisible = false
    @Published var contentVisible = false
    @Published var shouldAnimateBounce = false
    @Published var shouldAnimateOutBounce = false
    var onUnlockRequested: (() -> Void)?
    var onViewReady: (() -> Void)?

    func animateIn(completion: (() -> Void)? = nil) {
        print("[LOCK DEBUG] animateIn called, isVisible=\(isVisible), shouldAnimateBounce=\(shouldAnimateBounce)")
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = true
            baseVisible = true
            blobsVisible = true
            contentVisible = true
            completion?()
        } else {
            shouldAnimateBounce = true
            withAnimation(.easeOut(duration: 0.6 / animationSpeed)) {
                isVisible = true
            }
            // Base expands at t=0 (720ms, easeOutBack via spring)
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15).speed(1.0 / animationSpeed)) {
                baseVisible = true
            }
            // Blobs expand at t=100ms (792ms, easeOutBack via spring)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 / animationSpeed) {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 15).speed(1.0 / self.animationSpeed)) {
                    self.blobsVisible = true
                }
            }
            // Content fades in at t=504ms (360ms, easeOut)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.504 / animationSpeed) {
                withAnimation(.easeOut(duration: 0.36 / self.animationSpeed)) {
                    self.contentVisible = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.84 / animationSpeed) {
                completion?()
            }
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        print("[LOCK DEBUG] animateOut called, isVisible=\(isVisible)")
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = false
            baseVisible = false
            blobsVisible = false
            contentVisible = false
            completion()
        } else {
            // Content fades at t=0 (150ms, easeIn)
            withAnimation(.easeIn(duration: 0.15 / animationSpeed)) {
                contentVisible = false
            }
            // Blobs shrink at t=90ms (300ms, easeIn)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09 / animationSpeed) {
                withAnimation(.easeIn(duration: 0.3 / self.animationSpeed)) {
                    self.blobsVisible = false
                }
            }
            // Base shrinks at t=180ms (600ms, easeIn)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18 / animationSpeed) {
                withAnimation(.easeIn(duration: 0.6 / self.animationSpeed)) {
                    self.baseVisible = false
                }
            }
            // Panels slide at t=180ms (600ms, easeOut)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18 / animationSpeed) {
                withAnimation(.easeOut(duration: 0.6 / self.animationSpeed)) {
                    self.isVisible = false
                }
            }
            // Complete at t=780ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.78 / animationSpeed) {
                completion()
            }
        }
    }

    func showImmediately() {
        print("[LOCK DEBUG] showImmediately called")
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shouldAnimateBounce = false
            isVisible = true
            baseVisible = true
            blobsVisible = true
            contentVisible = true
        }
    }

    func hideImmediately() {
        print("[LOCK DEBUG] hideImmediately called")
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isVisible = false
            baseVisible = false
            blobsVisible = false
            contentVisible = false
        }
    }
}

// MARK: - SwiftUI View

struct TabLockOverlayContent: View {
    // Blob sizes from CSS: Blob1=200×218, Blob2=207×204, Blob3=196×211, BlackCircle=198
    // Use half of tallest dimension (Blob1 height=218) to ensure all blobs are hidden when retracted
    private let lockCircleRadius: CGFloat = 109  // 218 / 2

    @ObservedObject var viewModel: TabLockOverlayViewModel

    @State private var blob1Rotation: Double = .random(in: 0..<360)
    @State private var blob2Rotation: Double = .random(in: 0..<360)
    @State private var blob3Rotation: Double = .random(in: 0..<360)
    @State private var panelBounceOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = geometry.size.width * 0.5
            let visibleOffset = panelWidth / 2  // 0.25w - positions panel edge at center
            let hiddenOffset = visibleOffset + panelWidth + lockCircleRadius  // 0.75w + 105

            ZStack {
                Color.clear
                rightPanelView
                    .frame(width: panelWidth)
                    .offset(x: viewModel.isVisible
                        ? visibleOffset + panelBounceOffset
                        : hiddenOffset)

                ZStack {
                    leftPanelView
                    centerContent
                        .offset(x: visibleOffset)
                }
                .frame(width: panelWidth)
                .offset(x: viewModel.isVisible
                    ? -visibleOffset - panelBounceOffset
                    : -hiddenOffset)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.onUnlockRequested?()
            }
        }
        .onAppear {
            startBlobRotations()
            viewModel.onViewReady?()
        }
        .onChange(of: viewModel.isVisible) { isVisible in
            print("[LOCK DEBUG] onChange fired, isVisible=\(isVisible)")
            if isVisible {
                // Bounce animation (only if animated lock)
                guard viewModel.shouldAnimateBounce else { return }
                guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 / viewModel.animationSpeed) {
                    withAnimation(.easeOut(duration: 0.12 / self.viewModel.animationSpeed)) {
                        panelBounceOffset = 10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.72 / viewModel.animationSpeed) {
                    withAnimation(.easeInOut(duration: 0.12 / self.viewModel.animationSpeed)) {
                        panelBounceOffset = 0
                    }
                }
            } else {
                panelBounceOffset = 0
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
            // Each blob has darken blend mode applied individually (matches CSS reference)
            Group {
                blobView(imageName: "TabLock-Blob1", rotation: blob1Rotation, width: 200, height: 218)
                blobView(imageName: "TabLock-Blob2", rotation: blob2Rotation, width: 207, height: 204)
                blobView(imageName: "TabLock-Blob3", rotation: blob3Rotation, width: 196, height: 211)
            }

            // Base circle with lock icon nested inside
            ZStack {
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

                VStack(spacing: 12) {
                    Image("TabLock-Illus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 118, height: 68)

                    Text(UserText.tabLockClickToUnlock)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .opacity(viewModel.contentVisible ? 1 : 0)
                .offset(y: viewModel.contentVisible ? 0 : 16)
            }
            .scaleEffect(viewModel.baseVisible ? 1 : 0.3)
        }
    }

    private func blobView(imageName: String, rotation: Double, width: CGFloat, height: CGFloat) -> some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
            .blendMode(.darken)
            .scaleEffect(viewModel.blobsVisible ? 1 : 0.3)
            .opacity(viewModel.blobsVisible ? 1 : 0)
    }

    // MARK: - Blob Rotations

    private func startBlobRotations() {
        withAnimation(.linear(duration: 20 / viewModel.animationSpeed).repeatForever(autoreverses: false)) {
            blob1Rotation += 360
        }
        withAnimation(.linear(duration: 25 / viewModel.animationSpeed).repeatForever(autoreverses: false)) {
            blob2Rotation -= 360
        }
        withAnimation(.linear(duration: 30 / viewModel.animationSpeed).repeatForever(autoreverses: false)) {
            blob3Rotation += 360
        }
    }
}

