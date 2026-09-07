//
//  SettingsView.swift
//  MusicTuner
//
//  Settings with dynamic version, restore purchases, and sound settings
//  "Playful Premium" acid/black theme — matches Tuner/Metronome/Chord Library.
//

import SwiftUI

// MARK: - Acid/black palette for this screen

private enum STheme {
    static let background = Color(hex: "131313")
    static let card = Color(hex: "1F1F1F")
    static let border = Color(hex: "353534")
    static let acid = Color(hex: "E1EC00")
    static let textOnAcid = Color(hex: "303300")
    static let textPrimary = Color(hex: "E2E2E2")
    static let textSecondary = Color(hex: "929277")
    static let success = Color(hex: "4ADE80")
    static let warning = Color(hex: "FFC94A")
    static let error = Color(hex: "FF5A5A")
}

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
    @AppStorage("handsFreeModeEnabled") static var handsFreeModeEnabled: Bool = false
    @AppStorage("showLessonPreview") static var showLessonPreview: Bool = true
}

/// Settings screen with theme picker, note naming, sound settings, and restore purchases
struct SettingsView: View {
    @ObservedObject var storeManager = StoreKitManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @AppStorage("noteNamingStyle") private var noteNamingStyle: String = NoteNamingStyle.english.rawValue
    @AppStorage("successSoundEnabled") private var successSoundEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("handsFreeModeEnabled") private var handsFreeModeEnabled: Bool = false
    @AppStorage("showLessonPreview") private var showLessonPreview: Bool = true

    // Local state for immediate preview updates
    @State private var localNamingStyle: NoteNamingStyle = .english
    @State private var isRestoring: Bool = false

