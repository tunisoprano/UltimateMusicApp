//
//  StoreKitManager.swift
//  MusicTuner
//
//  Manages monthly Premium subscription using StoreKit 2
//

import Foundation
import StoreKit

/// Manages Premium subscription (auto-renewable monthly)
@MainActor
final class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StoreKitManager()
    
    // MARK: - Product ID
    /// Monthly subscription product ID — must match App Store Connect
    private let premiumMonthlyID = "com.2jam.premium.monthly"
    
    // MARK: - Published Properties
    @Published private(set) var isPremium = false
    @Published private(set) var subscriptionProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published private(set) var isLoadingProducts = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isSubscriptionActive = false
    
    /// Convenience for views that used the old name
    var removeAdsProduct: Product? { subscriptionProduct }
    
    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Initialization
    
    private init() {
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [premiumMonthlyID])

            if let product = products.first {
                subscriptionProduct = product
                errorMessage = nil
                print("✅ Subscription product loaded: \(product.displayName) - \(product.displayPrice)")
            } else {
                print("⚠️ No products returned for ID: \(premiumMonthlyID)")
                errorMessage = "Subscription not available"
            }
        } catch {
            print("⚠️ Failed to load products: \(error)")
            errorMessage = "Failed to load store products"
        }
    }
    
    // MARK: - Purchase Subscription
    
    func purchaseSubscription() async {
        guard let product = subscriptionProduct else {
            errorMessage = "Product not available"
            return
        }
        
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus(transaction)
                await transaction.finish()
                print("✅ Subscription successful!")
                
            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                
            case .pending:
                print("ℹ️ Purchase pending")
                
            @unknown default:
                break
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isPurchasing = false
    }
    
    /// Backward compatibility
    func purchaseRemoveAds() async {
        await purchaseSubscription()
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("⚠️ Restore failed: \(error)")
            errorMessage = "Restore failed"
        }
    }
    
    // MARK: - Check Subscription Status
    
    private func checkSubscriptionStatus() async {
        // Check current entitlements for active subscription
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumMonthlyID {
                    // Check if subscription is still valid (not expired, not revoked)
                    if transaction.revocationDate == nil,
                       let expDate = transaction.expirationDate, expDate > Date() {
                        isPremium = true
                        isSubscriptionActive = true
                        expirationDate = transaction.expirationDate
                        print("✅ Active subscription — expires: \(transaction.expirationDate?.formatted() ?? "unknown")")
                        return
                    }
                }
            }
        }
        
        // No active subscription found
        isPremium = false
        isSubscriptionActive = false
        expirationDate = nil
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updateSubscriptionStatus(transaction)
                    await transaction.finish()
                }
            }
        }
    }
    
    private func updateSubscriptionStatus(_ transaction: StoreKit.Transaction) async {
        if transaction.productID == premiumMonthlyID {
            let isActive = transaction.revocationDate == nil
            isPremium = isActive
            isSubscriptionActive = isActive
            expirationDate = transaction.expirationDate
        }
    }
    
    // MARK: - Manage Subscription (opens system subscription management)
    
    func manageSubscription() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            print("⚠️ Could not open subscription management: \(error)")
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
