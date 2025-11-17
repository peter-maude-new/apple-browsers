//
//  SettingsSubscriptionView.swift
//  DuckDuckGo
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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

import Core
import Subscription
import BrowserServicesKit
import StoreKit
import DataBrokerProtection_iOS
import SwiftUI
import UIKit
import DesignResourcesKit
import DesignResourcesKitIcons

struct SettingsSubscriptionView: View {

    enum ViewConstants {
        static let purchaseDescriptionPadding = 5.0
        static let topCellPadding = 3.0
        static let noEntitlementsIconWidth = 20.0
        static let navigationDelay = 0.3
        static let privacyPolicyURL = URL(string: "https://duckduckgo.com/pro/privacy-terms")!
    }

    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var subscriptionNavigationCoordinator: SubscriptionNavigationCoordinator
    @State var isShowingDBP = false
    @State var isShowingITP = false
    @State var isShowingVPN = false
    @State var isShowingPaidAIChat = false
    @State var isShowingRestoreFlow = false
    @State var isShowingGoogleView = false
    @State var isShowingStripeView = false
    @State var isShowingSubscription = false

    // Debug functions for testing subscription purchases (V2 only)
    private func testDirectPurchase(productID: String, description: String) {
        Task {
            do {
                print("SABRINA iOS: Testing V2 purchase of \(productID)")
                
                guard let subscriptionManagerV2 = AppDependencyProvider.shared.subscriptionManagerV2 else {
                    print("SABRINA iOS: No V2 subscription manager available")
                    return
                }
                
                // FIRST: Ensure products are loaded and synced
                print("SABRINA iOS: Syncing Apple ID account...")
                try await subscriptionManagerV2.storePurchaseManager().syncAppleIDAccount()
                
                print("SABRINA iOS: Checking products after sync...")
                // Cast to concrete type to access getAvailableProducts method
                if let storePurchaseManager = subscriptionManagerV2.storePurchaseManager() as? DefaultStorePurchaseManagerV2 {
                    let availableProducts = await storePurchaseManager.getAvailableProducts()
                    print("SABRINA iOS: Found \(availableProducts.count) products after sync")
                    
                    // Check if our product exists
                    if !availableProducts.contains(where: { $0.id == productID }) {
                        print("SABRINA iOS: ERROR - Product \(productID) not found in available products!")
                        for product in availableProducts {
                            print("SABRINA iOS AVAILABLE: \(product.id)")
                        }
                        return
                    }
                } else {
                    print("SABRINA iOS: Could not cast to DefaultStorePurchaseManagerV2")
                    return
                }
                
                let externalID: String
                if let existingID = try? await subscriptionManagerV2.getTokenContainer(policy: .local).decodedAccessToken.externalID {
                    externalID = existingID
                    print("SABRINA iOS: Using existing external ID: \(externalID)")
                } else {
                    let newContainer = try await subscriptionManagerV2.getTokenContainer(policy: .createIfNeeded)
                    externalID = newContainer.decodedAccessToken.externalID
                    print("SABRINA iOS: Created new external ID: \(externalID)")
                }
                
                print("SABRINA iOS: Starting purchase with synced products...")
                let result = await subscriptionManagerV2.storePurchaseManager().purchaseSubscription(with: productID, externalID: externalID)
                
                switch result {
                case .success(let transactionJWS):
                    print("SABRINA iOS: Purchase SUCCESS for \(description)")
                case .failure(let error):
                    print("SABRINA iOS: Purchase FAILED for \(description): \(error)")
                }
            } catch {
                print("SABRINA iOS: Purchase ERROR for \(description): \(error)")
            }
        }
    }
    
