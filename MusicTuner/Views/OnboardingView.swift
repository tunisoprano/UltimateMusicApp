//
//  OnboardingView.swift
//  MusicTuner
//
//  3-slide tutorial for first-time users
//

import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: () -> String
    let subtitleKey: () -> String
    let color: Color
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @ObservedObject var theme = ThemeManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "music.note",
            titleKey: { L10n.onboardingWelcomeTitle },
            subtitleKey: { L10n.onboardingWelcomeSubtitle },
            color: .blue
        ),
        OnboardingPage(
            icon: "ear.fill",
            titleKey: { L10n.onboardingFeaturesTitle },
            subtitleKey: { L10n.onboardingFeaturesSubtitle },
            color: .purple
        ),
        OnboardingPage(
            icon: "star.fill",
            titleKey: { L10n.onboardingStartTitle },
            subtitleKey: { L10n.onboardingStartSubtitle },
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text(L10n.skip)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 44)
                
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, theme: theme)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? theme.accent : theme.inactive)
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                
                // Action Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? L10n.next : L10n.getStarted)
                }
                .buttonStyle(ThemeButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(page.color)
            }
            
            // Text
            VStack(spacing: 16) {
                Text(page.titleKey())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitleKey())
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
