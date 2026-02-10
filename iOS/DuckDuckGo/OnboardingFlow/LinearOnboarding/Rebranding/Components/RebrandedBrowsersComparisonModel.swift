import SwiftUI
import DesignResourcesKit
import DesignResourcesKitIcons

struct RebrandedBrowsersComparisonModel {

    struct Feature: Equatable {
        let type: FeatureType
        let safariAvailability: Availability
        let ddgAvailability: Availability

        enum FeatureType: Equatable {
            case privateSearch
            case blockTrackers
            case blockCookies
            case blockAds
            case eraseData

            var title: String {
                switch self {
                case .privateSearch:
                    return "Search privately by default"
                case .blockTrackers:
                    return "Block 3rd-party trackers"
                case .blockCookies:
                    return "Block cookie requests & pop-ups"
                case .blockAds:
                    return "Block targeted ads"
                case .eraseData:
                    return "Erase browsing data swiftly"
                }
            }

            var icon: DesignSystemImage {
                switch self {
                case .privateSearch:
                    return DesignSystemImages.Color.Size24.findSearch
                case .blockTrackers:
                    return DesignSystemImages.Color.Size24.shield
                case .blockCookies:
                    return DesignSystemImages.Color.Size24.cookieBlocked
                case .blockAds:
                    return DesignSystemImages.Color.Size24.adsBlocked
                case .eraseData:
                    return DesignSystemImages.Color.Size24.fire
                }
            }
        }

        enum Availability {
            case available
            case partial
            case unavailable

            var icon: DesignSystemImage {
                switch self {
                case .available:
                    return DesignSystemImages.Glyphs.Size20.checkSolid
                case .partial:
                    return DesignSystemImages.Glyphs.Size20.stopSolid
                case .unavailable:
                    return DesignSystemImages.Glyphs.Size20.closeSolid
                }
            }

            var color: Color {
                switch self {
                case .available:
                    return Color(red: 0x39/255, green: 0xB2/255, blue: 0x5E/255) // green40
                case .partial:
                    return Color(red: 0xFF/255, green: 0xD8/255, blue: 0x85/255) // pollen30
                case .unavailable:
                    return Color(red: 0x88/255, green: 0x88/255, blue: 0x88/255) // gray50
                }
            }
        }
    }

    static let features: [Feature] = [
        Feature(
            type: .privateSearch,
            safariAvailability: .unavailable,
            ddgAvailability: .available
        ),
        Feature(
            type: .blockTrackers,
            safariAvailability: .unavailable,
            ddgAvailability: .available
        ),
        Feature(
            type: .blockCookies,
            safariAvailability: .partial,
            ddgAvailability: .available
        ),
        Feature(
            type: .blockAds,
            safariAvailability: .unavailable,
            ddgAvailability: .available
        ),
        Feature(
            type: .eraseData,
            safariAvailability: .unavailable,
            ddgAvailability: .available
        )
    ]
}