    // Debug function to show available products (V2 only)
    private func showAvailableProducts() {
        Task {
            do {
                print("SABRINA iOS: Checking available V2 products...")
                
                guard let subscriptionManagerV2 = AppDependencyProvider.shared.subscriptionManagerV2 else {
                    print("SABRINA iOS: No V2 subscription manager available")
                    return
                }
                
                // Sync first to get latest products
                print("SABRINA iOS: Syncing to get latest products...")
                try await subscriptionManagerV2.storePurchaseManager().syncAppleIDAccount()
                
                if let storePurchaseManager = subscriptionManagerV2.storePurchaseManager() as? DefaultStorePurchaseManagerV2 {
                    let products = await storePurchaseManager.getAvailableProducts()
                    print("SABRINA iOS PRODUCTS V2: Found \(products.count) products")
                    for product in products {
                        print("SABRINA iOS PRODUCT V2: ID=\(product.id), Name=\(product.displayName), Monthly=\(product.isMonthly), Yearly=\(product.isYearly)")
                    }
                } else {
                    print("SABRINA iOS: Could not cast to DefaultStorePurchaseManagerV2 for product list")
                }
            } catch {
                print("SABRINA iOS: Error getting products: \(error)")
            }
        }
    }
    
    // Debug function to show current subscription status
    private func showCurrentSubscription() {
        Task {
            do {
                print("SABRINA iOS: Checking current subscription status...")
                
                guard let subscriptionManagerV2 = AppDependencyProvider.shared.subscriptionManagerV2 else {
                    print("SABRINA iOS: No V2 subscription manager available")
                    return
                }
                
                // Sync first to get latest subscription data
                print("SABRINA iOS: Syncing to get latest subscription...")
                try await subscriptionManagerV2.storePurchaseManager().syncAppleIDAccount()
                
                // Check StoreKit entitlements
                if let storePurchaseManager = subscriptionManagerV2.storePurchaseManager() as? DefaultStorePurchaseManagerV2 {
                    let purchasedIDs = storePurchaseManager.purchasedProductIDs
                    print("SABRINA iOS CURRENT: Found \(purchasedIDs.count) active StoreKit subscriptions")
                    for (index, productID) in purchasedIDs.enumerated() {
                        print("SABRINA iOS CURRENT \(index + 1): \(productID)")
                    }
                    
                    // Show external ID used for this account
                    if let externalID = try? await subscriptionManagerV2.getTokenContainer(policy: .local).decodedAccessToken.externalID {
                        print("SABRINA iOS CURRENT: External ID (appAccountToken): \(externalID)")
                    }
                }
                
                // Check backend subscription
                do {
                    let subscription = try await subscriptionManagerV2.getSubscription(cachePolicy: .remoteFirst)
                    print("SABRINA iOS BACKEND: Subscription found")
                    print("SABRINA iOS BACKEND: Product ID: \(subscription.productId ?? "nil")")
                    print("SABRINA iOS BACKEND: Status: \(subscription.status)")
                    print("SABRINA iOS BACKEND: Platform: \(subscription.platform)")
                    print("SABRINA iOS BACKEND: Billing Period: \(subscription.billingPeriod)")
                    print("SABRINA iOS BACKEND: Started: \(subscription.startedAt)")
                    print("SABRINA iOS BACKEND: Expires: \(subscription.expiresOrRenewsAt)")
                } catch {
                    print("SABRINA iOS BACKEND: No subscription found or error: \(error)")
                }
                
                // Check authentication
                print("SABRINA iOS AUTH: Is authenticated: \(subscriptionManagerV2.isUserAuthenticated)")
                if let email = subscriptionManagerV2.userEmail {
                    print("SABRINA iOS AUTH: Email: \(email)")
                } else {
                    print("SABRINA iOS AUTH: No email found")
                }
                
            } catch {
                print("SABRINA iOS: Error checking current subscription: \(error)")
            }
        }
    }
    
