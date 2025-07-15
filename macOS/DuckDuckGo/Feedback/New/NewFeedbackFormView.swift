//
//  NewFeedbackFormView.swift
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

final class NewFeedbackFormViewController: NSHostingController<NewFeedbackFormView> {
    override init(rootView: NewFeedbackFormView) {
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct NewFeedbackFormView: View {
    @State private var selectedFeatures: Set<String> = []
    @State private var customFeatureText: String = ""

    let availableFeatures = [
        "Reader mode",
        "Password Manager Extensions",
        "Advanced ad blocking",
        "New tab page widgets",
        "Website Translation",
        "Incognito",
        "User Profiles",
        "Import Bookmarks",
        "Vertical tabs",
        "Picture-in-picture",
        "Cast video/audio",
        "Tab groups"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Request a New Feature")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Feature selection pills
            FlexibleView(
                availableWidth: 400, // Adjust based on your window width
                data: availableFeatures,
                spacing: 8,
                alignment: .leading
            ) { feature in
                FeaturePill(
                    text: feature,
                    isSelected: selectedFeatures.contains(feature)
                ) {
                    toggleFeature(feature)
                }
            }

            // Custom feature input
            VStack(alignment: .leading, spacing: 12) {
                Text("Or share your own feature idea")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextEditor(text: $customFeatureText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if customFeatureText.isEmpty {
                                HStack {
                                    VStack {
                                        HStack {
                                            Text("The more details you share, the better!")
                                                .foregroundColor(.secondary)
                                                .font(.body)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                }
                            }
                        }
                    )
            }

            Spacer()

            // Footer
            VStack(spacing: 16) {
                Text("Reports sent to DuckDuckGo are 100% anonymous and only include your message, the DuckDuckGo browser version, and your macOS version.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Button("Cancel") {
                        // Handle cancel action
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button("Submit") {
                        // Handle submit action
                    }
                    .disabled(selectedFeatures.isEmpty && customFeatureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggleFeature(_ feature: String) {
        if selectedFeatures.contains(feature) {
            selectedFeatures.remove(feature)
        } else {
            selectedFeatures.insert(feature)
        }
    }
}

struct FeaturePill: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color(.separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRowWidth: CGFloat = 0

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]

            if currentRowWidth + elementSize.width + spacing > availableWidth {
                rows.append([element])
                currentRowWidth = elementSize.width
            } else {
                rows[rows.count - 1].append(element)
                currentRowWidth += elementSize.width + spacing
            }
        }

        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

#Preview {
    NewFeedbackFormView()
}
