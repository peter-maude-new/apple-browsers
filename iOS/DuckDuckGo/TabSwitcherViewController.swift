//
//  TabSwitcherViewController.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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

import UIKit
import Common
import Core
import DDGSync
import WebKit
import Bookmarks
import Persistence
import os.log
import SwiftUI
import Combine
import DesignResourcesKit
import BrowserServicesKit
import PrivacyConfig
import AIChat

class TabSwitcherViewController: UIViewController {

    struct Constants {
        static let preferredMinNumberOfRows: CGFloat = 2.7

        static let cellMinHeight: CGFloat = 140.0
        static let cellMaxHeight: CGFloat = 209.0

        static let trackerInfoTopSpacing: CGFloat = 8
        static let trackerInfoHorizontalPadding: CGFloat = 16
        static let trackerInfoBottomSpacing: CGFloat = 0
    }

    struct BookmarkAllResult {
        let newCount: Int
        let existingCount: Int
        let urls: [URL]
    }

    enum InterfaceMode {

        var isLarge: Bool {
            return [.largeSize, .editingLargeSize].contains(self)
        }

        var isNormal: Bool {
            return !isLarge
        }

        case regularSize
        case largeSize
        case editingRegularSize
        case editingLargeSize

    }

    enum TabsStyle: String {

        case list = "tabsToggleList"
        case grid = "tabsToggleGrid"

        var accessibilityLabel: String {
            switch self {
            case .list: "Switch to grid view"
            case .grid: "Switch to list view"
            }
        }

        var image: UIImage {
            switch self {
            case .list:
                return UIImage(resource: .tabsToggleList)
            case .grid:
                return UIImage(resource: .tabsToggleGrid)
            }
        }

    }

    lazy var borderView = StyledTopBottomBorderView()

    @IBOutlet weak var titleBarView: UINavigationBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!

    weak var delegate: TabSwitcherDelegate!
    weak var previewsSource: TabPreviewsSource!

