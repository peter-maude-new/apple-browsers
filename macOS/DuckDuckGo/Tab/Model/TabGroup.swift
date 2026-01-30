//
//  TabGroup.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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
import AppKit

struct TabGroup: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var color: TabGroupColor
    let createdAt: Date

    init(id: UUID = UUID(), name: String, color: TabGroupColor = .gray) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = Date()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TabGroup, rhs: TabGroup) -> Bool {
        lhs.id == rhs.id
    }
}

enum TabGroupColor: String, CaseIterable, Codable {
    case blue, purple, green, yellow, orange, red, pink, gray
    var nsColor: NSColor {
        switch self {
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .orange:
            return .orange
        case .red:
            return .red
        case .pink:
            return .systemPink
        case .gray:
            return .gray
        }
    }
}

final class TabGroupManager: ObservableObject {
    @Published private(set) var groups: [TabGroup] = []
    @Published private(set) var tabToGroup: [String: UUID] = [:]  // tab.uuid -> group.id

    // MARK: - Queries

    func group(for tab: Tab) -> TabGroup? {
        guard let id = groupID(for: tab) else { return nil }
        return groups.first(where: { $0.id == id })
    }

    func groupID(for tab: Tab) -> UUID? {
        return tabToGroup[tab.uuid]
    }

    func groupID(forTabUUID tabUUID: String) -> UUID? {
        return tabToGroup[tabUUID]
    }

    func isTabGrouped(_ tab: Tab) -> Bool {
        return groupID(for: tab) != nil
    }

    // MARK: - Group CRUD Operations

    @discardableResult
    func createGroup(name: String, color: TabGroupColor = .blue) -> TabGroup {
        let group = TabGroup(name: name, color: color)
        groups.append(group)
        return group
    }

    func updateGroup(_ group: TabGroup, name: String, color: TabGroupColor) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = name
        groups[index].color = color
    }

    func registerGroup(_ group: TabGroup) {
        groups.append(group)
    }

    func unregisterGroup(_ group: TabGroup) {
        // Remove all tab associations for this group
        tabToGroup = tabToGroup.filter { $0.value != group.id }
        groups.removeAll(where: { $0.id == group.id })
    }

    // MARK: - Tab-Group Mapping

    func setGroup(_ groupID: UUID?, for tab: Tab) {
        if groupID == nil {
            tabToGroup.removeValue(forKey: tab.uuid)
        } else {
            tabToGroup[tab.uuid] = groupID
        }
    }

    func tabs(in group: TabGroup, from allTabs: [Tab]) -> [Tab] {
        allTabs.filter { tabToGroup[$0.uuid] == group.id }
    }

    func tabUUIDs(in group: TabGroup) -> [String] {
        tabToGroup.filter { $0.value == group.id }.map { $0.key }
    }

    // MARK: - Persistence

//    func encode() -> Data
//    static func decode(from data: Data) -> TabGroupManager
}
