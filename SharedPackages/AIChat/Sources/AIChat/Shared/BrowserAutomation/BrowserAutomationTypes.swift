//
//  BrowserAutomationTypes.swift
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

import Foundation

// MARK: - Request Types

/// Parameters for taking a screenshot
public struct BrowserScreenshotParams: Codable, Equatable {
    public let rect: BrowserRect?
    /// Optional tab handle. If provided, the screenshot is taken from that tab's webview.
    /// If nil, uses the currently active tab.
    public let handle: String?

    public init(rect: BrowserRect? = nil, handle: String? = nil) {
        self.rect = rect
        self.handle = handle
    }
}

/// Rectangle specification for screenshots
public struct BrowserRect: Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Parameters for switching to a tab
public struct BrowserSwitchTabParams: Codable, Equatable {
    public let handle: String

    public init(handle: String) {
        self.handle = handle
    }
}

/// Parameters for creating a new tab
public struct BrowserNewTabParams: Codable, Equatable {
    public let url: String?
    public let hidden: Bool?

    public init(url: String? = nil, hidden: Bool? = nil) {
        self.url = url
        self.hidden = hidden
    }
}

/// Parameters for closing a tab
public struct BrowserCloseTabParams: Codable, Equatable {
    public let handle: String?

    public init(handle: String? = nil) {
        self.handle = handle
    }
}

/// Parameters for hiding or showing a tab
public struct BrowserSetTabHiddenParams: Codable, Equatable {
    public let handle: String
    public let hidden: Bool

    public init(handle: String, hidden: Bool) {
        self.handle = handle
        self.hidden = hidden
    }
}

/// Parameters for clicking an element
public struct BrowserClickParams: Codable, Equatable {
    public let selector: String?
    public let x: Double?
    public let y: Double?
    /// Optional tab handle. If provided, the click is performed in that tab's webview.
    /// If nil, uses the currently active tab.
    public let handle: String?

    public init(selector: String? = nil, x: Double? = nil, y: Double? = nil, handle: String? = nil) {
        self.selector = selector
        self.x = x
        self.y = y
        self.handle = handle
    }
}

/// Parameters for typing text
public struct BrowserTypeParams: Codable, Equatable {
    public let selector: String
    public let text: String
    public let clear: Bool?
    /// Optional tab handle. If provided, typing is performed in that tab's webview.
    /// If nil, uses the currently active tab.
    public let handle: String?

    public init(selector: String, text: String, clear: Bool? = nil, handle: String? = nil) {
        self.selector = selector
        self.text = text
        self.clear = clear
        self.handle = handle
    }
}

/// Parameters for getting HTML
public struct BrowserGetHTMLParams: Codable, Equatable {
    public let selector: String?
    public let outerHTML: Bool?
    /// Optional tab handle. If provided, HTML is retrieved from that tab's webview.
    /// If nil, uses the currently active tab.
    public let handle: String?

    public init(selector: String? = nil, outerHTML: Bool? = nil, handle: String? = nil) {
        self.selector = selector
        self.outerHTML = outerHTML
        self.handle = handle
    }
}

/// Parameters for navigation
public struct BrowserNavigateParams: Codable, Equatable {
    public let url: String
    /// Optional tab handle. If provided, navigation occurs in that tab.
    /// If nil, uses the currently active tab.
    public let handle: String?

    public init(url: String, handle: String? = nil) {
        self.url = url
        self.handle = handle
    }
}

// MARK: - Response Types

/// Response for screenshot capture
public struct BrowserScreenshotResponse: Codable, Equatable {
    public let base64Image: String
    public let mimeType: String
    public let width: Int
    public let height: Int

    public init(base64Image: String, mimeType: String = "image/png", width: Int, height: Int) {
        self.base64Image = base64Image
        self.mimeType = mimeType
        self.width = width
        self.height = height
    }
}

/// Tab information returned from browser automation
public struct BrowserTabInfo: Codable, Equatable {
    public let handle: String
    public let url: String?
    public let title: String?
    public let active: Bool
    public let hidden: Bool

    public init(handle: String, url: String? = nil, title: String? = nil, active: Bool = false, hidden: Bool = false) {
        self.handle = handle
        self.url = url
        self.title = title
        self.active = active
        self.hidden = hidden
    }
}

/// Response for getting all tabs
public struct BrowserGetTabsResponse: Codable, Equatable {
    public let tabs: [BrowserTabInfo]

    public init(tabs: [BrowserTabInfo]) {
        self.tabs = tabs
    }
}

/// Response for operations that return success status
public struct BrowserSuccessResponse: Codable, Equatable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }
}

/// Response for switch tab operations
public struct BrowserSwitchTabResponse: Codable, Equatable {
    public let success: Bool
    public let tab: BrowserTabInfo?

    public init(success: Bool, tab: BrowserTabInfo? = nil) {
        self.success = success
        self.tab = tab
    }
}

/// Response for navigate operations
public struct BrowserNavigateResponse: Codable, Equatable {
    public let success: Bool
    public let url: String
    public let title: String?

    public init(success: Bool, url: String, title: String? = nil) {
        self.success = success
        self.url = url
        self.title = title
    }
}

/// Response for creating a new tab
public struct BrowserNewTabResponse: Codable, Equatable {
    public let handle: String
    public let hidden: Bool?

    public init(handle: String, hidden: Bool? = nil) {
        self.handle = handle
        self.hidden = hidden
    }
}

/// Response for click operations
public struct BrowserClickResponse: Codable, Equatable {
    public let success: Bool
    public let element: BrowserElementInfo?

    public init(success: Bool, element: BrowserElementInfo? = nil) {
        self.success = success
        self.element = element
    }
}

/// Information about a clicked element
public struct BrowserElementInfo: Codable, Equatable {
    public let tagName: String
    public let text: String?

    public init(tagName: String, text: String? = nil) {
        self.tagName = tagName
        self.text = text
    }
}

/// Response for getting HTML
public struct BrowserGetHTMLResponse: Codable, Equatable {
    public let html: String
    public let url: String
    public let title: String

    public init(html: String, url: String, title: String) {
        self.html = html
        self.url = url
        self.title = title
    }
}