    // MARK: - Search Properties
    private lazy var searchTextField: TabSearchTextField = {
        let field = TabSearchTextField()
        field.placeholder = UserText.tabSearchBarPlaceholder
        field.delegate = self
        field.accessibilityLabel = UserText.tabSearchBarAccessibilityLabel
        field.accessibilityHint = UserText.tabSearchBarAccessibilityHint
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    var isSearching: Bool = false
    var searchQuery: String = ""
    var filteredTabs: [Tab] = []
    var isSearchBarRevealed: Bool = false

    // Search bar container and constraints for showing/hiding
    private var searchBarContainer: UIView!
    private var searchBarContainerHeightConstraint: NSLayoutConstraint!
    private var searchBarContainerTopConstraint: NSLayoutConstraint?
    private var collectionViewTopConstraint: NSLayoutConstraint?
    private var searchBarHeight: CGFloat {
        return 36 // Fixed height for custom search text field
    }

    var selectedTabs: [IndexPath] {
        collectionView.indexPathsForSelectedItems ?? []
    }

    private(set) var bookmarksDatabase: CoreDataDatabase
    let syncService: DDGSyncing

    override var canBecomeFirstResponder: Bool { return true }

    var currentSelection: Int?

    let tabSwitcherSettings: TabSwitcherSettings
    var isProcessingUpdates = false
    private var canUpdateCollection = true

    let favicons: Favicons

    var tabsStyle: TabsStyle = .list
    var interfaceMode: InterfaceMode = .regularSize
    var canShowSelectionMenu = false

    let featureFlagger: FeatureFlagger
    let tabManager: TabManager
    let historyManager: HistoryManaging
    let fireproofing: Fireproofing
    let aiChatSettings: AIChatSettingsProvider
    let privacyStats: PrivacyStatsProviding
    let keyValueStore: ThrowingKeyValueStoring
    var tabsModel: TabsModel {
        tabManager.model
    }

    let barsHandler: TabSwitcherBarsStateHandling = DefaultTabSwitcherBarsStateHandler()

    private var tabObserverCancellable: AnyCancellable?
    private let appSettings: AppSettings
    private var trackerCountCancellable: AnyCancellable?
    private var trackerCountViewModel: TabSwitcherTrackerCountViewModel?
    private var lastAppliedTrackerCountState: TabSwitcherTrackerCountViewModel.State?
    private var trackerInfoModel: InfoPanelView.Model?
    
    private(set) var aichatFullModeFeature: AIChatFullModeFeatureProviding

    private let productSurfaceTelemetry: ProductSurfaceTelemetry

    required init?(coder: NSCoder,
                   bookmarksDatabase: CoreDataDatabase,
                   syncService: DDGSyncing,
                   featureFlagger: FeatureFlagger,
                   favicons: Favicons = Favicons.shared,
                   tabManager: TabManager,
                   aiChatSettings: AIChatSettingsProvider,
                   appSettings: AppSettings,
                   aichatFullModeFeature: AIChatFullModeFeatureProviding = AIChatFullModeFeature(),
                   privacyStats: PrivacyStatsProviding,
                   productSurfaceTelemetry: ProductSurfaceTelemetry,
                   historyManager: HistoryManaging,
                   fireproofing: Fireproofing,
                   keyValueStore: ThrowingKeyValueStoring,
                   tabSwitcherSettings: TabSwitcherSettings = DefaultTabSwitcherSettings()) {
        self.bookmarksDatabase = bookmarksDatabase
        self.syncService = syncService
        self.featureFlagger = featureFlagger
        self.keyValueStore = keyValueStore
        self.favicons = favicons
        self.tabManager = tabManager
        self.aiChatSettings = aiChatSettings
        self.appSettings = appSettings
        self.aichatFullModeFeature = aichatFullModeFeature
        self.privacyStats = privacyStats
        self.productSurfaceTelemetry = productSurfaceTelemetry
        self.historyManager = historyManager
        self.fireproofing = fireproofing
        self.tabSwitcherSettings = tabSwitcherSettings
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    fileprivate func createTitleBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        titleBarView.standardAppearance = appearance
        titleBarView.scrollEdgeAppearance = appearance
    }

    private func activateLayoutConstraintsBasedOnBarPosition() {
        let isBottomBar = appSettings.currentAddressBarPosition.isBottom

        // Potentially for these 3 we could do thing better for 'normal' on iPad
        let topOffset = -6.0
        let bottomOffset = 8.0
        let navHPadding = 10.0

        // Deactivate old constraints if they exist
        if let oldConstraint = searchBarContainerTopConstraint {
            oldConstraint.isActive = false
        }
        if let oldConstraint = collectionViewTopConstraint {
            oldConstraint.isActive = false
        }

        // Set search bar container top constraint based on bar position
        // Initially positioned off-screen (hidden above visible area)
        let searchBarTopOffset = isSearchBarRevealed ? 0 : -searchBarHeight
        if isBottomBar {
            // Title bar at bottom -> search bar at top safe area
            searchBarContainerTopConstraint = searchBarContainer.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: searchBarTopOffset
            )
        } else {
            // Title bar at top -> search bar below title bar
            searchBarContainerTopConstraint = searchBarContainer.topAnchor.constraint(
                equalTo: titleBarView.bottomAnchor,
                constant: searchBarTopOffset
            )
        }
        searchBarContainerTopConstraint?.isActive = true

        // Collection view top constraint - adjust for search bar if revealed
        let collectionViewOffset = Constants.trackerInfoTopSpacing + (isSearchBarRevealed ? searchBarHeight : 0)
        if isBottomBar {
            collectionViewTopConstraint = collectionView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: collectionViewOffset
            )
        } else {
            collectionViewTopConstraint = collectionView.topAnchor.constraint(
                equalTo: titleBarView.bottomAnchor,
                constant: collectionViewOffset
            )
        }
        collectionViewTopConstraint?.isActive = true

