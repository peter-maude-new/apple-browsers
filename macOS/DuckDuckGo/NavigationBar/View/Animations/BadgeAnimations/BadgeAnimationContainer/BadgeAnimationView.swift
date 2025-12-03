//
//  BadgeAnimationView.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import DesignResourcesKit

struct BadgeAnimationView: View {
    var animationModel: BadgeNotificationAnimationModel
    let iconView: AnyView
    @State var text: String
    let eventCount: Int
    let textGenerator: ((Int) -> String)?
    @State var textOffset: CGFloat = 0

    init(animationModel: BadgeNotificationAnimationModel,
         iconView: AnyView,
         text: String,
         eventCount: Int = 0,
         textGenerator: ((Int) -> String)? = nil) {
        self.animationModel = animationModel
        self.iconView = iconView
        self.eventCount = eventCount
        self.textGenerator = textGenerator

        // Only animate counting for 5+ trackers
        // For counts < 5, show the final count immediately
        if eventCount >= AnimationParameters.minimumCountForAnimation, let generator = textGenerator {
            let startingCount = max(1, Int(ceil(Double(eventCount) * AnimationParameters.startPercent)))
            _text = State(initialValue: generator(startingCount))
        } else {
            _text = State(initialValue: text)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ExpandableRectangle(animationModel: animationModel)
                .frame(width: geometry.size.width, height: geometry.size.height)

                HStack {
                    Text(text)
                        .foregroundColor(.primary)
                        .font(.body)
                        .offset(x: textOffset)
                        .onReceive(animationModel.$state, perform: { state in
                            switch state {
                            case .expanded:
                                withAnimation(.easeInOut(duration: animationModel.duration)) {
                                    textOffset = 0
                                }
                                // Start counting animation only for 5+ trackers
                                if eventCount >= AnimationParameters.minimumCountForAnimation {
                                    animateCount()
                                }
                            case .retracted:
                                withAnimation(.easeInOut(duration: animationModel.duration)) {
                                    textOffset = -textWidth - Consts.View.textOffsetMargin
                                }
                            default:
                                break
                            }
                        })
                        .padding(.leading, geometry.size.height)

                    Spacer()
                }.clipped()
                .onAppear {
                    // Initialize text offset to hide text completely before animation
                    textOffset = -textWidth - Consts.View.textOffsetMargin
                }

                // Opaque view
                HStack {
                    Rectangle()
                        .foregroundColor(Consts.Colors.badgeBackgroundColor)
                        .cornerRadius(Consts.View.cornerRadius)
                        .frame(width: geometry.size.height - Consts.View.opaqueViewOffset, height: geometry.size.height)
                    Spacer()
                }

                HStack {
                    iconView
                        .frame(width: geometry.size.height, height: geometry.size.height)
                    Spacer()
                }
            }
        }.frame(width: viewWidth)
    }

    private var textWidth: CGFloat {
        text.width(withFont: NSFont.preferredFont(forTextStyle: .body))
    }

    /// Width based on final text when animation crosses digit boundaries (e.g., 5 -> 10)
    private var finalTextWidth: CGFloat {
        guard let generator = textGenerator,
              eventCount >= AnimationParameters.minimumCountForAnimation else {
            return textWidth
        }

        // Only use final text width when animation crosses from single to double digits
        let startingCount = max(1, Int(ceil(Double(eventCount) * AnimationParameters.startPercent)))
        let crossesDigitBoundary = startingCount < 10 && eventCount >= 10

        if crossesDigitBoundary {
            // Add small buffer for digit transition
            return generator(eventCount).width(withFont: NSFont.preferredFont(forTextStyle: .body)) + 4
        }
        return textWidth
    }

    private var viewWidth: CGFloat {
        let iconSize: CGFloat = 32
        let margins: CGFloat = 8

        return finalTextWidth + iconSize + margins
    }

    // MARK: - Counting Animation

    /// Animates the count from 50% to 100% over 1.75s with quartic easeOut
    /// Only animates for counts >= 5
    private func animateCount() {
        guard eventCount >= AnimationParameters.minimumCountForAnimation, let generator = textGenerator else { return }

        let totalDuration = AnimationParameters.totalDuration
        let startPercent = AnimationParameters.startPercent

        // Calculate steps based on the range we're animating
        let animationRange = Int(ceil(Double(eventCount) * (1.0 - startPercent)))
        // Use 3-4 steps per number for smooth progression
        let steps = max(AnimationParameters.steps, min(animationRange * AnimationParameters.rangeMultiplier, AnimationParameters.stepsPerNumber))

        for i in 1...steps {
            // Use linear timing for delays, but ease the count progression
            let progress = Double(i) / Double(steps)
            let delay = progress * totalDuration

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                let easedProgress = easeOut(progress)
                // Interpolate from 50% to 100% of eventCount
                let countProgress = startPercent + (easedProgress * (1.0 - startPercent))
                let exactCount = Double(self.eventCount) * countProgress

                // Use min() to ensure we show the final count on the last step
                let currentCount = min(Int(floor(exactCount)), self.eventCount)

                // Use textGenerator for proper localization
                self.text = generator(currentCount)
            }
        }
    }

    /// Standard quartic easeOut curve (power of 4)
    /// Formula: 1 - pow(1 - t, 4)
    private func easeOut(_ t: Double) -> Double {
        return 1 - pow(1 - t, AnimationParameters.easeOutCurve)
    }
}

// MARK: - Animation Parameters

private enum AnimationParameters {
    static let minimumCountForAnimation: Int = 5  // Only animate for 5+ trackers
    static let startPercent: Double = 0.5  // Start at 50% of total count
    static let stepsPerNumber: Int = 30    // Maximum steps
    static let steps: Int = 10             // Minimum steps
    static let rangeMultiplier: Int = 3    // Steps per number in range
    static let easeOutCurve: Double = 4    // Quartic easeOut curve
    static let totalDuration: TimeInterval = 1.75  // Total animation duration
}

struct ExpandableRectangle: View {
    @ObservedObject var animationModel: BadgeNotificationAnimationModel
    @State var width: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Consts.Colors.badgeBackgroundColor)
                .cornerRadius(Consts.View.cornerRadius)
                .frame(width: geometry.size.height + width, height: geometry.size.height)
                .onReceive(animationModel.$state, perform: { state in
                    switch state {
                    case .expanded:
                        withAnimation(.easeInOut(duration: animationModel.duration)) {
                            width = geometry.size.width - geometry.size.height
                        }

                    case .retracted:
                        withAnimation(.easeInOut(duration: animationModel.duration)) {
                                width = 0
                        }
                    default:
                        break
                    }
                })
        }
    }
}

struct BadgeAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        BadgeAnimationView(
            animationModel: BadgeNotificationAnimationModel(),
            iconView: AnyView(Image(systemName: "globe")),
            text: "Test",
            eventCount: 0,
            textGenerator: nil
        )
        .frame(width: 100, height: 30)
    }
}

private enum Consts {
    enum View {
        static let cornerRadius: CGFloat = 12
        static let opaqueViewOffset: CGFloat = 8
        static let textOffsetMargin: CGFloat = 10
    }

    enum Colors {
        static let badgeBackgroundColor = Color(designSystemColor: .surfacePrimary)
    }
}

private extension String {
    func width(withFont font: NSFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes).width
    }
}
