
#if os(iOS)
import UIKit

public class CustomInputAccessoryView: UIInputView {

    private let segmentedControl: UISegmentedControl
    private let height: CGFloat = 44

    private static let userDefaultsKey = "CustomInputAccessoryViewSelectedMode"

    public enum Mode: Int, CaseIterable {
        case search = 0
        case ask = 1

        public var title: String {
            switch self {
            case .search: return "Search"
            case .ask: return "Duck.ai"
            }
        }

        public var icon: UIImage? {
            switch self {
            case .search: return UIImage(systemName: "magnifyingglass")
            case .ask: return UIImage(systemName: "bubble")
            }
        }
    }

    public var selectedMode: Mode {
        get {
            return Mode(rawValue: segmentedControl.selectedSegmentIndex) ?? .search
        }
        set {
            segmentedControl.selectedSegmentIndex = newValue.rawValue
            Self.lastSelectedMode = newValue // Save to UserDefaults whenever set
        }
    }

    // Static shared property to access last selected mode
    public static var lastSelectedMode: Mode {
        get {
            let rawValue = UserDefaults.standard.integer(forKey: userDefaultsKey)
            return Mode(rawValue: rawValue) ?? .search
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultsKey)
        }
    }

    // Callback closure to notify mode changes
    private var modeChangedCallback: ((Mode) -> Void)?

    // Custom initializer accepting initial mode and callback
    public init(initialMode: Mode = CustomInputAccessoryView.lastSelectedMode, modeChangedCallback: @escaping (Mode) -> Void) {
        self.segmentedControl = UISegmentedControl(items: Mode.allCases.map { $0.title })
        self.modeChangedCallback = modeChangedCallback
        super.init(frame: .zero, inputViewStyle: .keyboard)
        setupView()
        selectedMode = initialMode
    }

    required init?(coder: NSCoder) {
        segmentedControl = UISegmentedControl(items: Mode.allCases.map { $0.title })
        super.init(coder: coder)
        setupView()
        selectedMode = CustomInputAccessoryView.lastSelectedMode
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        guard let mode = Mode(rawValue: sender.selectedSegmentIndex) else { return }
        Self.lastSelectedMode = mode // Save to UserDefaults
        modeChangedCallback?(mode)
    }
}


#endif
