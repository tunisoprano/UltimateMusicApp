//
//  ChordLibraryView.swift
//  MusicTuner
//
//  Professional chord dictionary with dynamic diagram rendering
//  "Playful Premium" acid/black theme — matches Tuner/Metronome.
//

import SwiftUI

/// Acid/black palette for this screen (mirrors TunerView/MetronomeView)
private enum CLTheme {
    static let background = Color(hex: "131313")
    static let card = Color(hex: "1F1F1F")
    static let border = Color(hex: "353534")
    static let acid = Color(hex: "E1EC00")
    static let textOnAcid = Color(hex: "303300")
    static let textPrimary = Color(hex: "E2E2E2")
    static let textSecondary = Color(hex: "929277")
    static let heart = Color(hex: "FF5A5A")
}

struct ChordLibraryView: View {
    @StateObject private var viewModel = ChordLibraryViewModel()
    @ObservedObject var favorites = ChordFavoritesManager.shared

    var body: some View {
        ZStack {
            CLTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        // Root Note Picker
                        rootNotePicker

                        // Chord Type Picker
                        chordTypePicker

                        // Chord Diagram
                        if let chord = viewModel.selectedChord {
                            ChordDiagramView(chord: chord) {
                                viewModel.playChord()
                            }
                            .frame(height: 380)
                            .padding(.horizontal, 20)
                        }

                        // Favorited chords (only shown once the user has favorited something)
                        if !favorites.favoriteChords.isEmpty {
                            favoritesSection
                        }

                        // All chords of selected type
                        allChordsGrid
                    }
                    .padding(.vertical, 20)
                }

                // Banner Ad
                AdBannerContainer()
            }
        }
        .navigationTitle(L("chord_library"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(CLTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.initialize()
        }
    }

    // MARK: - Root Note Picker

    private var rootNotePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Root Note")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(CLTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RootNote.allCases) { root in
                        let isSelected = viewModel.selectedRoot == root
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectRoot(root)
                            }
                        } label: {
                            Text(root.displayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? CLTheme.textOnAcid : CLTheme.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isSelected ? CLTheme.acid : CLTheme.card)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.clear : CLTheme.border, lineWidth: 1)
                                )
                                .shadow(color: isSelected ? CLTheme.acid.opacity(0.35) : .clear, radius: 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Chord Type Picker

    private var chordTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(ChordType.allCases) { type in
                let isSelected = viewModel.selectedType == type
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectType(type)
                    }
                } label: {
                    Text(type.localizedName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? CLTheme.textOnAcid : CLTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? CLTheme.acid : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CLTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CLTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(CLTheme.heart)
                Text(L("favorites"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(CLTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favorites.favoriteChords) { chord in
                        let isSelected = viewModel.selectedChord == chord
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectChord(chord)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(chord.name)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text(chord.rootNote.displayName)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .opacity(0.7)
                            }
                            .foregroundStyle(isSelected ? CLTheme.textOnAcid : CLTheme.textPrimary)
                            .frame(width: 64, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? CLTheme.acid : CLTheme.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.clear : CLTheme.border, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - All Chords Grid

    private var allChordsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All \(viewModel.selectedType.localizedName) Chords")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(CLTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.chordsOfSelectedType) { chord in
                    let isSelected = viewModel.selectedChord == chord
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectChord(chord)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(chord.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text(chord.rootNote.displayName)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundStyle(isSelected ? CLTheme.textOnAcid : CLTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? CLTheme.acid : CLTheme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.clear : CLTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ChordLibraryViewModel: ObservableObject {
    @Published var selectedRoot: RootNote = .C
    @Published var selectedType: ChordType = .major
    @Published var selectedChord: ChordDefinition?

    private let chordEngine = ChordEngine.shared

    var chordsOfSelectedType: [ChordDefinition] {
        ChordDatabase.chords(ofType: selectedType)
    }

    func initialize() {
        updateSelectedChord()
        Task {
            await chordEngine.initialize()
        }
    }

    func selectRoot(_ root: RootNote) {
        selectedRoot = root
        updateSelectedChord()
    }

    func selectType(_ type: ChordType) {
        selectedType = type
        updateSelectedChord()
    }

    func selectChord(_ chord: ChordDefinition) {
        selectedRoot = chord.rootNote
        selectedType = chord.type
        selectedChord = chord
        playChord()
    }

    func playChord() {
        guard let chord = selectedChord else { return }
        chordEngine.playChord(chord)
    }

    private func updateSelectedChord() {
        selectedChord = ChordDatabase.chord(root: selectedRoot, type: selectedType)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChordLibraryView()
    }
}
