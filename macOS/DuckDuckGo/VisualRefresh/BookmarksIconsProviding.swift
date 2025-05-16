//
//  BookmarksIconsProviding.swift
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

import DesignResourcesKit

protocol BookmarksIconsProviding {
    var bookmarksManagerRootIcon: NSImage { get }
    var bookmarkFolderColorIcon: NSImage { get }
    var bookmarkFolderIcon: NSImage { get }
    var bookmarkIcon: NSImage { get }
    var bookmarkColorIcon: NSImage { get }
    var addBookmarkFolderIcon: NSImage { get }
    var addBookmarkIcon: NSImage { get }
}

final class LegacyBookmarksIconsProvider: BookmarksIconsProviding {
    var bookmarksManagerRootIcon: NSImage = .bookmarksFolder
    var bookmarkFolderColorIcon: NSImage = .folder
    var bookmarkFolderIcon: NSImage = .folder16
    var bookmarkIcon: NSImage = .bookmark
    var bookmarkColorIcon: NSImage = .bookmarkDefaultFavicon
    var addBookmarkFolderIcon: NSImage = .addBookmark
    var addBookmarkIcon: NSImage = .addFolder
}

final class CurrentBookmarksIconsProvider: BookmarksIconsProviding {
    var bookmarksManagerRootIcon: NSImage = DesignSystemImages.Color.Size16.bookmarksNew
    var bookmarkFolderColorIcon: NSImage = DesignSystemImages.Color.Size16.folder
    var bookmarkFolderIcon: NSImage = DesignSystemImages.Glyphs.Size16.folder
    var bookmarkIcon: NSImage = DesignSystemImages.Glyphs.Size16.bookmark
    var bookmarkColorIcon: NSImage = DesignSystemImages.Color.Size16.bookmark
    var addBookmarkFolderIcon: NSImage = DesignSystemImages.Glyphs.Size16.folderNew
    var addBookmarkIcon: NSImage = DesignSystemImages.Glyphs.Size16.bookmarkAdd
}
