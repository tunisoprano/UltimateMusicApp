//
//  ContentView.swift
//  MusicTuner
//
//  Adaptive root view: NavigationSplitView for iPad, Dashboard for iPhone
//

import SwiftUI

/// Root content view with adaptive layout for different device sizes
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject private var router = AppRouter.shared

    // Deep link navigation
    @State private var navigateToTuner = false
    @State private var navigateToMetronome = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Use NavigationSplitView with sidebar
                iPadLayout
            } else {
                // iPhone: Use existing dashboard layout
                iPhoneLayout
            }
        }
        .onAppear {
            // Request ATT permission after the root view is fully on screen.
            // Triggering from ContentView (instead of App.onAppear) ensures the
            // UIWindowScene is ready on both iPhone and iPad (incl. Stage Manager).
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await AdsManager.shared.requestTrackingAndInitialize()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    // MARK: - iPhone Layout
    
    private var iPhoneLayout: some View {
        NavigationStack {
            MainMenuView()
                .navigationDestination(isPresented: $navigateToTuner) {
                    TunerView()
                }
                .navigationDestination(isPresented: $navigateToMetronome) {
                    MetronomeView()
                }
        }
        // Changing this id tears down and rebuilds the whole stack, popping
        // back to MainMenuView in one shot — see AppRouter.goHome().
        .id(router.homeResetToken)
    }
    
    // MARK: - iPad Layout
    
    @State private var selectedItem: SidebarItem? = .tuner
    
    private var iPadLayout: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var sidebarContent: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.title, systemImage: item.icon)
                .tag(item)
        }
        .navigationTitle("2Jam")
        .listStyle(.sidebar)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedItem {
        case .tuner:
            TunerView()
        case .metronome:
            MetronomeView()
        case .chordLibrary:
            ChordLibraryView()
        case .chordMastery:
            LevelSelectView()
        case .earTraining:
            EarTrainingView()
        case .fretboardTraining:
            ExerciseView()
        case .chordMaker:
            ChordMakerView()
        case .settings:
            SettingsView()
        case .none:
            Text(L("select_an_item"))
                .font(.title)
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Deep Link Handler
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "jam2" else { return }
        
        switch url.host {
        case "tuner":
            if horizontalSizeClass == .regular {
                selectedItem = .tuner
            } else {
                navigateToTuner = true
            }
        case "metronome":
            if horizontalSizeClass == .regular {
                selectedItem = .metronome
            } else {
                navigateToMetronome = true
            }
        default:
            break
        }
    }
}

// MARK: - Sidebar Items

enum SidebarItem: String, CaseIterable, Identifiable {
    case tuner
    case metronome
    case chordLibrary
    case chordMastery
    case earTraining
    case fretboardTraining
    case chordMaker
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .tuner: return L("tuner")
        case .metronome: return L("metronome")
        case .chordLibrary: return L("chord_library")
        case .chordMastery: return L("learn_chord_diagrams")
        case .earTraining: return L("ear_training")
        case .fretboardTraining: return L("fretboard")
        case .chordMaker: return L("chord_maker") // Or localized equivalent
        case .settings: return L("settings")
        }
    }
    
    var icon: String {
        switch self {
        case .tuner: return "tuningfork"
        case .metronome: return "metronome.fill"
        case .chordLibrary: return "book.fill"
        case .chordMastery: return "graduationcap.fill"
        case .earTraining: return "ear.fill"
        case .fretboardTraining: return "guitars.fill"
        case .chordMaker: return "wand.and.stars.inverse"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    ContentView()
}
