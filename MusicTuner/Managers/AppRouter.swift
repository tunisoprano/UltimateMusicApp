//
//  AppRouter.swift
//  MusicTuner
//
//  Lets a deeply-nested screen (e.g. mid-quiz) jump straight back to the
//  main menu in one tap, without needing an explicit NavigationPath threaded
//  through every intermediate screen.
//

import Foundation

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    /// Changing this forces the root NavigationStack to be torn down and
    /// rebuilt from scratch (see ContentView's `.id(router.homeResetToken)`),
    /// which pops every pushed screen back to MainMenuView regardless of how
    /// deep the stack is or how each screen was pushed.
    @Published private(set) var homeResetToken = UUID()

    private init() {}

    func goHome() {
        homeResetToken = UUID()
    }
}