        // The constants here are to force the ai button to align between the tab switcher and this view
        NSLayoutConstraint.activate([
            titleBarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: navHPadding),
            titleBarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -navHPadding),
            isBottomBar ? titleBarView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: topOffset) : nil,
            !isBottomBar ? titleBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: bottomOffset) : nil,

            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            interfaceMode.isLarge ? collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor) :
                collectionView.bottomAnchor.constraint(equalTo: isBottomBar ? titleBarView.topAnchor : toolbar.topAnchor),

            borderView.topAnchor.constraint(equalTo: isBottomBar ? view.safeAreaLayoutGuide.topAnchor : titleBarView.bottomAnchor),
            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // On iPad large mode constrain to the bottom as the toolbar is hidden
            interfaceMode.isLarge ? borderView.bottomAnchor.constraint(equalTo: view.bottomAnchor) :
                borderView.bottomAnchor.constraint(equalTo: isBottomBar ? titleBarView.topAnchor : toolbar.topAnchor),

            // Always at the bottom
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ].compactMap { $0 })
    }

    private func setupSearchBar() {
        // Create container for search bar
        searchBarContainer = UIView()
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.backgroundColor = UIColor(designSystemColor: .background)
        searchBarContainer.clipsToBounds = true
        searchBarContainer.alpha = 0 // Start invisible
        view.addSubview(searchBarContainer)

        // Add search text field to container
        searchBarContainer.addSubview(searchTextField)

        // Height constraint - start at full height but positioned off-screen
        searchBarContainerHeightConstraint = searchBarContainer.heightAnchor.constraint(equalToConstant: searchBarHeight)

        NSLayoutConstraint.activate([
            // Container horizontal constraints - respect safe area
            searchBarContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBarContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            // Note: Top constraint will be set in activateLayoutConstraintsBasedOnBarPosition()
            searchBarContainerHeightConstraint,

            // Search text field inside container with padding: 0pt top/bottom, 8pt leading/trailing
            searchTextField.topAnchor.constraint(equalTo: searchBarContainer.topAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: searchBarContainer.leadingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: searchBarContainer.trailingAnchor, constant: -8),
            searchTextField.bottomAnchor.constraint(equalTo: searchBarContainer.bottomAnchor)
        ])
    }

    private func setupBarsLayout() {
        // Remove existing constraints to avoid conflicts
        borderView.translatesAutoresizingMaskIntoConstraints = false
        titleBarView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Clear existing constraints for these views comprehensively
        let viewsToRemoveConstraintsFor: [UIView] = [titleBarView, toolbar, collectionView, borderView]
        viewsToRemoveConstraintsFor.forEach { targetView in
            targetView.removeFromSuperview()
        }

        // Re-add the views to the hierarchy (search bar container added separately in setupSearchBar)
        view.addSubview(titleBarView)
        view.addSubview(toolbar)
        view.addSubview(collectionView)
        view.addSubview(borderView)

        // Bring search bar container to front if it exists
        if let searchBarContainer = searchBarContainer {
            view.bringSubviewToFront(searchBarContainer)
        }

        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithTransparentBackground()
        toolbarAppearance.shadowColor = .clear
        toolbar.standardAppearance = toolbarAppearance
        toolbar.compactAppearance = toolbarAppearance
        borderView.updateForAddressBarPosition(appSettings.currentAddressBarPosition)
        // On large ipad view don't show the bottom divider
        borderView.isBottomVisible = !interfaceMode.isLarge
        activateLayoutConstraintsBasedOnBarPosition()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // These should only be done once
        createTitleBar()
        setupBackgroundView()
        setupSearchBar() // Set up search bar as separate view
        collectionView.register(
            TabSwitcherTrackerInfoHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TabSwitcherTrackerInfoHeaderView.reuseIdentifier
        )
        tabObserverCancellable = tabsModel.$tabs.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            // Don't auto-reload during search - search manages its own updates
            if !self.isSearching {
                self.collectionView.reloadData()
            }
        }

        // These can be done more than once but don't need to
        decorate()
        becomeFirstResponder()
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.alwaysBounceVertical = true // Enable pull-to-reveal
        collectionView.keyboardDismissMode = .none // Don't dismiss keyboard on scroll
        bindTrackerCount()
        trackerCountViewModel?.refresh()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        productSurfaceTelemetry.tabManagerUsed()
    }

    private func setupBackgroundView() {
        let view = UIView(frame: collectionView.frame)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:))))
        collectionView.backgroundView = view
    }

    func refreshDisplayModeButton() {
        tabsStyle = tabSwitcherSettings.isGridViewEnabled ? .grid : .list
    }

    private func bindTrackerCount() {
        let viewModel = TabSwitcherTrackerCountViewModel(
            settings: tabSwitcherSettings,
            privacyStats: privacyStats,
            featureFlagger: featureFlagger
        )
        trackerCountViewModel = viewModel
        trackerCountCancellable = viewModel.$state
            .sink { [weak self] state in
                self?.applyTrackerCountState(state)
            }
    }

    private func applyTrackerCountState(_ state: TabSwitcherTrackerCountViewModel.State) {
        guard state != lastAppliedTrackerCountState else { return }
        lastAppliedTrackerCountState = state

        guard state.isVisible else {
            trackerInfoModel = nil
            updateTrackerInfoHeaderIfVisible()
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        trackerInfoModel = .trackerInfoPanel(
            state: state,
            onTap: { },
            onInfo: { [weak self] in
                self?.presentHideTrackerCountAlert()
            }
        )
        updateTrackerInfoHeaderIfVisible()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func updateTrackerInfoHeaderIfVisible() {
        let indexPath = IndexPath(item: 0, section: 0)
        guard let header = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: indexPath
        ) as? TabSwitcherTrackerInfoHeaderView else {
            return
        }

        header.configure(in: self, model: trackerInfoModel)
    }

    private func presentHideTrackerCountAlert() {
        let alert = UIAlertController(title: UserText.tabSwitcherTrackerCountHideTitle,
                                      message: UserText.tabSwitcherTrackerCountHideMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: UserText.tabSwitcherTrackerCountKeepAction, style: .cancel))
        alert.addAction(UIAlertAction(title: UserText.tabSwitcherTrackerCountHideAction, style: .default) { [weak self] _ in
            self?.trackerCountViewModel?.hide()
        })
        present(alert, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTitle()
        currentSelection = tabsModel.currentIndex
        updateUIForSelectionMode()
        setupBarsLayout()
        trackerCountViewModel?.refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isSearching {
            finishSearching()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        _ = AppWidthObserver.shared.willResize(toWidth: size.width)
        updateUIForSelectionMode()
        setupBarsLayout()
        collectionView.setNeedsLayout()
        collectionView.collectionViewLayout.invalidateLayout()

    }

    func prepareForPresentation() {
        view.layoutIfNeeded()
        self.scrollToInitialTab()
    }
    
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard gesture.tappedInWhitespaceAtEndOfCollectionView(collectionView) else { return }
        
        if isEditing {
            transitionFromMultiSelect()
        } else {
            dismiss()
        }
    }

    private func scrollToInitialTab() {
        let index = tabsModel.currentIndex
        guard index < collectionView.numberOfItems(inSection: 0) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
    }

    func refreshTitle() {
        titleBarView.topItem?.title = UserText.numberOfTabs(tabsModel.count)
        if !selectedTabs.isEmpty {
            titleBarView.topItem?.title = UserText.numberOfSelectedTabs(withCount: selectedTabs.count)
        }
    }

    func displayBookmarkAllStatusMessage(with results: BookmarkAllResult, openTabsCount: Int) {
        if results.newCount == 1 {
            ActionMessageView.present(message: UserText.tabsBookmarked(withCount: results.newCount), actionTitle: UserText.actionGenericEdit, onAction: {
                self.editBookmark(results.urls.first)
            })
        } else if results.newCount > 0 {
            ActionMessageView.present(message: UserText.tabsBookmarked(withCount: results.newCount), actionTitle: UserText.actionGenericUndo, onAction: {
                self.removeBookmarks(results.urls)
            })
        } else { // Zero
            ActionMessageView.present(message: UserText.tabsBookmarked(withCount: results.newCount))
        }
    }
    
    func removeBookmarks(_ url: [URL]) {
        let model = BookmarkListViewModel(bookmarksDatabase: self.bookmarksDatabase, parentID: nil, favoritesDisplayMode: .default, errorEvents: nil)
        url.forEach {
            guard let entity = model.bookmark(for: $0) else { return }
            model.softDeleteBookmark(entity)
        }
    }
    
    func editBookmark(_ url: URL?) {
        guard let url else { return }
        delegate?.tabSwitcher(self, editBookmarkForUrl: url)
    }

    func addNewTab() {
        guard !isProcessingUpdates else { return }
        // Will be dismissed, so no need to process incoming updates
        canUpdateCollection = false

        Pixel.fire(pixel: .tabSwitcherNewTab)
        dismiss()
        // This call needs to be after the dismiss to allow OmniBarEditingStateViewController
        // to present on top of MainVC instead of TabSwitcher.
        // If these calls are switched it'll be immediately dismissed along with this controller.
        delegate.tabSwitcherDidRequestNewTab(tabSwitcher: self)
    }
    
    func addNewAIChatTab() {
        guard !isProcessingUpdates else { return }
        canUpdateCollection = false
        
        dismiss()
        
        self.delegate.tabSwitcherDidRequestAIChatTab(tabSwitcher: self)
    }

    func bookmarkTabs(withIndexPaths indexPaths: [IndexPath], viewModel: MenuBookmarksInteracting) -> BookmarkAllResult {
        let tabs = self.tabsModel.tabs
        var newCount = 0
        var urls = [URL]()

        indexPaths.compactMap {
            tabsModel.safeGetTabAt($0.row)
        }.forEach { tab in
            guard let link = tab.link else { return }
            if viewModel.bookmark(for: link.url) == nil {
                viewModel.createBookmark(title: link.displayTitle, url: link.url)
                favicons.loadFavicon(forDomain: link.url.host, intoCache: .fireproof, fromCache: .tabs)
                newCount += 1
                urls.append(link.url)
            }
        }
        return .init(newCount: newCount, existingCount: tabs.count - newCount, urls: urls)
    }

    @IBAction func onAddPressed(_ sender: UIBarButtonItem) {
        addNewTab()
    }

    @IBAction func onDonePressed(_ sender: UIBarButtonItem) {
        if isEditing {
            transitionFromMultiSelect()
        } else {
            dismiss()
        }
    }
    
    func markCurrentAsViewedAndDismiss() {
        // Will be dismissed, so no need to process incoming updates
        canUpdateCollection = false

        dismiss()
        if let current = currentSelection {
            let tab = tabsModel.get(tabAt: current)
            tab.viewed = true
            tabManager.save()
            delegate?.tabSwitcher(self, didSelectTab: tab)
        }
    }

    @IBAction func onFirePressed(sender: AnyObject) {
        burn(sender: sender)
    }

    func forgetAll(_ fireRequest: FireRequest) {
        self.delegate.tabSwitcherDidRequestForgetAll(tabSwitcher: self, fireRequest: fireRequest)
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        canUpdateCollection = false
        tabsModel.tabs.forEach { $0.removeObserver(self) }
        super.dismiss(animated: animated, completion: completion)
    }
}

