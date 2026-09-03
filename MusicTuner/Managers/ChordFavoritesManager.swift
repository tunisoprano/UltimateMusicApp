//
//  ChordFavoritesManager.swift
//  MusicTuner
//
//  Persists the user's favorited chords (heart button in Chord Library) as a
//  simple comma-joined string in UserDefaults — no Codable ceremony needed
//  since a favorite is just "root-type" (e.g. "C-Major").
//

import Foundation
import SwiftUI

@MainActor
final class ChordFavoritesManager: ObservableObject {
    static let shared = ChordFavoritesManager()

    @AppStorage("favoriteChordIds") private var storedIds: String = ""
    @Published private(set) var favoriteIds: Set<String> = []

    private init() {
        favoriteIds = Self.parse(storedIds)
    }

    func isFavorite(_ chord: ChordDefinition) -> Bool {
        favoriteIds.contains(Self.key(for: chord))
    }

    func toggleFavorite(_ chord: ChordDefinition) {
        let key = Self.key(for: chord)
        if favoriteIds.contains(key) {
            favoriteIds.remove(key)
        } else {
            favoriteIds.insert(key)
        }
        storedIds = favoriteIds.sorted().joined(separator: ",")
    }

    /// Resolve favorited chord keys back into playable `ChordDefinition`s, in the order they appear
    /// in `ChordDatabase.allChords` (stable ordering regardless of favorite/unfavorite sequence).
    var favoriteChords: [ChordDefinition] {
        ChordDatabase.allChords.filter { favoriteIds.contains(Self.key(for: $0)) }
    }

    private static func key(for chord: ChordDefinition) -> String {
        "\(chord.rootNote.rawValue)-\(chord.type.rawValue)"
    }

    private static func parse(_ stored: String) -> Set<String> {
        Set(stored.split(separator: ",").map(String.init))
    }
}
