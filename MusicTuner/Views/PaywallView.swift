//
//  PaywallView.swift
//  MusicTuner
//
//  Premium paywall sheet: feature list, price, purchase, restore, legal links.
//  Presented from the main menu premium row and from premium-locked level cards.
//

import SwiftUI

struct PaywallView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    featureList
                    purchaseSection
                    legalSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(theme.textSecondary.opacity(0.5))
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }
                Spacer()
            }
        }
        .onChange(of: storeManager.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.orange.opacity(0.35), radius: 14, x: 0, y: 6)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Text(L("paywall_title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text(L("paywall_subtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 14) {
            featureRow(
                icon: "rectangle.slash",
                tint: .red,
                title: L("paywall_feature_ads_title"),
                subtitle: L("paywall_feature_ads_desc")
            )
            featureRow(
                icon: "lock.open.fill",
                tint: .purple,
                title: L("paywall_feature_levels_title"),
                subtitle: L("paywall_feature_levels_desc")
            )
            featureRow(
                icon: "sparkles",
                tint: .blue,
                title: L("paywall_feature_future_title"),
                subtitle: L("paywall_feature_future_desc")
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 10, x: 0, y: 5)
        )
    }

    private func featureRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.gradient)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            // Subscribe button
            Button {
                Task {
                    await storeManager.purchaseSubscription()
                }
            } label: {
                HStack(spacing: 10) {
                    if storeManager.isPurchasing || storeManager.isLoadingProducts {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 17))

                        if let product = storeManager.subscriptionProduct {
                            Text(L("paywall_cta") + " · " + product.displayPrice + " " + L("iap_per_month"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        } else {
                            Text(L("unavailable_try_later"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: .orange.opacity(0.35), radius: 10, x: 0, y: 4)
                )
            }
            .disabled(storeManager.isPurchasing || storeManager.isLoadingProducts || storeManager.subscriptionProduct == nil)

            Text(L("paywall_cancel_anytime"))
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(theme.textSecondary)

            // Error message
            if let error = storeManager.errorMessage {
                Text(error)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(theme.error)
                    .multilineTextAlignment(.center)
            }

            // Restore purchases
            Button {
                Task {
                    isRestoring = true
                    await storeManager.restorePurchases()
                    isRestoring = false
                }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text(L("iap_restore"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.accent)
                }
            }
            .disabled(isRestoring)
            .padding(.top, 4)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 10) {
            Text(L("iap_subscription_terms"))
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link(L("terms_of_use"), destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.accent)

                Link(L("privacy_policy"), destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.accent)
            }
        }
    }
}

#Preview {
    PaywallView()
}