extension TabSwitcherViewController: TabViewCellDelegate {

    func deleteTabsAtIndexPaths(_ indexPaths: [IndexPath]) {
        let shouldDismiss = tabsModel.count == indexPaths.count

        collectionView.performBatchUpdates {
            isProcessingUpdates = true
            tabManager.bulkRemoveTabs(indexPaths)
            collectionView.deleteItems(at: indexPaths)
        } completion: { _ in
            self.currentSelection = self.tabsModel.currentIndex
            self.isProcessingUpdates = false
            if self.tabsModel.tabs.isEmpty {
                self.tabsModel.add(tab: Tab())
            }

            self.delegate?.tabSwitcherDidBulkCloseTabs(tabSwitcher: self)
            self.refreshTitle()
            self.updateUIForSelectionMode()
            if shouldDismiss {
                self.dismiss()
            }
        }
    }
    
    func deleteTab(tab: Tab) {
        // If search is active, cancel it first
        if isSearching || isSearchBarRevealed {
            finishSearching()
        }

        // Find the tab in the actual model and delete it
        guard let modelIndex = tabsModel.indexOf(tab: tab) else { return }
        let indexPath = IndexPath(row: modelIndex, section: 0)
        deleteTabsAtIndexPaths([indexPath])
    }

    func isCurrent(tab: Tab) -> Bool {
        return currentSelection == tabsModel.indexOf(tab: tab)
    }

