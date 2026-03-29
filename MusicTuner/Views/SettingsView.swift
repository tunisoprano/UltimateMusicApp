//
//  SettingsView.swift
//  MusicTuner
//
//  Settings with dynamic version, restore purchases, and sound settings
//

import SwiftUI

// MARK: - App Version Helper

/// Helper to read app version from Bundle
struct AppVersion {
    /// App version (e.g., "1.2.0") from CFBundleShortVersionString
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Build number (e.g., "42") from CFBundleVersion
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Full version string: "1.2.0 (Build 42)"
    static var fullVersion: String {
        "\(version) (Build \(build))"
    }
}

// MARK: - User Preferences

/// Global user preferences stored in AppStorage
enum UserPreferences {
    @AppStorage("successSoundEnabled") static var successSoundEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") static var hapticFeedbackEnabled: Bool = true
}

/// Settings screen with theme picker, note naming, sound settings, and restore purchases
struct SettingsView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @AppStorage("noteNamingStyle") private var noteNamingStyle: String = NoteNamingStyle.english.rawValue
    @AppStorage("successSoundEnabled") private var successSoundEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    
    // Local state for immediate preview updates
    @State private var localNamingStyle: NoteNamingStyle = .english
    @State private var isRestoring: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Language Section
                    SettingsSectionCard(title: L10n.language) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                    .foregroundStyle(theme.accent)
                                    .frame(width: 28)
                                
                                Text(L10n.language)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                                
                                Spacer()
                            }
                            
                            // Language Picker
                            HStack(spacing: 12) {
                                ForEach(Language.allCases) { lang in
                                    LanguageOptionButton(
                                        language: lang,
                                        isSelected: languageManager.language == lang,
                                        theme: theme
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            languageManager.language = lang
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Appearance Section
                    SettingsSectionCard(title: L10n.appearance) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: theme.currentTheme.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(theme.accent)
                                    .frame(width: 28)
                                
                                Text(L10n.theme)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                                
                                Spacer()
                            }
                            
                            // Theme Picker
                            HStack(spacing: 12) {
                                ForEach(AppTheme.allCases) { themeOption in
                                    ThemeOptionButton(
                                        option: themeOption,
                                        isSelected: theme.currentTheme == themeOption,
                                        theme: theme
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            theme.currentTheme = themeOption
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Note Naming Section
                    SettingsSectionCard(title: "Note Naming") {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Display Style")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                                
                                Picker("Style", selection: $localNamingStyle) {
                                    ForEach(NoteNamingStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: localNamingStyle) { _, newValue in
                                    noteNamingStyle = newValue.rawValue
                                    NoteFormatter.style = newValue
                                }
                            }
                            
                            // Live Preview
                            VStack(spacing: 12) {
                                Text("Preview")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                                
                                HStack(spacing: 8) {
                                    ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { note in
                                        NotePreviewBadge(note: note, style: localNamingStyle)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sound & Feedback Section
                    SettingsSectionCard(title: "Sound & Feedback") {
                        VStack(spacing: 16) {
                            Toggle(isOn: $successSoundEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Success Sound")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.textPrimary)
                                        Text("Play ding when tuned")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                            }
                            .tint(theme.accent)
                            
                            Divider()
                                .background(theme.inactive.opacity(0.3))
                            
                            Toggle(isOn: $hapticFeedbackEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .font(.system(size: 18))
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Haptic Feedback")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.textPrimary)
                                        Text("Vibrate when tuned")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                            }
                            .tint(theme.accent)
                        }
                    }
                    
                    // Subscription Section
                    SettingsSectionCard(title: L("iap_purchases")) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: storeManager.isPremium ? "checkmark.seal.fill" : "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(storeManager.isPremium ? theme.success : theme.warning)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("iap_premium_status"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.textPrimary)
                                    
                                    if storeManager.isPremium, let expDate = storeManager.expirationDate {
                                        Text(L("iap_renews_on") + " " + expDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    } else {
                                        Text(storeManager.isPremium ? L("iap_ads_removed") : L("iap_free_version"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if storeManager.isPremium {
                                    Text(L("iap_active"))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(theme.success))
                                }
                            }
                            
                            // Subscribe Button (only when not premium)
                            if !storeManager.isPremium {
                                Divider()
                                    .background(theme.inactive.opacity(0.3))
                                
                                Button {
                                    Task {
                                        await storeManager.purchaseSubscription()
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        if storeManager.isPurchasing {
                                            ProgressView()
                                                .frame(width: 28)
                                        } else {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.white)
                                                .frame(width: 28)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(L("iap_subscribe"))
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text(L("iap_subscribe_desc"))
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        if let product = storeManager.subscriptionProduct {
                                            VStack(spacing: 2) {
                                                Text(product.displayPrice)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)
                                                Text(L("iap_per_month"))
                                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(.white.opacity(0.2))
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                                            .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 4)
                                    )
                                }
                                .disabled(storeManager.isPurchasing || storeManager.subscriptionProduct == nil)
                                
                                // Subscription legal text
                                Text(L("iap_subscription_terms"))
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                                
                                // Legal Links
                                HStack(spacing: 16) {
                                    Link(L("terms_of_use"), destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.accent)
                                    
                                    Link(L("privacy_policy"), destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.accent)
                                }
                                
                                // Error message
                                if let error = storeManager.errorMessage {
                                    Text(error)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(theme.error)
                                }
                            }
                            
                            // Manage Subscription (when premium)
                            if storeManager.isPremium {
                                Divider()
                                    .background(theme.inactive.opacity(0.3))
                                
                                Button {
                                    Task {
                                        await storeManager.manageSubscription()
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(theme.accent)
                                            .frame(width: 28)
                                        
                                        Text(L("iap_manage_subscription"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 13))
                                            .foregroundStyle(theme.inactive)
                                    }
                                }
                            }
                            
                            Divider()
                                .background(theme.inactive.opacity(0.3))
                            
                            // Restore Purchases Button
                            Button {
                                Task {
                                    isRestoring = true
                                    await storeManager.restorePurchases()
                                    isRestoring = false
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    if isRestoring {
                                        ProgressView()
                                            .frame(width: 28)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 18))
                                            .foregroundStyle(theme.accent)
                                            .frame(width: 28)
                                    }
                                    
                                    Text(L("iap_restore"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(theme.inactive)
                                }
                            }
                            .disabled(isRestoring)
                        }
                    }
                    
                    // About Section
                    SettingsSectionCard(title: L("about")) {
                        VStack(spacing: 16) {
                            HStack {
                                Text(L("version"))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                                Spacer()
                                Text(AppVersion.version)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            
                            HStack {
                                Text(L("build"))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                                Spacer()
                                Text(AppVersion.build)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            
                            Divider()
                                .background(theme.inactive.opacity(0.3))
                            
                            // Privacy Policy
                            Link(destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 28)
                                    
                                    Text(L("privacy_policy"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(theme.inactive)
                                }
                            }
                            
                            Divider()
                                .background(theme.inactive.opacity(0.3))
                            
                            // Terms of Use
                            Link(destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 28)
                                    
                                    Text(L("terms_of_use"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(theme.inactive)
                                }
                            }
                        }
                    }
                    
                    // Footer
                    VStack(spacing: 4) {
                        Text("Made by Tuni")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                        Text("Version \(AppVersion.fullVersion)")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(theme.inactive)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .onAppear {
            localNamingStyle = NoteNamingStyle(rawValue: noteNamingStyle) ?? .english
        }
    }
}

// MARK: - Settings Section Card

struct SettingsSectionCard<Content: View>: View {
    @ObservedObject var theme = ThemeManager.shared
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadow, radius: 12, x: 0, y: 6)
            )
        }
    }
}

// MARK: - Theme Option Button

struct ThemeOptionButton: View {
    let option: AppTheme
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                Text(option.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isSelected ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .stroke(isSelected ? Color.clear : theme.inactive.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Language Option Button

struct LanguageOptionButton: View {
    let language: Language
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 24))
                Text(language.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isSelected ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .stroke(isSelected ? Color.clear : theme.inactive.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Note Preview Badge

struct NotePreviewBadge: View {
    @ObservedObject var theme = ThemeManager.shared
    let note: String
    let style: NoteNamingStyle
    
    private var displayNote: String {
        if style == .solfege {
            let solfegeMap: [String: String] = [
                "C": "Do", "D": "Re", "E": "Mi", "F": "Fa",
                "G": "Sol", "A": "La", "B": "Si"
            ]
            return solfegeMap[note] ?? note
        }
        return note
    }
    
    var body: some View {
        Text(displayNote)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(theme.textPrimary)
            .frame(width: 36, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.accent.opacity(0.15))
            )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
