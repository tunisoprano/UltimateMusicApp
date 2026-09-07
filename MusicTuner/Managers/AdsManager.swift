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
final class AdsManager: NSObject, ObservableObject {
    
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
    private let transitionsBeforeAd = 3
    private var lastInterstitialPresentedAt: Date?
    private let minimumIntervalBetweenInterstitials: TimeInterval = 60
    
    // MARK: - Premium Check
    var isPremium: Bool {
        StoreKitManager.shared.isPremium
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
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
        
        InterstitialAd.load(with: interstitialAdUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ Interstitial failed: \(error.localizedDescription)")
                    return
                }
                
                ad?.fullScreenContentDelegate = self
                self?.interstitialAd = ad
                self?.isInterstitialReady = true
                print("✅ Interstitial loaded")
            }
        }
    }
    
    func recordPageTransition() {
        guard !isPremium else { return }

        pageTransitionCount += 1
        guard pageTransitionCount >= transitionsBeforeAd else { return }

        // Only reset the counter once an ad actually presents. If it's not
        // ready yet (or we're still in the cooldown window), keep counting
        // so we retry on the very next transition instead of waiting for
        // another full cycle.
        if showInterstitial() {
            pageTransitionCount = 0
        }
    }

    @discardableResult
    func showInterstitial() -> Bool {
        guard !isPremium, let ad = interstitialAd else {
            // Nothing ready to show yet — make sure one is on the way.
            if isAdMobReady { loadInterstitial() }
            return false
        }

        // Client-side cooldown so back-to-back triggers (e.g. counter-based
        // navigation plus a direct post-quiz call) can't spam the user;
        // AdMob's own 5-minute frequency cap is the hard backstop.
        if let lastShown = lastInterstitialPresentedAt,
           Date().timeIntervalSince(lastShown) < minimumIntervalBetweenInterstitials {
            return false
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return false
        }

        // An interstitial can only be presented once — drop the reference
        // immediately so a second trigger before the next ad loads can't
        // try to re-present the already-used ad (which silently no-ops).
        interstitialAd = nil
        isInterstitialReady = false
        lastInterstitialPresentedAt = Date()
        ad.present(from: rootVC)
        return true
    }

    func getBannerAdUnitID() -> String {
        bannerAdUnitID
    }
}

// MARK: - FullScreenContentDelegate

extension AdsManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("⚠️ Interstitial failed to present: \(error.localizedDescription)")
        interstitialAd = nil
        isInterstitialReady = false
        loadInterstitial()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadInterstitial()
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
                    Text(L("ad_loading"))
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