    private func removeFavicon(forTab tab: Tab) {
        DispatchQueue.global(qos: .background).async {
            if let currentHost = tab.link?.url.host,
               !self.tabsModel.tabExists(withHost: currentHost) {
                Favicons.shared.removeTabFavicon(forDomain: currentHost)
            }
        }
    }

}

extension TabSwitcherViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredTabs.count : tabsModel.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = tabSwitcherSettings.isGridViewEnabled ? TabViewCell.gridReuseIdentifier : TabViewCell.listReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TabViewCell else {
            fatalError("Failed to dequeue cell \(cellIdentifier) as TabViewCell")
        }
        cell.delegate = self
        cell.isDeleting = false

        let tab = getTab(at: indexPath)
        tab.addObserver(self)
        cell.update(withTab: tab,
                    isSelectionModeEnabled: self.isEditing,
                    preview: previewsSource.preview(for: tab))

        return cell
    }

    /// Get the tab at a given index path, accounting for search filtering
    private func getTab(at indexPath: IndexPath) -> Tab {
        if isSearching {
            return filteredTabs[indexPath.row]
        } else {
            return tabsModel.get(tabAt: indexPath.row)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        // Header now only shows tracker info (search bar is separate)
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TabSwitcherTrackerInfoHeaderView.reuseIdentifier,
            for: indexPath
        ) as? TabSwitcherTrackerInfoHeaderView else {
            return UICollectionReusableView()
        }

        // Don't show tracker info during multi-select mode
        let trackerModel = isEditing ? nil : trackerInfoModel
        header.configure(in: self, model: trackerModel)
        return header
    }

}

