//
//  PopoverMessageViewModel.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import SwiftUI

public final class PopoverMessageViewModel: ObservableObject {
    @Published var title: String?
    @Published var message: String
    @Published var image: NSImage?
    @Published var buttonText: String?
    @Published public var buttonAction: (() -> Void)?
    @Published var maxWidth: CGFloat?
    var shouldShowCloseButton: Bool
    var shouldPresentMultiline: Bool
    
    public var closePopover: (() -> Void)?

    public init(title: String?,
                message: String,
                image: NSImage? = nil,
                buttonText: String? = nil,
                buttonAction: (() -> Void)? = nil,
                shouldShowCloseButton: Bool = false,
                shouldPresentMultiline: Bool = true,
                maxWidth: CGFloat? = nil,
                closePopover: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.image = image
        self.buttonText = buttonText
        self.buttonAction = buttonAction
        self.shouldShowCloseButton = shouldShowCloseButton
        self.shouldPresentMultiline = shouldPresentMultiline
        self.maxWidth = maxWidth
        self.closePopover = closePopover
    }
}