    // Debug function to show all StoreKit transactions
    private func showAllTransactions() {
        Task {
            do {
                if #available(iOS 15.0, *) {
                    print("SABRINA iOS: === ALL TRANSACTIONS DEBUG ===")
                    
                    guard let subscriptionManagerV2 = AppDependencyProvider.shared.subscriptionManagerV2 else {
                        print("SABRINA iOS: No V2 subscription manager available")
                        return
                    }
                    
                    // Sync first
                    print("SABRINA iOS: Syncing for transaction data...")
                    try await subscriptionManagerV2.storePurchaseManager().syncAppleIDAccount()
                    
                    // Show current entitlements (active subscriptions)
                    print("SABRINA iOS: === CURRENT ENTITLEMENTS ===")
                    var entitlementCount = 0
                    for await result in Transaction.currentEntitlements {
                        entitlementCount += 1
                        print("SABRINA ENTITLEMENT \(entitlementCount): Processing...")
                        print("SABRINA \(result)")

                        switch result {
                        case .verified(let transaction):
                            print("  ✅ VERIFIED")
                            print("  Product ID: \(transaction.productID)")
                            print("  Transaction ID: \(transaction.id)")
                            print("  Purchase Date: \(transaction.purchaseDate)")
                            if let expiration = transaction.expirationDate {
                                print("  Expiration Date: \(expiration)")
                            } else {
                                print("  Expiration Date: nil")
                            }
                            print("  Is Upgraded: \(transaction.isUpgraded)")
                            if let revocation = transaction.revocationDate {
                                print("  Revocation Date: \(revocation)")
                            } else {
                                print("  Revocation Date: nil (active)")
                            }
                            if let appToken = transaction.appAccountToken {
                                print("  App Account Token: \(appToken)")
                            } else {
                                print("  App Account Token: nil")
                            }
                        case .unverified(let unverifiedTransaction, let error):
                            print("  ❌ UNVERIFIED - Error: \(error)")
                            print("  Product ID: \(unverifiedTransaction.productID)")
                        }
                    }
                    print("SABRINA iOS: Total current entitlements: \(entitlementCount)")
                    
                    // Show all transactions (including expired/cancelled)
                    print("SABRINA iOS: === ALL TRANSACTIONS ===")
                    var allTransactionCount = 0
                    for await result in Transaction.all {
                        allTransactionCount += 1
                        print("SABRINA TRANSACTION \(allTransactionCount): Processing...")
                        
                        switch result {
                        case .verified(let transaction):
                            print("  ✅ VERIFIED")
                            print("  Product ID: \(transaction.productID)")
                            print("  Transaction ID: \(transaction.id)")
                            print("  Purchase Date: \(transaction.purchaseDate)")
                            print("  Purchase Date: \(transaction.purchaseDate)")
                            if let expiration = transaction.expirationDate {
                                print("  Expiration Date: \(expiration)")
                            } else {
                                print("  Expiration Date: nil")
                            }
                            print("  Is Upgraded: \(transaction.isUpgraded)")
                            if let revocation = transaction.revocationDate {
                                print("  Revocation Date: \(revocation)")
                            } else {
                                print("  Revocation Date: nil (active)")
                            }
                            if let appToken = transaction.appAccountToken {
                                print("  App Account Token: \(appToken)")
                            } else {
                                print("  App Account Token: nil")
                            }
                        case .unverified(let unverifiedTransaction, let error):
                            print("  ❌ UNVERIFIED - Error: \(error)")
                            print("  Product ID: \(unverifiedTransaction.productID)")
                        }
                        
                        // Limit output to prevent spam
                        if allTransactionCount >= 10 {
                            print("SABRINA iOS: Limiting to first 10 transactions...")
                            break
                        }
                    }
                    print("SABRINA iOS: Total transactions checked: \(allTransactionCount)")
                } else {
                    print("SABRINA iOS: StoreKit 2 not available (iOS 15+ required)")
                }
                
            } catch {
                print("SABRINA iOS: Error getting transactions: \(error)")
            }
        }
    }

    var subscriptionRestoreView: some View {
        SubscriptionContainerViewFactory.makeRestoreFlow(navigationCoordinator: subscriptionNavigationCoordinator,
                                                         subscriptionManager: AppDependencyProvider.shared.subscriptionManager!,
                                                         subscriptionFeatureAvailability: settingsViewModel.subscriptionFeatureAvailability,
                                                         internalUserDecider: AppDependencyProvider.shared.internalUserDecider,
                                                         dataBrokerProtectionViewControllerProvider: settingsViewModel.dataBrokerProtectionViewControllerProvider)
    }

    var subscriptionRestoreViewV2: some View {
        SubscriptionContainerViewFactory.makeRestoreFlowV2(navigationCoordinator: subscriptionNavigationCoordinator,
                                                           subscriptionManager: AppDependencyProvider.shared.subscriptionManagerV2!,
                                                           subscriptionFeatureAvailability: settingsViewModel.subscriptionFeatureAvailability,
                                                           internalUserDecider: AppDependencyProvider.shared.internalUserDecider,
                                                           wideEvent: AppDependencyProvider.shared.wideEvent,
                                                           dataBrokerProtectionViewControllerProvider: settingsViewModel.dataBrokerProtectionViewControllerProvider)
    }

    private var manageSubscriptionView: some View {
        SettingsCellView(
            label: UserText.settingsPProManageSubscription,
            image: Image(uiImage: DesignSystemImages.Color.Size24.subscription)
        )
    }

    var currentStorefrontRegion: SubscriptionRegion {
        if !settingsViewModel.isAuthV2Enabled {
            return AppDependencyProvider.shared.subscriptionManager!.storePurchaseManager().currentStorefrontRegion
        } else {
            return AppDependencyProvider.shared.subscriptionManagerV2!.storePurchaseManager().currentStorefrontRegion
        }
    }
    
    private var winBackURLComponents: URLComponents? {
        SubscriptionURL.purchaseURLComponentsWithOriginAndFeaturePage(
            origin: SubscriptionFunnelOrigin.winBackSettings.rawValue,
            featurePage: SubscriptionURL.FeaturePage.winback
        )
    }
    
    @ViewBuilder
    private var resubscribeWithWinbackOfferView: some View {
        Group {
            let titleText: String = UserText.winBackCampaignSubscriptionSettingsMenuTitle
            let subtitleText = UserText.winBackCampaignSubscriptionSettingsMenuSubtitle

            SettingsCellView(label: titleText,
                             subtitle: subtitleText,
                             image: Image(uiImage: DesignSystemImages.Color.Size24.subscription))
            .disabled(true)

            // See Offer
            SettingsCustomCell(content: {
                Text(UserText.winBackCampaignSubscriptionSettingsMenuCTA)
                    .daxBodyRegular()
                    .foregroundColor(Color.init(designSystemColor: .accent))
                    .padding(.leading, 32.0)
            }, action: {
                Pixel.fire(pixel: .subscriptionWinBackOfferSettingsLoggedOutOfferCTAClicked)
                subscriptionNavigationCoordinator.redirectURLComponents = winBackURLComponents
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            }, isButton: true, shouldShowWinBackOffer: true)

            // Restore subscription
            if !settingsViewModel.isAuthV2Enabled {
                let restoreView = subscriptionRestoreView
                    .navigationViewStyle(.stack)
                    .onFirstAppear {
                        Pixel.fire(pixel: .subscriptionRestorePurchaseClick)
                    }
                NavigationLink(destination: restoreView,
                               isActive: $isShowingRestoreFlow) {
                    SettingsCellView(label: UserText.settingsPProIHaveASubscription).padding(.leading, 32.0)
                }
            } else {
                let restoreView = subscriptionRestoreViewV2
                    .navigationViewStyle(.stack)
                    .onFirstAppear {
                        Pixel.fire(pixel: .subscriptionRestorePurchaseClick)
                    }
                NavigationLink(destination: restoreView,
                               isActive: $isShowingRestoreFlow) {
                    SettingsCellView(label: UserText.settingsPProIHaveASubscription).padding(.leading, 32.0)
                }
            }
        }
        .onFirstAppear {
            Pixel.fire(pixel: .subscriptionWinBackOfferSettingsLoggedOutOfferShown)
        }
    }

    @ViewBuilder
    private var purchaseSubscriptionView: some View {
        Group {
            let isPaidAIChatEnabled = settingsViewModel.isPaidAIChatEnabled
            let titleText: String = UserText.settingsSubscription(isPaidAIChatEnabled: isPaidAIChatEnabled)
            let subtitleText: String = {
                switch currentStorefrontRegion {
                case .usa:
                    return UserText.settingsSubscriptionDescription(isPaidAIChatEnabled: isPaidAIChatEnabled, isUS: true)
                case .restOfWorld:
                    return UserText.settingsSubscriptionDescription(isPaidAIChatEnabled: isPaidAIChatEnabled, isUS: false)
                }
            }()

            SettingsCellView(label: titleText,
                             subtitle: subtitleText,
                             image: Image(uiImage: DesignSystemImages.Color.Size24.subscription))
            .disabled(true)

            // Get Subscription
            let getText = settingsViewModel.state.subscription.isEligibleForTrialOffer ? UserText.trySubscriptionButton : UserText.getSubscriptionButton
            SettingsCustomCell(content: {
                Text(getText)
                    .daxBodyRegular()
                    .foregroundColor(Color.init(designSystemColor: .accent))
                    .padding(.leading, 32.0)
            }, action: {
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            }, isButton: true)

            // Restore subscription
            if !settingsViewModel.isAuthV2Enabled {
                let restoreView = subscriptionRestoreView
                    .navigationViewStyle(.stack)
                    .onFirstAppear {
                        Pixel.fire(pixel: .subscriptionRestorePurchaseClick)
                    }
                NavigationLink(destination: restoreView,
                               isActive: $isShowingRestoreFlow) {
                    SettingsCellView(label: UserText.settingsPProIHaveASubscription).padding(.leading, 32.0)
                }
            } else {
                let restoreView = subscriptionRestoreViewV2
                    .navigationViewStyle(.stack)
                    .onFirstAppear {
                        Pixel.fire(pixel: .subscriptionRestorePurchaseClick)
                    }
                NavigationLink(destination: restoreView,
                               isActive: $isShowingRestoreFlow) {
                    SettingsCellView(label: UserText.settingsPProIHaveASubscription).padding(.leading, 32.0)
                }
            }
        }
    }

    @ViewBuilder
    private var disabledFeaturesView: some View {
        let subscriptionFeatures = settingsViewModel.state.subscription.subscriptionFeatures

        if subscriptionFeatures.contains(.networkProtection) {
            SettingsCellView(label: UserText.settingsPProVPNTitle,
                             image: Image(uiImage: DesignSystemImages.Color.Size24.vpn),
                             statusIndicator: StatusIndicatorView(status: .off),
                             isGreyedOut: true
            )
        }

        if subscriptionFeatures.contains(.dataBrokerProtection) {
            SettingsCellView(
                label: UserText.settingsPProDBPTitle,
                image: Image(uiImage: DesignSystemImages.Color.Size24.databroker),
                statusIndicator: StatusIndicatorView(status: .off),
                isGreyedOut: true
            )
        }

        if subscriptionFeatures.contains(.paidAIChat) && settingsViewModel.isPaidAIChatEnabled && settingsViewModel.isAuthV2Enabled {
            SettingsCellView(
                label: UserText.settingsSubscriptionAiChatTitle,
                image: Image(uiImage: DesignSystemImages.Color.Size24.aiChat),
                statusIndicator: StatusIndicatorView(status: .off),
                isGreyedOut: true,
                isNew: true
            )
        }

        if subscriptionFeatures.contains(.identityTheftRestoration) || subscriptionFeatures.contains(.identityTheftRestorationGlobal) {
            SettingsCellView(
                label: UserText.settingsPProITRTitle,
                image: Image(uiImage: DesignSystemImages.Color.Size24.identityTheftRestoration),
                statusIndicator: StatusIndicatorView(status: .off),
                isGreyedOut: true
            )
        }
    }

    @ViewBuilder
    private var subscriptionExpiredView: some View {
        disabledFeaturesView

        // Renew Subscription (Expired)
        if !settingsViewModel.isAuthV2Enabled {
            let settingsView = SubscriptionSettingsView(configuration: SubscriptionSettingsViewConfiguration.expired,
                                                        settingsViewModel: settingsViewModel,
                                                        viewPlans: {
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            })
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.settingsPProSubscriptionExpiredTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription),
                    accessory: .image(Image(uiImage: DesignSystemImages.Color.Size16.exclamation))
                )
            }
        } else {
            let settingsView = SubscriptionSettingsViewV2(configuration: SubscriptionSettingsViewConfiguration.expired,
                                                          settingsViewModel: settingsViewModel,
                                                          viewPlans: {
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            })
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.settingsPProSubscriptionExpiredTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription),
                    accessory: .image(Image(uiImage: DesignSystemImages.Color.Size16.exclamation))
                )
            }
        }
    }

    @ViewBuilder
    private var subscribeWithWinBackOfferView: some View {
        Group {
        disabledFeaturesView

        // Subscribe with Win-back offer
        if !settingsViewModel.isAuthV2Enabled {
            let settingsView = SubscriptionSettingsView(configuration: SubscriptionSettingsViewConfiguration.expired,
                                                        settingsViewModel: settingsViewModel,
                                                        takeWinBackOffer: {
                Pixel.fire(pixel: .subscriptionWinBackOfferSubscriptionSettingsCTAClicked)
                subscriptionNavigationCoordinator.redirectURLComponents = winBackURLComponents
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            }).onFirstAppear {
                Pixel.fire(pixel: .subscriptionWinBackOfferSubscriptionSettingsShown)
            }
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.winBackCampaignSubscriptionSettingsMenuLoggedOutSubtitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription),
                    shouldShowWinBackOffer: true
                )
            }
        } else {
            let settingsView = SubscriptionSettingsViewV2(configuration: SubscriptionSettingsViewConfiguration.expired,
                                                          settingsViewModel: settingsViewModel,
                                                          takeWinBackOffer: {
                Pixel.fire(pixel: .subscriptionWinBackOfferSubscriptionSettingsCTAClicked)
                subscriptionNavigationCoordinator.redirectURLComponents = winBackURLComponents
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            }).onFirstAppear {
                Pixel.fire(pixel: .subscriptionWinBackOfferSubscriptionSettingsShown)
            }
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.winBackCampaignSubscriptionSettingsMenuLoggedOutSubtitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription),
                    shouldShowWinBackOffer: true
                )
            }
        }
        }
        .onFirstAppear {
            Pixel.fire(pixel: .subscriptionWinBackOfferSettingsLoggedInOfferShown)
        }
    }

    @ViewBuilder
    private var missingSubscriptionOrEntitlementsView: some View {
        disabledFeaturesView

        // Renew Subscription (Expired)
        if !settingsViewModel.isAuthV2Enabled {
            let settingsView = SubscriptionSettingsView(configuration: SubscriptionSettingsViewConfiguration.activating,
                                                        settingsViewModel: settingsViewModel,
                                                        viewPlans: {
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            })
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.settingsPProActivating,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription)
                )
            }
        } else {
            let settingsView = SubscriptionSettingsViewV2(configuration: SubscriptionSettingsViewConfiguration.activating,
                                                          settingsViewModel: settingsViewModel,
                                                          viewPlans: {
                subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = true
            })
                .environmentObject(subscriptionNavigationCoordinator)
            NavigationLink(destination: settingsView) {
                SettingsCellView(
                    label: UserText.settingsPProManageSubscription,
                    subtitle: UserText.settingsPProActivating,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.subscription)
                )
            }
        }
    }

    @ViewBuilder
    private var subscriptionDetailsView: some View {
        let subscriptionFeatures = settingsViewModel.state.subscription.subscriptionFeatures
        let userEntitlements = settingsViewModel.state.subscription.entitlements

        if subscriptionFeatures.contains(.networkProtection) {
            let hasVPNEntitlement = userEntitlements.contains(.networkProtection)
            let isVPNConnected = settingsViewModel.state.networkProtectionConnected

            NavigationLink(destination: LazyView(NetworkProtectionRootView()), isActive: $isShowingVPN) {
                SettingsCellView(
                    label: UserText.settingsPProVPNTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.vpn),
                    statusIndicator: StatusIndicatorView(status: isVPNConnected ? .on : .off),
                    isGreyedOut: !hasVPNEntitlement
                )
            }
            .disabled(!hasVPNEntitlement)
        }

        if subscriptionFeatures.contains(.dataBrokerProtection) {
            let hasDBPEntitlement = userEntitlements.contains(.dataBrokerProtection)
            let hasValidStoredProfile = settingsViewModel.dbpMeetsProfileRunPrequisite
            var statusIndicator: StatusIndicator = hasDBPEntitlement && hasValidStoredProfile ? .on : .off

            let destination: LazyView<AnyView> = {
                if settingsViewModel.isPIREnabled, let vcProvider = settingsViewModel.dataBrokerProtectionViewControllerProvider {
                    return LazyView(AnyView(DataBrokerProtectionViewControllerRepresentation(dbpViewControllerProvider: vcProvider)
                        .edgesIgnoringSafeArea(.bottom)))
                } else {
                    statusIndicator = .on
                    return LazyView(AnyView(SubscriptionPIRMoveToDesktopView()))
                }
            }()

            NavigationLink(destination: destination, isActive: $isShowingDBP) {
                SettingsCellView(
                    label: UserText.settingsPProDBPTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.identity),
                    statusIndicator: StatusIndicatorView(status: statusIndicator),
                    isGreyedOut: !hasDBPEntitlement
                )
            }
            .disabled(!hasDBPEntitlement)
        }

        if subscriptionFeatures.contains(.paidAIChat) && settingsViewModel.isPaidAIChatEnabled && settingsViewModel.isAuthV2Enabled {
            let hasAIChatEntitlement = userEntitlements.contains(.paidAIChat)

            NavigationLink(destination: LazyView(SubscriptionAIChatView(viewModel: settingsViewModel)), isActive: $isShowingPaidAIChat) {
                SettingsCellView(
                    label: UserText.settingsSubscriptionAiChatTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.aiChat),
                    statusIndicator: StatusIndicatorView(status: (hasAIChatEntitlement && settingsViewModel.isAIChatEnabled) ? .on : .off),
                    isGreyedOut: !hasAIChatEntitlement,
                    isNew: true
                )
            }
            .disabled(!hasAIChatEntitlement)
        }

        if subscriptionFeatures.contains(.identityTheftRestoration) || subscriptionFeatures.contains(.identityTheftRestorationGlobal) {
            let hasITREntitlement = userEntitlements.contains(.identityTheftRestoration) || userEntitlements.contains(.identityTheftRestorationGlobal)

            NavigationLink(destination: LazyView(SubscriptionITPView()), isActive: $isShowingITP) {
                SettingsCellView(
                    label: UserText.settingsPProITRTitle,
                    image: Image(uiImage: DesignSystemImages.Color.Size24.identityTheftRestoration),
                    statusIndicator: StatusIndicatorView(status: hasITREntitlement ? .on : .off),
                    isGreyedOut: !hasITREntitlement
                )
            }
            .disabled(!hasITREntitlement)
        }

        let isActiveTrialOffer = settingsViewModel.state.subscription.isActiveTrialOffer
        let configuration: SubscriptionSettingsViewConfiguration = isActiveTrialOffer ? .trial : .subscribed

        if !settingsViewModel.isAuthV2Enabled {
            NavigationLink(destination: LazyView(SubscriptionSettingsView(configuration: configuration, settingsViewModel: settingsViewModel))
                .environmentObject(subscriptionNavigationCoordinator)
            ) {
                SettingsCustomCell(content: { manageSubscriptionView })
            }
        } else {
            NavigationLink(destination: LazyView(SubscriptionSettingsViewV2(configuration: configuration, settingsViewModel: settingsViewModel))
                .environmentObject(subscriptionNavigationCoordinator)
            ) {
                SettingsCustomCell(content: { manageSubscriptionView })
            }
        }
    }
        
    var body: some View {
        Group {
            if isShowingSubscription {

                let isSignedIn = settingsViewModel.state.subscription.isSignedIn
                let hasSubscription = settingsViewModel.state.subscription.hasSubscription
                let hasActiveSubscription = settingsViewModel.state.subscription.hasActiveSubscription
                let hasAnyEntitlements = !settingsViewModel.state.subscription.entitlements.isEmpty
                let isWinBackEligible = settingsViewModel.state.subscription.isWinBackEligible

                let footerLink = Link(UserText.settingsPProSectionFooter,
                                      destination: ViewConstants.privacyPolicyURL)
                    .daxFootnoteRegular().accentColor(Color.init(designSystemColor: .accent))

                Section(header: Text(UserText.settingsSubscriptionSection),
                        footer: !isSignedIn ? footerLink : nil
                ) {

                    switch (isSignedIn, hasSubscription, hasActiveSubscription, hasAnyEntitlements) {

                    // Signed out, Eligible for Win-back offer
                    case (false, _, _, _) where isWinBackEligible:
                        resubscribeWithWinbackOfferView
                        
                    // Signed out
                    case (false, _, _, _):
                        purchaseSubscriptionView

                    // Signed In, Subscription Missing
                    case (true, false, _, _):
                        missingSubscriptionOrEntitlementsView

                    // Subscription Expired, Eligible for Win-back offer
                    case (true, true, false, _) where isWinBackEligible:
                        subscribeWithWinBackOfferView
                        
                    // Signed In, Subscription Present & Not Active
                    case (true, true, false, _):
                        subscriptionExpiredView

                    // Signed in, Subscription Present & Active, Missing Entitlements
                    case (true, true, true, false):
                        missingSubscriptionOrEntitlementsView

                    // Signed in, Subscription Present & Active, Valid entitlements
                    case (true, true, true, true):
                        subscriptionDetailsView
                    }
                }
                .onReceive(subscriptionNavigationCoordinator.$shouldPopToAppSettings) { shouldDismiss in
                    if shouldDismiss {
                        isShowingRestoreFlow = false
                        subscriptionNavigationCoordinator.shouldPushSubscriptionWebView = false
                    }
                }
            }
        }
        
        // DEBUG SECTION: Always visible upgrade testing  
        debugUpgradeTestingSection
        
        .onReceive(settingsViewModel.$state) { state in
            isShowingSubscription = (state.subscription.isSignedIn || state.subscription.canPurchase)
        }
    }
}