extension TabSwitcherViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            Pixel.fire(pixel: .tabSwitcherTabSelected)
            (collectionView.cellForItem(at: indexPath) as? TabViewCell)?.refreshSelectionAppearance()
            updateUIForSelectionMode()
            refreshTitle()
        } else {
            // Get the actual tab and find its index in the main model
            let tab = getTab(at: indexPath)

            // Clear search before switching tabs
            if isSearching {
                finishSearching()
            }

            // Find the index of the selected tab in the actual model
            if let actualIndex = tabsModel.indexOf(tab: tab) {
                currentSelection = actualIndex
                Pixel.fire(pixel: .tabSwitcherSwitchTabs)
                markCurrentAsViewedAndDismiss()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? TabViewCell)?.refreshSelectionAppearance()
        updateUIForSelectionMode()
        refreshTitle()
        Pixel.fire(pixel: .tabSwitcherTabDeselected)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return !isEditing
    }

    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
                        toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        return proposedIndexPath
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        // Disable context menu when search bar is visible to avoid crashes
        guard !isSearchBarRevealed else { return nil }

        // This can happen if you long press in the whitespace
        guard !indexPaths.isEmpty else { return nil }

        // Convert search result index paths to actual model index paths
        let actualIndexPaths: [IndexPath]
        if isSearching {
            actualIndexPaths = indexPaths.compactMap { indexPath in
                let tab = filteredTabs[indexPath.row]
                if let actualIndex = tabsModel.indexOf(tab: tab) {
                    return IndexPath(row: actualIndex, section: 0)
                }
                return nil
            }
        } else {
            actualIndexPaths = indexPaths
        }

        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            Pixel.fire(pixel: .tabSwitcherLongPress)
            DailyPixel.fire(pixel: .tabSwitcherLongPressDaily)
            return self.createLongPressMenuForTabs(atIndexPaths: actualIndexPaths)
        }

        return configuration
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only enable pull-to-reveal when not searching and not in edit mode
        guard !isSearching && !isEditing && !isSearchBarRevealed else { return }

        let offsetY = scrollView.contentOffset.y
        let adjustedOffset = offsetY + scrollView.contentInset.top
        let threshold: CGFloat = -60 // Pull down threshold

        if adjustedOffset < threshold {
            revealSearchBar()
        }
    }

    private func revealSearchBar() {
        guard !isSearchBarRevealed else { return }
        isSearchBarRevealed = true

        let isBottomBar = appSettings.currentAddressBarPosition.isBottom

        // Update search bar constraint to slide it into view (from negative offset to 0)
        searchBarContainerTopConstraint?.constant = 0

        // Update collection view constraint to make room for search bar
        let collectionViewOffset = Constants.trackerInfoTopSpacing + searchBarHeight
        collectionViewTopConstraint?.constant = collectionViewOffset

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.searchBarContainer.alpha = 1.0 // Fade in
            self.view.layoutIfNeeded()
        }) { _ in
            // Make search text field first responder after animation
            self.searchTextField.becomeFirstResponder()
        }
    }

    private func hideSearchBar() {
        guard isSearchBarRevealed else { return }
        guard !isSearching else { return } // Don't hide while actively searching

        isSearchBarRevealed = false

        let isBottomBar = appSettings.currentAddressBarPosition.isBottom

        // Resign first responder if needed
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
        }

        // Update search bar constraint to slide it out of view (from 0 to negative offset)
        searchBarContainerTopConstraint?.constant = -searchBarHeight

        // Update collection view constraint back to original position
        collectionViewTopConstraint?.constant = Constants.trackerInfoTopSpacing

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.searchBarContainer.alpha = 0.0 // Fade out
            self.view.layoutIfNeeded()
        })
    }

}

