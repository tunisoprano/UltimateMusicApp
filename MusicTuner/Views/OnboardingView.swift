//
//  OnboardingView.swift
//  MusicTuner
//
//  Modern minimal onboarding — 3 slides with animated icons and gradient accents
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
    @State private var iconBounce = false

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

    private var currentColor: Color { pages[currentPage].color }
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            // Animated background — tints slightly with page color
            theme.backgroundGradient.ignoresSafeArea()

            Color(currentColor).opacity(0.04)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text(L10n.skip)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(height: 52)
                .padding(.top, 8)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageContent(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // Bottom area: dots + button
                VStack(spacing: 32) {
                    // Dot indicators
                    HStack(spacing: 10) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? currentColor : theme.inactive.opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if isLastPage {
                            completeOnboarding()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                currentPage += 1
                            }
                            triggerIconBounce()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(isLastPage ? L10n.getStarted : L10n.next)
                                .font(.system(size: 17, weight: .bold, design: .rounded))

                            if !isLastPage {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [currentColor, currentColor.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: currentColor.opacity(0.35), radius: 14, x: 0, y: 6)
                        )
                        .animation(.easeInOut(duration: 0.35), value: currentPage)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear { triggerIconBounce() }
    }

    // MARK: - Page Content

    private func pageContent(page: OnboardingPage) -> some View {
        VStack(spacing: 36) {
            Spacer()

            // Icon with layered glow rings
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 200, height: 200)

                // Mid ring
                Circle()
                    .fill(page.color.opacity(0.13))
                    .frame(width: 155, height: 155)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: page.color.opacity(0.4), radius: 20, x: 0, y: 8)

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(iconBounce ? 1.0 : 0.85)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.55),
                        value: iconBounce
                    )
            }

            // Text
            VStack(spacing: 14) {
                Text(page.titleKey())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitleKey())
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasSeenOnboarding = true
        }
    }

    private func triggerIconBounce() {
        iconBounce = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            iconBounce = true
        }
    }
}

#Preview {
    OnboardingView()
}
