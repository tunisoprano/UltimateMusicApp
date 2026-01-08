//
//  StoreKitManager.swift
//  MusicTuner
//
//  Manages In-App Purchases using StoreKit 2
//

import Foundation
import StoreKit

/// Manages "Remove Ads" purchase using StoreKit 2
@MainActor
final class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StoreKitManager()
    
    // MARK: - Product ID
    private let removeAdsProductID = "com.musictuner.removeads"
    
    // MARK: - Published Properties
    @Published private(set) var isPremium = false
    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Initialization
    
    private init() {
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [removeAdsProductID])
            
            if let product = products.first {
                removeAdsProduct = product
                print("✅ Product loaded: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("⚠️ Failed to load products: \(error)")
            errorMessage = "Failed to load store products"
        }
    }
    
    // MARK: - Purchase
    
    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else {
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
                await updatePurchaseStatus(transaction)
                await transaction.finish()
                print("✅ Purchase successful!")
                
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
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            print("⚠️ Restore failed: \(error)")
            errorMessage = "Restore failed"
        }
    }
    
    // MARK: - Check Purchase Status
    
    private func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == removeAdsProductID {
                    isPremium = true
                    print("✅ User is premium (Remove Ads purchased)")
                    return
                }
            }
        }
        
        isPremium = false
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchaseStatus(transaction)
                    await transaction.finish()
                }
            }
        }
    }
    
    private func updatePurchaseStatus(_ transaction: StoreKit.Transaction) async {
        if transaction.productID == removeAdsProductID {
            isPremium = transaction.revocationDate == nil
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