extension TabSwitcherViewController: UICollectionViewDelegateFlowLayout {

    private func calculateColumnWidth(minimumColumnWidth: CGFloat, maxColumns: Int) -> CGFloat {
        // Spacing is supposed to be equal between cells and on left/right side of the collection view
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let spacing = layout?.sectionInset.left ?? 0.0
        
        let contentWidth = collectionView.bounds.width - spacing
        let numberOfColumns = min(maxColumns, Int(contentWidth / minimumColumnWidth))
        return contentWidth / CGFloat(numberOfColumns) - spacing
    }
    
    private func calculateRowHeight(columnWidth: CGFloat) -> CGFloat {
        
        // Calculate height based on the view size
        let contentAspectRatio = collectionView.bounds.width / collectionView.bounds.height
        let heightToFit = (columnWidth / contentAspectRatio) + TabViewCell.Constants.cellHeaderHeight
        
        // Try to display at least `preferredMinNumberOfRows`
        let preferredMaxHeight = collectionView.bounds.height / Constants.preferredMinNumberOfRows
        let preferredHeight = min(preferredMaxHeight, heightToFit)
        
        return min(Constants.cellMaxHeight,
                   max(Constants.cellMinHeight, preferredHeight))
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGSize
        if tabSwitcherSettings.isGridViewEnabled {
            let columnWidth = calculateColumnWidth(minimumColumnWidth: 150, maxColumns: 4)
            let rowHeight = calculateRowHeight(columnWidth: columnWidth)
            size = CGSize(width: floor(columnWidth),
                          height: floor(rowHeight))
        } else {
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
            let spacing = layout?.sectionInset.left ?? 0.0
            
            let width = min(664, collectionView.bounds.size.width - 2 * spacing)
            
            size = CGSize(width: width, height: 70)
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Header only shows tracker info now (search bar is separate)
        guard !isEditing && trackerInfoModel != nil else {
            return .zero
        }

        return CGSize(width: collectionView.bounds.width, height: TabSwitcherTrackerInfoHeaderView.estimatedHeight)
    }

}

extension TabSwitcherViewController: TabObserver {
    
    func didChange(tab: Tab) {
        // During search, find the tab in filtered results instead of the full model
        let index: Int?
        if isSearching {
            index = filteredTabs.firstIndex(where: { $0.uid == tab.uid })
        } else {
            index = tabsModel.indexOf(tab: tab)
        }

        guard let index = index,
              let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? TabViewCell,
              // Check the current tab is the one we want to update, if not it might have been updated elsewhere
              cell.tab?.uid == tab.uid else {
            DailyPixel.fireDaily(.debugTabSwitcherDidChangeInvalidState)
            return
        }

        cell.update(withTab: tab,
                    isSelectionModeEnabled: self.isEditing,
                    preview: previewsSource.preview(for: tab))
    }
}

extension TabSwitcherViewController {
    
    private func decorate() {
        let theme = ThemeManager.shared.currentTheme
        view.backgroundColor = theme.backgroundColor
        
        refreshDisplayModeButton()
        
        titleBarView.tintColor = theme.barTintColor

        toolbar.barTintColor = theme.barBackgroundColor
        toolbar.tintColor = theme.barTintColor
                
        collectionView.reloadData()
    }

}

// These don't appear to do anything but at least one needs to exist for dragging to even work
extension TabSwitcherViewController: UICollectionViewDragDelegate {

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return isEditing ? [] : [UIDragItem(itemProvider: NSItemProvider())]
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: any UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

}

extension TabSwitcherViewController: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView, canHandle session: any UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {

        guard let destination = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let source = item.sourceIndexPath
        else {
            // This can happen if the menu is shown and the user then drags to an invalid location
            return
        }

