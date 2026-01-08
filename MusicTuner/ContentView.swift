//
//  ContentView.swift
//  MusicTuner
//
//  Root content view - redirects to MainMenuView
//

import SwiftUI

/// Root content view (alternative entry point if needed)
struct ContentView: View {
    var body: some View {
        NavigationStack {
            MainMenuView()
        }
    }
}

#Preview {
    ContentView()
}
