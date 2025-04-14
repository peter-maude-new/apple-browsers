//
//  URLs.swift
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

import Foundation

enum URLs {
    static let example = URL(string: "https://www.example.com")!
    static let ddg = URL(string: "https://duckduckgo.com?q=test")!
    static let ddg2 = URL(string: "https://duckduckgo.com?q=testSomethingElse")!
    static let facebook = URL(string: "https://www.facebook.com")!
    static let google = URL(string: "https://www.google.com")!
    static let ownedByFacebook = URL(string: "https://www.instagram.com")!
    static let ownedByFacebook2 = URL(string: "https://www.whatsapp.com")!
    static let amazon = URL(string: "https://www.amazon.com")!
    static let tracker = URL(string: "https://www.1dmp.io")!
}