    var body: some View {
        ZStack {
            STheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Language Section
                    SettingsSectionCard(title: L10n.language) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                    .foregroundStyle(STheme.acid)
                                    .frame(width: 28)

                                Text(L10n.language)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(STheme.textPrimary)

                                Spacer()
                            }

                            // Language Picker
                            HStack(spacing: 12) {
                                ForEach(Language.allCases) { lang in
                                    LanguageOptionButton(
                                        language: lang,
                                        isSelected: languageManager.language == lang
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            languageManager.language = lang
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Note Naming Section
                    SettingsSectionCard(title: L("note_naming_section")) {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("display_style"))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(STheme.textPrimary)

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
                                Text(L("preview"))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(STheme.textSecondary)

                                HStack(spacing: 8) {
                                    ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { note in
                                        NotePreviewBadge(note: note, style: localNamingStyle)
                                    }
                                }
                            }
                        }
                    }

                    // Sound & Feedback Section
                    SettingsSectionCard(title: L("sound_feedback_section")) {
                        VStack(spacing: 16) {
                            Toggle(isOn: $successSoundEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L("success_sound"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(STheme.textPrimary)
                                        Text(L("play_ding_when_tuned"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }
                            }
                            .tint(STheme.acid)

                            Divider()
                                .background(STheme.border)

                            Toggle(isOn: $hapticFeedbackEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L("haptic_feedback"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(STheme.textPrimary)
                                        Text(L("vibrate_when_tuned"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }
                            }
                            .tint(STheme.acid)

                            Divider()
                                .background(STheme.border)

                            Toggle(isOn: $handsFreeModeEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "waveform.and.mic")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L("hands_free_mode"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(STheme.textPrimary)
                                        Text(L("hands_free_mode_desc"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }
                            }
                            .tint(STheme.acid)

                            Divider()
                                .background(STheme.border)

                            Toggle(isOn: $showLessonPreview) {
                                HStack(spacing: 12) {
                                    Image(systemName: "text.book.closed.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L("show_lesson_preview"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(STheme.textPrimary)
                                        Text(L("show_lesson_preview_desc"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }
                            }
                            .tint(STheme.acid)
                        }
                    }

                    // Subscription Section
                    SettingsSectionCard(title: L("iap_purchases")) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: storeManager.isPremium ? "checkmark.seal.fill" : "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(storeManager.isPremium ? STheme.success : STheme.warning)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("iap_premium_status"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.textPrimary)

                                    if storeManager.isPremium, let expDate = storeManager.expirationDate {
                                        Text(L("iap_renews_on") + " " + expDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    } else {
                                        Text(storeManager.isPremium ? L("iap_ads_removed") : L("iap_free_version"))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }

                                Spacer()

                                if storeManager.isPremium {
                                    Text(L("iap_active"))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(STheme.textOnAcid)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(STheme.success))
                                }
                            }

                            // Subscribe Button (only when not premium)
                            if !storeManager.isPremium {
                                Divider()
                                    .background(STheme.border)

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
                                                .foregroundStyle(STheme.textOnAcid)
                                                .frame(width: 28)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            if let product = storeManager.subscriptionProduct {
                                                Text(product.displayName)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundStyle(STheme.textOnAcid)
                                            } else {
                                                Text(L("iap_subscribe"))
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundStyle(STheme.textOnAcid)
                                            }
                                            Text(L("iap_subscribe_desc"))
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(STheme.textOnAcid.opacity(0.75))
                                        }

                                        Spacer()

                                        if let product = storeManager.subscriptionProduct {
                                            VStack(spacing: 2) {
                                                Text(product.displayPrice)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundStyle(STheme.textOnAcid)
                                                Text(L("iap_per_month"))
                                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                                    .foregroundStyle(STheme.textOnAcid.opacity(0.7))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(STheme.textOnAcid.opacity(0.12))
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(STheme.acid)
                                            .shadow(color: STheme.acid.opacity(0.35), radius: 10, x: 0, y: 4)
                                    )
                                }
                                .disabled(storeManager.isPurchasing || storeManager.subscriptionProduct == nil)

                                // Subscription legal text
                                Text(L("iap_subscription_terms"))
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(STheme.textSecondary.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)

                                // Legal Links
                                HStack(spacing: 16) {
                                    Link(L("terms_of_use"), destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.acid)

                                    Link(L("privacy_policy"), destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.acid)
                                }

                                // Error message
                                if let error = storeManager.errorMessage {
                                    Text(error)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(STheme.error)
                                }
                            }

                            // Manage Subscription (when premium)
                            if storeManager.isPremium {
                                Divider()
                                    .background(STheme.border)

                                Button {
                                    Task {
                                        await storeManager.manageSubscription()
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(STheme.acid)
                                            .frame(width: 28)

                                        Text(L("iap_manage_subscription"))
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(STheme.textPrimary)

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 13))
                                            .foregroundStyle(STheme.textSecondary)
                                    }
                                }
                            }

                            Divider()
                                .background(STheme.border)

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
                                            .foregroundStyle(STheme.acid)
                                            .frame(width: 28)
                                    }

                                    Text(L("iap_restore"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(STheme.textSecondary)
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
                                    .foregroundStyle(STheme.textSecondary)
                                Spacer()
                                Text(AppVersion.version)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(STheme.textPrimary)
                            }

                            HStack {
                                Text(L("build"))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(STheme.textSecondary)
                                Spacer()
                                Text(AppVersion.build)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(STheme.textPrimary)
                            }

                            Divider()
                                .background(STheme.border)

                            // Privacy Policy
                            Link(destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    Text(L("privacy_policy"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.textPrimary)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(STheme.textSecondary)
                                }
                            }

                            Divider()
                                .background(STheme.border)

                            // Terms of Use
                            Link(destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(STheme.acid)
                                        .frame(width: 28)

                                    Text(L("terms_of_use"))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(STheme.textPrimary)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(STheme.textSecondary)
                                }
                            }
                        }
                    }

                    // Footer
                    VStack(spacing: 4) {
                        Text("Made by Tuni")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(STheme.textSecondary)
                        Text("Version \(AppVersion.fullVersion)")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(STheme.textSecondary.opacity(0.6))
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .padding(20)
            }
        }
        .navigationTitle(L("settings"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(STheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            localNamingStyle = NoteNamingStyle(rawValue: noteNamingStyle) ?? .english
        }
    }
}

// MARK: - Settings Section Card

struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(STheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(STheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(STheme.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Language Option Button

struct LanguageOptionButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 24))
                Text(language.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? STheme.textOnAcid : STheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? STheme.acid : STheme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : STheme.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Note Preview Badge

struct NotePreviewBadge: View {
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
            .foregroundStyle(STheme.textPrimary)
            .frame(width: 36, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(STheme.acid.opacity(0.15))
            )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
