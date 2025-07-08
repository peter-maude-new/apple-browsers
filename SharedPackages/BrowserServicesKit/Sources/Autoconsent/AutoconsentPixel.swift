import PixelKit

public enum AutoconsentPixel: PixelKitEventV2 {

    case acInit
    case missedPopup
    case errorMultiplePopups
    case errorOptoutFailed
    case popupFound
    case done
    case doneCosmetic
    case animationShown
    case animationShownCosmetic
    case disabledForSite
    case heuristicMatch
    case heuristicDetected
    case selfTestOk
    case selfTestFail

    case summary(events: [String: Int])

    static var summaryPixels = [AutoconsentPixel] (
        arrayLiteral: .acInit,
        .missedPopup,
        .errorMultiplePopups,
        .errorOptoutFailed,
        .popupFound,
        .done,
        .doneCosmetic,
        .animationShown,
        .animationShownCosmetic,
        .disabledForSite,
        .heuristicMatch,
        .heuristicDetected,
        .selfTestOk,
        .selfTestFail
    )

    public var name: String {
        switch self {
        case .acInit: "autoconsent_init"
        case .missedPopup: "autoconsent_missed-popup"
        case .errorMultiplePopups: "autoconsent_multiple-popups"
        case .errorOptoutFailed: "autoconsent_error_optout"
        case .popupFound: "autoconsent_popup-found"
        case .done: "autoconsent_done"
        case .doneCosmetic: "autoconsent_done_cosmetic"
        case .animationShown: "autoconsent_animation-shown"
        case .animationShownCosmetic: "autoconsent_animation-shown_cosmetic"
        case .disabledForSite: "autoconsent_disabled-for-site"
        case .heuristicDetected: "autoconsent_heuristic-detected"
        case .heuristicMatch: "autoconsent_heuristic-match"
        case .selfTestOk: "autoconsent_self-test-ok"
        case .selfTestFail: "autoconsent_self-test-fail"
        case .summary: "autoconsent_summary"
        }
    }

    public var key: String {
        return String(name.dropFirst(12))
    }

    public var parameters: [String: String]? {
        switch self {
        case let .summary(events):
            Dictionary(uniqueKeysWithValues: AutoconsentPixel.summaryPixels.map { pixel in
            (pixel.key, "\(events[pixel.key] ?? 0)")
            })
        default: [:]
        }
    }

    public var error: (any Error)? {
        nil
    }
}
