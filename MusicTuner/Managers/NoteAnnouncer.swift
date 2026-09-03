//
//  NoteAnnouncer.swift
//  MusicTuner
//
//  Speaks the target string + note for Fretboard Training's Hands-Free Mode,
//  so the player can find the note by ear/knowledge without looking at the screen.
//

import AVFoundation

@MainActor
final class NoteAnnouncer {

    private let synthesizer = AVSpeechSynthesizer()
    private var repeatTimer: Timer?
    private let repeatInterval: TimeInterval = 4.0

    /// Speaks "{string number} string, {note}" (or the Turkish equivalent) and,
    /// if `repeating` is true, keeps repeating it every few seconds until stopped.
    func announce(stringNumber: Int, noteName: String, repeating: Bool = true) {
        stopRepeating()
        speakOnce(stringNumber: stringNumber, noteName: noteName)

        guard repeating else { return }
        repeatTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.speakOnce(stringNumber: stringNumber, noteName: noteName)
            }
        }
    }

    func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speakOnce(stringNumber: Int, noteName: String) {
        let utterance = AVSpeechUtterance(string: Self.phrase(stringNumber: stringNumber, noteName: noteName))
        let isTurkish = LanguageManager.shared.language == .turkish
        utterance.voice = AVSpeechSynthesisVoice(language: isTurkish ? "tr-TR" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    private static func phrase(stringNumber: Int, noteName: String) -> String {
        let noteText = NoteFormatter.format(noteName)
        if LanguageManager.shared.language == .turkish {
            return "\(stringNumber). tel, \(noteText)"
        } else {
            return "\(ordinalEN(stringNumber)) string, \(noteText)"
        }
    }

    private static func ordinalEN(_ n: Int) -> String {
        switch n {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(n)th"
        }
    }
}