// MARK: - Debug Extension for Upgrade Testing
extension SettingsSubscriptionView {
    
    // This creates a separate, always-visible debug section
    var debugUpgradeTestingSection: some View {
        Section("🧪 Debug: Upgrade Testing") {
            Button("Show Current Subscription") {
                showCurrentSubscription()
            }
            
            Button("Show All Transactions") {
                showAllTransactions()
            }
            
            Button("Show Available Products") {
                showAvailableProducts()
            }
            
            Group {
                Text("Free Trial Products:").font(.caption)
                Button("Test Purchase Yearly Free Trial") {
                    testDirectPurchase(productID: "ios.subscription.1year.freetrial.dev", description: "Yearly Free Trial")
                }
                Button("Test Purchase Monthly Free Trial") {  
                    testDirectPurchase(productID: "ios.subscription.1month.freetrial.dev", description: "Monthly Free Trial")
                }
                
                Text("Regular Products:").font(.caption).padding(.top)
                Button("Test Purchase Privacy Pro Annual") {
                    testDirectPurchase(productID: "ios.subscription.1year.row", description: "Privacy Pro Annual")
                }
                Button("Test Purchase Privacy Pro Monthly") {  
                    testDirectPurchase(productID: "ios.subscription.1month.row", description: "Privacy Pro Monthly")
                }
            }
        }
    }
}