        collectionView.performBatchUpdates {
            tabsModel.moveTab(from: source.row, to: destination.row)
            currentSelection = tabsModel.currentIndex
            collectionView.deleteItems(at: [source])
            collectionView.insertItems(at: [destination])
        } completion: { _ in
            if self.isEditing {
                collectionView.reloadData() // Clears the selection
                collectionView.selectItem(at: destination, animated: true, scrollPosition: [])
                self.refreshBarButtons()
            } else {
                collectionView.reloadItems(at: [IndexPath(row: self.currentSelection ?? 0, section: 0)])
            }
            self.delegate.tabSwitcherDidReorderTabs(tabSwitcher: self)
            coordinator.drop(item.dragItem, toItemAt: destination)
        }

    }

}

// MARK: - UISearchBarDelegate
extension TabSwitcherViewController: TabSearchTextFieldDelegate {

    func searchTextFieldDidChange(_ textField: TabSearchTextField, text: String) {
        searchQuery = text

        // Ensure we're in search mode even if prepareForSearching wasn't called yet
        if !isSearching {
            prepareForSearching()
        }

        performSearch(query: text)
    }

    func searchTextFieldDidBeginEditing(_ textField: TabSearchTextField) {
        prepareForSearching()
    }

    func searchTextFieldDidEndEditing(_ textField: TabSearchTextField) {
        // No-op
    }

    func searchTextFieldDidTapCancel(_ textField: TabSearchTextField) {
        finishSearching()
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            // When search is cleared, show all tabs (not filtered)
            isSearching = false
            filteredTabs = []
            updateSearchBackgroundView()
            collectionView.reloadData()
            return
        }

        // Ensure we're in search mode when typing
        if !isSearching {
            isSearching = true
        }

        let searcher = TabsSearch()
        filteredTabs = searcher.search(query: query, in: tabsModel.tabs)
        updateSearchBackgroundView()
        collectionView.reloadData()

        // Announce result count for accessibility
        let resultCount = filteredTabs.count
        if resultCount == 0 {
            UIAccessibility.post(notification: .announcement, argument: UserText.tabSearchEmptyTitle)
        } else {
            let announcement = "\(resultCount) \(resultCount == 1 ? "tab" : "tabs") found"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private func prepareForSearching() {
        if isEditing {
            transitionFromMultiSelect()
        }
        isSearching = true
        collectionView.dragDelegate = nil // Disable drag during search

        updateUIForSelectionMode()
    }

    func finishSearching() {
        searchTextField.text = ""
        searchTextField.resignFirstResponder()
        searchTextField.hideCancelButton(animated: true)
        isSearching = false
        searchQuery = ""
        filteredTabs = []

        collectionView.backgroundView = nil
        collectionView.dragDelegate = self
        collectionView.reloadData()

        updateUIForSelectionMode()

        // Hide search bar after a delay if user didn't type anything meaningful
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hideSearchBar()
        }
    }

    private func updateSearchBackgroundView() {
        if isSearching && filteredTabs.isEmpty && !searchQuery.isEmpty {
            // Show empty state
            let emptyView = UIHostingController(rootView: TabSearchEmptyView(query: searchQuery))
            emptyView.view.backgroundColor = .clear
            collectionView.backgroundView = emptyView.view
        } else {
            collectionView.backgroundView = nil
            setupBackgroundView() // Restore tap gesture
        }
    }
}


extension UITapGestureRecognizer {

    func tappedInWhitespaceAtEndOfCollectionView(_ collectionView: UICollectionView) -> Bool {
        guard collectionView.indexPathForItem(at: self.location(in: collectionView)) == nil else { return false }
        let location = self.location(in: collectionView)
           
        // Now check if the tap is in the whitespace area at the end
        let lastSection = collectionView.numberOfSections - 1
        let lastItemIndex = collectionView.numberOfItems(inSection: lastSection) - 1
        
        // Get the frame of the last item
        // If there are no items in the last section, the entire area is whitespace
       guard lastItemIndex >= 0 else { return true }
        
        let lastItemIndexPath = IndexPath(item: lastItemIndex, section: lastSection)
        let lastItemFrame = collectionView.layoutAttributesForItem(at: lastItemIndexPath)?.frame ?? .zero
        
        // Check if the tap is below the last item.
        // Add 10px buffer to ensure it's whitespace.
        if location.y > lastItemFrame.maxY + 15 // below the bottom of the last item is definitely the end
            || (location.x > lastItemFrame.maxX + 15 && location.y > lastItemFrame.minY) { // to the right of the last item is the end as long as it's also at least below the start of the frame
            // The tap is in the whitespace area at the end
           return true
        }

        return false
    }
}
