//
//  FileImportScreenView.swift
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
import BrowserServicesKit

struct FileImportScreenView: View {
    let importSource: DataImport.Source
    let kind: NewFileImportView.Kind
    let summary: DataImportSummary?
    let isSelectFileButtonDisabled: Bool
    let selectFile: () -> Void
    let onFileDrop: (URL) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 20) {
                if let importSourceImage = importSource.importSourceImage {
                    Image(nsImage: importSourceImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                }

                if case .individual(let dataType) = kind, shouldShowErrorView(for: dataType) {
                    let formatText: () -> String = {
                        switch dataType {
                        case .bookmarks:
                            UserText.importBookmarksFromSourceAutomaticError(source: importSource)
                        case .passwords:
                            UserText.importPasswordsFromSourceAutomaticError(source: importSource)
                        case .creditCards:
                            UserText.importBookmarksFromSourceAutomaticError(source: importSource)
                        }
                    }
                    NewImportErrorView(text: formatText())
                }

                Text(UserText.importFromFileTitle(from: importSource))
                    .font(.title2.weight(.semibold))

                NewFileImportView(source: importSource,
                                  allowedFileTypes: kind.supportedFileTypes(for: importSource),
                                  isButtonDisabled: isSelectFileButtonDisabled,
                                  kind: kind) {
                    selectFile()
                } onFileDrop: { url in
                    onFileDrop(url)
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .padding(.top, 20)
        }
    }

    private func shouldShowErrorView(for dataType: DataImport.DataType) -> Bool {
        switch summary?[dataType] {
        case .success(let typeSummary) where typeSummary.successful == 0:
            return true
        case .failure:
            return true
        default:
            return false
        }
    }
}
