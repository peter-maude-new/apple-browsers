//
//  FaviconUserScriptTests.swift
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

import XCTest
@testable import Core

class FaviconUserScriptTests: XCTestCase {

    private var sut: FaviconUserScript!

    override func setUp() {
        super.setUp()
        sut = FaviconUserScript()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func link(_ href: String, rel: String, type: String? = nil) -> FaviconUserScript.FaviconLink {
        FaviconUserScript.FaviconLink(href: URL(string: href)!, rel: rel, type: type)
    }

    // MARK: - Priority Ordering Tests

    func testSelectBestFavicon_prefersAppleTouchIconPrecomposed() {
        let favicons = [
            link("https://example.com/icon.png", rel: "icon"),
            link("https://example.com/apple-touch.png", rel: "apple-touch-icon"),
            link("https://example.com/precomposed.png", rel: "apple-touch-icon-precomposed")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/precomposed.png")
    }

    func testSelectBestFavicon_prefersAppleTouchIconOverIcon() {
        let favicons = [
            link("https://example.com/icon.png", rel: "icon"),
            link("https://example.com/apple-touch.png", rel: "apple-touch-icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/apple-touch.png")
    }

    func testSelectBestFavicon_returnsIconWhenNoAppleTouchIcon() {
        let favicons = [
            link("https://example.com/favicon.ico", rel: "icon"),
            link("https://example.com/shortcut.png", rel: "shortcut icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/favicon.ico")
    }

    // MARK: - SVG Filtering Tests

    func testSelectBestFavicon_filtersSvgByHref() {
        let favicons = [
            link("https://example.com/logo.svg", rel: "icon"),
            link("https://example.com/favicon.png", rel: "icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/favicon.png")
    }

    func testSelectBestFavicon_filtersSvgByHrefCaseInsensitive() {
        let favicons = [
            link("https://example.com/logo.SVG", rel: "icon"),
            link("https://example.com/favicon.png", rel: "icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/favicon.png")
    }

    func testSelectBestFavicon_filtersSvgByMimeType() {
        let favicons = [
            link("https://example.com/logo", rel: "icon", type: "image/svg+xml"),
            link("https://example.com/favicon.png", rel: "icon", type: "image/png")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/favicon.png")
    }

    func testSelectBestFavicon_filtersSvgByMimeTypeWhenHrefHasNoExtension() {
        // This is the key case: URL doesn't contain "svg" but MIME type does
        let favicons = [
            link("https://example.com/assets/logo", rel: "icon", type: "image/svg+xml"),
            link("https://example.com/favicon.ico", rel: "icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertEqual(result?.absoluteString, "https://example.com/favicon.ico")
    }

    // MARK: - Edge Cases

    func testSelectBestFavicon_returnsNilForEmptyList() {
        let result = sut.selectBestFavicon(from: [])

        XCTAssertNil(result)
    }

    func testSelectBestFavicon_returnsNilWhenAllAreSvg() {
        let favicons = [
            link("https://example.com/logo.svg", rel: "icon"),
            link("https://example.com/apple.svg", rel: "apple-touch-icon")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertNil(result)
    }

    func testSelectBestFavicon_returnsNilWhenNoIconRel() {
        let favicons = [
            link("https://example.com/style.css", rel: "stylesheet"),
            link("https://example.com/manifest.json", rel: "manifest")
        ]

        let result = sut.selectBestFavicon(from: favicons)

        XCTAssertNil(result)
    }

}
