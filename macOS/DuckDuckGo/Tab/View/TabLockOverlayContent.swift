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
    private let animationSpeed: Double = 0.2  // 5x slower for debugging
    #else
    private let animationSpeed: Double = 1.0
    #endif

    @Published var isVisible = false
    @Published var shouldAnimateBounce = false
    @Published var shouldAnimateOutBounce = false
    var onUnlockRequested: (() -> Void)?
    var onViewReady: (() -> Void)?

    func animateIn(completion: (() -> Void)? = nil) {
        print("[LOCK DEBUG] animateIn called, isVisible=\(isVisible), shouldAnimateBounce=\(shouldAnimateBounce)")
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = true
            completion?()
        } else {
            shouldAnimateBounce = true
            withAnimation(.easeOut(duration: 0.6 / animationSpeed)) {
                isVisible = true
            }
            // Call completion after full animation (0.6s slide + bounce sequence)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.84 / animationSpeed) {
                completion?()
            }
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        print("[LOCK DEBUG] animateOut called, isVisible=\(isVisible)")
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            isVisible = false
            completion()
        } else {
            shouldAnimateOutBounce = true
            // Phase 1: Slide out with easeIn (360ms)
            withAnimation(.easeIn(duration: 0.36 / animationSpeed)) {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 / animationSpeed) {
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
        }
    }

    func hideImmediately() {
        print("[LOCK DEBUG] hideImmediately called")
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isVisible = false
        }
    }
}

// MARK: - SwiftUI View

struct TabLockOverlayContent: View {
    #if DEBUG
    private let animationSpeed: Double = 0.2  // 5x slower for debugging
    #else
    private let animationSpeed: Double = 1.0
    #endif

    @ObservedObject var viewModel: TabLockOverlayViewModel

    @State private var blob1Rotation: Double = .random(in: 0..<360)
    @State private var blob2Rotation: Double = .random(in: 0..<360)
    @State private var blob3Rotation: Double = .random(in: 0..<360)
    @State private var panelBounceOffset: CGFloat = 0
    @State private var showElements = false

    private var baseAnimation: Animation { .easeOut(duration: 0.72 / animationSpeed) }
    private var blobAnimation: Animation { .easeOut(duration: 0.7 / animationSpeed).delay(0.1 / animationSpeed) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                rightPanelView
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: viewModel.isVisible
                        ? geometry.size.width * 0.25 + panelBounceOffset
                        : geometry.size.width)

                ZStack {
                    leftPanelView
                    centerContent
                        .offset(x: geometry.size.width * 0.25)
                }
                .frame(width: geometry.size.width * 0.5)
                .offset(x: viewModel.isVisible
                    ? -geometry.size.width * 0.25 - panelBounceOffset
                    : -geometry.size.width * 1.5)
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
            print("[LOCK DEBUG] onChange fired, isVisible=\(isVisible), shouldAnimateBounce=\(viewModel.shouldAnimateBounce), showElements=\(showElements)")
            if isVisible {
                print("[LOCK DEBUG] Setting showElements to true")
                // Set showElements - with or without animation depending on mode
                if viewModel.shouldAnimateBounce && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    withAnimation(.easeOut(duration: 0.36 / animationSpeed).delay(0.5 / animationSpeed)) {
                        showElements = true
                    }
                } else {
                    // Immediate show or reduce motion - disable animations
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showElements = true
                    }
                }

                // Bounce animation (only if animated mode)
                guard viewModel.shouldAnimateBounce else { return }
                guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

                // Phase 2: Bounce outward (after 600ms slide completes)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 / animationSpeed) {
                    withAnimation(.easeOut(duration: 0.12 / self.animationSpeed)) {
                        panelBounceOffset = 10
                    }
                }
                // Phase 3: Settle back (after 720ms)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.72 / animationSpeed) {
                    withAnimation(.easeInOut(duration: 0.12 / self.animationSpeed)) {
                        panelBounceOffset = 0
                    }
                }
            } else {
                print("[LOCK DEBUG] Setting showElements to false")
                // Animate inner content out with fast easeIn (no delay)
                if viewModel.shouldAnimateOutBounce && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    withAnimation(.easeIn(duration: 0.15 / animationSpeed)) {
                        showElements = false
                    }
                } else {
                    panelBounceOffset = 0
                    showElements = false
                }

                // Unlock bounce animation (panels bounce back toward center as they exit)
                guard viewModel.shouldAnimateOutBounce else { return }
                guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
                viewModel.shouldAnimateOutBounce = false

                // Phase 2: Bounce back toward center (after 360ms slide)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.36 / animationSpeed) {
                    withAnimation(.easeOut(duration: 0.12 / self.animationSpeed)) {
                        panelBounceOffset = -10  // Negative = panels bounce back inward
                    }
                }
                // Phase 3: Settle to final position (after 480ms)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.48 / animationSpeed) {
                    withAnimation(.easeInOut(duration: 0.12 / self.animationSpeed)) {
                        panelBounceOffset = 0
                    }
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
                .opacity(showElements ? 1 : 0)
                .offset(y: showElements ? 0 : 16)
            }
            .scaleEffect(showElements ? 1 : 0.3)
            .opacity(showElements ? 1 : 0)
            .animation(baseAnimation, value: showElements)
        }
    }

    private func blobView(imageName: String, rotation: Double, size: CGFloat) -> some View {
        Image(imageName)
            .resizable()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(showElements ? 1 : 0.3)
            .opacity(showElements ? 1 : 0)
            .animation(blobAnimation, value: showElements)
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

