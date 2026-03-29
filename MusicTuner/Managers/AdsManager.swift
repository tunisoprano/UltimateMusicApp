//
//  AdsManager.swift
//  MusicTuner
//
//  Manages Banner and Interstitial ads - with safe initialization
//

import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import SwiftUI

/// Singleton for managing AdMob ads
@MainActor
final class AdsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdsManager()
    
    // MARK: - Ad Unit IDs
    private let bannerAdUnitID = "ca-app-pub-1674562447830288/4960930323"
    private let interstitialAdUnitID = "ca-app-pub-1674562447830288/9879039497"
    
    // MARK: - Published Properties
    @Published private(set) var isAdMobReady = false
    @Published private(set) var isInterstitialReady = false
    
    // MARK: - Interstitial
    private var interstitialAd: InterstitialAd?
    private var pageTransitionCount = 0
    private let transitionsBeforeAd = 4
    
    // MARK: - Premium Check
    var isPremium: Bool {
        StoreKitManager.shared.isPremium
    }
    
    // MARK: - Initialization
    private init() {
        // Do NOT call MobileAds.shared.start() here
        // It will be called later after ATT permission + app is fully loaded
    }
    
    /// Request ATT permission first, then initialize AdMob SDK.
    /// Call this from App's onAppear or after a delay.
    func requestTrackingAndInitialize() async {
        guard !isAdMobReady else { return }
        
        // Skip ads entirely for premium users
        guard !isPremium else { return }
        
        // Request App Tracking Transparency permission
        _ = await TrackingManager.shared.requestTrackingPermission()
        
        // Initialize AdMob after ATT response (regardless of user choice)
        initializeAdMob()
    }
    
    /// Initialize AdMob SDK (called after ATT permission is handled)
    private func initializeAdMob() {
        guard !isAdMobReady else { return }
        
        MobileAds.shared.start { [weak self] status in
            DispatchQueue.main.async {
                self?.isAdMobReady = true
                print("✅ AdMob SDK initialized")
                self?.loadInterstitial()
            }
        }
    }
    
    // MARK: - Interstitial Ads
    
    func loadInterstitial() {
        guard !isPremium, isAdMobReady else { return }
        
        InterstitialAd.load(with: interstitialAdUnitID) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ Interstitial failed: \(error.localizedDescription)")
                    return
                }
                
                self?.interstitialAd = ad
                self?.isInterstitialReady = true
                print("✅ Interstitial loaded")
            }
        }
    }
    
    func recordPageTransition() {
        guard !isPremium else { return }
        
        pageTransitionCount += 1
        
        if pageTransitionCount >= transitionsBeforeAd {
            showInterstitial()
            pageTransitionCount = 0
        }
    }
    
    func showInterstitial() {
        guard !isPremium, let ad = interstitialAd else { return }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        ad.present(from: rootVC)
        isInterstitialReady = false
        loadInterstitial()
    }
    
    func getBannerAdUnitID() -> String {
        bannerAdUnitID
    }
}

// MARK: - Banner Ad View

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - Banner Container (shows placeholder until AdMob ready)

struct AdBannerContainer: View {
    @ObservedObject private var adsManager = AdsManager.shared
    @ObservedObject private var storeManager = StoreKitManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        if !storeManager.isPremium {
            if adsManager.isAdMobReady {
                BannerAdView(adUnitID: adsManager.getBannerAdUnitID())
                    .frame(height: 50)
            } else {
                // Placeholder while loading
                HStack {
                    Image(systemName: "rectangle.badge.plus")
                        .font(.system(size: 14))
                    Text("Ad Loading...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(theme.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.cardBackground)
            }
        }
    }
}
