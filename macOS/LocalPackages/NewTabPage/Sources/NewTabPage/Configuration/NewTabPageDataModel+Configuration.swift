//
//  NewTabPageDataModel+Configuration.swift
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

import Foundation

public extension NewTabPageDataModel {
    struct OpenAction: Codable {
        let target: Target

        public enum Target: String, Codable {
            case settings
            case duckAISettings
        }
    }
}

extension NewTabPageDataModel {

    public enum WidgetId: String, Codable {
        case rmf, freemiumPIRBanner, subscriptionWinBackBanner, nextSteps, nextStepsList, omnibar, favorites, protections
        case weather, news, stock
    }

    /// Unified widget config - represents both standard and multi-instance widgets
    public struct WidgetConfig: Codable, Equatable {
        public var id: WidgetId
        public var visibility: WidgetVisibility

        // Multi-instance widgets have an instanceId
        public var instanceId: String?

        // Weather-specific
        public var location: String?
        public var temperatureUnit: TemperatureUnit?

        // News-specific
        public var query: String?

        // Stock-specific
        public var symbols: [String]?

        // UI state
        public var expansion: Expansion?

        public enum WidgetVisibility: String, Codable {
            case visible, hidden

            public var isVisible: Bool {
                self == .visible
            }
        }

        public enum TemperatureUnit: String, Codable {
            case celsius, fahrenheit
        }

        public enum Expansion: String, Codable {
            case expanded, collapsed
        }

        // Convenience initializer for standard widgets
        public init(id: WidgetId, isVisible: Bool) {
            self.id = id
            self.visibility = isVisible ? .visible : .hidden
        }
    }

    // Legacy alias
    public typealias MultiInstanceWidgetConfig = WidgetConfig

    struct ContextMenuParams: Codable {
        let visibilityMenuItems: [ContextMenuItem]

        struct ContextMenuItem: Codable {
            let id: WidgetId
            let title: String
        }
    }

    struct Exception: Codable, Equatable {
        let message: String
    }

    struct NewTabPageConfiguration: Encodable {
        var widgets: [Widget]
        var widgetConfigs: [NewTabPageDataModel.WidgetConfig]
        var env: String
        var locale: String
        var platform: Platform
        var settings: Settings?
        var customizer: NewTabPageDataModel.CustomizerData?
        var tabs: Tabs?

        struct Widget: Encodable, Equatable {
            public var id: WidgetId
        }

        struct Platform: Encodable, Equatable {
            var name: String
        }

        struct Settings: Encodable, Equatable {
            let customizerDrawer: Setting
        }

        struct Setting: Encodable, Equatable {
            let state: BooleanSetting
        }

        enum BooleanSetting: String, Encodable {
            case enabled, disabled

            var isEnabled: Bool {
                self == .enabled
            }
        }
    }
}
