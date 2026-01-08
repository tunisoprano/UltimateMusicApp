//
//  MusicTunerApp.swift
//  MusicTuner
//
//  Main entry point - directly opens MainMenuView
//

import SwiftUI

@main
struct MusicTunerApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
            .onAppear {
                // Initialize AdMob after app is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    AdsManager.shared.initializeAdMob()
                }
            }
        }
    }
}
