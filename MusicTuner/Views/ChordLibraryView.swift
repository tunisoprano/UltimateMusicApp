//
//  ChordLibraryView.swift
//  MusicTuner
//
//  Professional chord dictionary with dynamic diagram rendering
//

import SwiftUI

struct ChordLibraryView: View {
    @StateObject private var viewModel = ChordLibraryViewModel()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
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
                            .shadow(color: theme.shadow, radius: 10, y: 5)
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
        .toolbarBackground(theme.background, for: .navigationBar)
        .onAppear {
            viewModel.initialize()
        }
    }
    
    // MARK: - Root Note Picker
    
    private var rootNotePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Root Note")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RootNote.allCases) { root in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectRoot(root)
                            }
                        } label: {
                            Text(root.displayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.selectedRoot == root ? .white : theme.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(viewModel.selectedRoot == root ? 
                                              theme.accentGradient : 
                                              LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
                                        .shadow(color: viewModel.selectedRoot == root ? theme.accent.opacity(0.3) : theme.shadow, radius: 6)
                                )
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
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectType(type)
                    }
                } label: {
                    Text(type.localizedName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.selectedType == type ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.selectedType == type ? theme.accent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackground)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - All Chords Grid
    
    private var allChordsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All \(viewModel.selectedType.localizedName) Chords")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
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
                        .foregroundStyle(viewModel.selectedChord == chord ? .white : theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                                .fill(viewModel.selectedChord == chord ? 
                                      theme.accentGradient : 
                                      LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
                                .shadow(color: theme.shadow, radius: 6)
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
