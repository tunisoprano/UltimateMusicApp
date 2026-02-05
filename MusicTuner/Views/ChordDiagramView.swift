//
//  ChordDiagramView.swift
//  MusicTuner
//
//  Dynamic SwiftUI chord diagram rendering using Path and Shapes
//  Supports multiple variations with swipeable TabView
//

import SwiftUI

// MARK: - Single Variation Diagram View

/// Renders a single chord variation diagram
struct ChordVariationDiagramView: View {
    let variation: ChordVariation
    let chordName: String
    let chordDisplayName: String
    let showFingerNumbers: Bool
    let showName: Bool
    let onTap: (() -> Void)?
    
    @ObservedObject var theme = ThemeManager.shared
    
    // Layout constants
    private let stringCount = 6
    private let fretCount = 5
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 30
            let gridWidth = width - (padding * 2)
            let gridHeight = height - (padding * 2) - 60 // Extra space for header and footer
            let stringSpacing = gridWidth / CGFloat(stringCount - 1)
            let fretSpacing = gridHeight / CGFloat(fretCount)
            
            ZStack {
                VStack(spacing: 0) {
                    // Chord name header (hidden in quiz mode)
                    if showName {
                        Text(chordName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        
                        Text("\(chordDisplayName) • \(variation.positionName)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                            .padding(.top, 2)
                    } else {
                        // Quiz mode - show question mark
                        Text("?")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                    }
                    
                    Spacer().frame(height: 12)
                    
                    // The diagram
                    ZStack {
                        // Open/Muted indicators at top
                        openMutedIndicators(stringSpacing: stringSpacing, padding: padding)
                            .offset(y: -gridHeight / 2 - 15)
                        
                        // Fret grid
                        fretGrid(gridWidth: gridWidth, gridHeight: gridHeight, 
                                stringSpacing: stringSpacing, fretSpacing: fretSpacing)
                        
                        // Nut (thick line at top for open chords)
                        if variation.startFret == 1 {
                            nutLine(gridWidth: gridWidth, gridHeight: gridHeight)
                        }
                        
                        // Fret number indicator
                        if variation.startFret > 1 {
                            fretNumberIndicator(gridHeight: gridHeight, padding: padding)
                        }
                        
                        // Barre (if present)
                        if let barre = variation.barreInfo {
                            barreLine(barre: barre, stringSpacing: stringSpacing, 
                                     fretSpacing: fretSpacing, gridHeight: gridHeight)
                        }
                        
                        // Finger dots with numbers
                        fingerDots(stringSpacing: stringSpacing, fretSpacing: fretSpacing, 
                                  gridHeight: gridHeight)
                    }
                    .frame(width: gridWidth + 40, height: gridHeight + 40)
                    
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
        }
    }
    
    // MARK: - Subviews
    
    private func openMutedIndicators(stringSpacing: CGFloat, padding: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<stringCount, id: \.self) { stringIndex in
                let fretPosition = variation.fretPositions[stringIndex]
                
                Group {
                    if fretPosition == nil {
                        // Muted string - X
                        Text("×")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme.error)
                    } else if fretPosition == 0 {
                        // Open string - O
                        Circle()
                            .stroke(theme.success, lineWidth: 2)
                            .frame(width: 14, height: 14)
                    } else {
                        // Pressed string - no indicator
                        Color.clear
                            .frame(width: 14, height: 14)
                    }
                }
                .frame(width: stringSpacing)
            }
        }
        .frame(width: CGFloat(stringCount - 1) * stringSpacing + stringSpacing)
    }
    
    private func fretGrid(gridWidth: CGFloat, gridHeight: CGFloat, 
                         stringSpacing: CGFloat, fretSpacing: CGFloat) -> some View {
        Canvas { context, size in
            let startX = (size.width - gridWidth) / 2
            let startY = (size.height - gridHeight) / 2
            
            // Draw horizontal fret lines
            for i in 0...fretCount {
                let y = startY + CGFloat(i) * fretSpacing
                var path = Path()
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: startX + gridWidth, y: y))
                context.stroke(path, with: .color(theme.inactive), lineWidth: i == 0 ? 2 : 1)
            }
            
            // Draw vertical string lines
            for i in 0..<stringCount {
                let x = startX + CGFloat(i) * stringSpacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: startY))
                path.addLine(to: CGPoint(x: x, y: startY + gridHeight))
                
                // Thicker lines for bass strings
                let lineWidth: CGFloat = i < 3 ? 2.5 - CGFloat(i) * 0.4 : 1.0
                context.stroke(path, with: .color(theme.textSecondary.opacity(0.6)), lineWidth: lineWidth)
            }
        }
    }
    
    private func nutLine(gridWidth: CGFloat, gridHeight: CGFloat) -> some View {
        Rectangle()
            .fill(theme.textPrimary)
            .frame(width: gridWidth + 4, height: 5)
            .offset(y: -gridHeight / 2 - 2)
    }
    
    private func fretNumberIndicator(gridHeight: CGFloat, padding: CGFloat) -> some View {
        Text("\(variation.startFret)fr")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(theme.textSecondary)
            .offset(x: -padding - 15, y: -gridHeight / 2 + 15)
    }
    
    private func barreLine(barre: BarreInfo, stringSpacing: CGFloat, 
                          fretSpacing: CGFloat, gridHeight: CGFloat) -> some View {
        let barreWidth = CGFloat(barre.toString - barre.fromString) * stringSpacing + 16
        let adjustedFret = barre.fret - variation.startFret + 1
        let yOffset = -gridHeight / 2 + (CGFloat(adjustedFret) - 0.5) * fretSpacing
        let xOffset = CGFloat(barre.fromString + barre.toString) / 2 * stringSpacing - 
                     CGFloat(stringCount - 1) / 2 * stringSpacing
        
        return ZStack {
            Capsule()
                .fill(theme.accent)
                .frame(width: barreWidth, height: 20)
            
            // Show finger number 1 for barre if enabled
            if showFingerNumbers {
                Text("1")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .offset(x: xOffset, y: yOffset)
    }
    
    private func fingerDots(stringSpacing: CGFloat, fretSpacing: CGFloat, 
                           gridHeight: CGFloat) -> some View {
        ZStack {
            ForEach(0..<stringCount, id: \.self) { stringIndex in
                if let fretPos = variation.fretPositions[stringIndex], fretPos > 0 {
                    // Skip if this is part of a barre
                    let isBarre = variation.barreInfo != nil && 
                                 fretPos == variation.barreInfo!.fret &&
                                 stringIndex >= variation.barreInfo!.fromString &&
                                 stringIndex <= variation.barreInfo!.toString
                    
                    if !isBarre {
                        let adjustedFret = fretPos - variation.startFret + 1
                        let xOffset = CGFloat(stringIndex) * stringSpacing - 
                                     CGFloat(stringCount - 1) / 2 * stringSpacing
                        let yOffset = -gridHeight / 2 + (CGFloat(adjustedFret) - 0.5) * fretSpacing
                        let fingerNum = variation.fingerPositions[stringIndex]
                        
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Group {
                                    if showFingerNumbers && fingerNum > 0 {
                                        Text("\(fingerNum)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            )
                            .offset(x: xOffset, y: yOffset)
                    }
                }
            }
        }
    }
}

// MARK: - Main Chord Diagram View (with Variations)

/// Swipeable chord diagram with multiple variations
struct ChordDiagramView: View {
    let chord: ChordDefinition
    let showName: Bool
    let onTap: (() -> Void)?
    
    @State private var selectedVariationIndex = 0
    @State private var showFingerNumbers = true
    @ObservedObject var theme = ThemeManager.shared
    
    private var variations: [ChordVariation] {
        ChordDatabase.variations(for: chord.rootNote, type: chord.type)
    }
    
    init(chord: ChordDefinition, showName: Bool = true, onTap: (() -> Void)? = nil) {
        self.chord = chord
        self.showName = showName
        self.onTap = onTap
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
            
            VStack(spacing: 0) {
                // Swipeable variations
                TabView(selection: $selectedVariationIndex) {
                    ForEach(Array(variations.enumerated()), id: \.offset) { index, variation in
                        ChordVariationDiagramView(
                            variation: variation,
                            chordName: chord.name,
                            chordDisplayName: chord.displayName,
                            showFingerNumbers: showFingerNumbers,
                            showName: showName,
                            onTap: {
                                playVariation(variation)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator + finger toggle
                HStack {
                    // Page dots
                    if variations.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<variations.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedVariationIndex ? theme.accent : theme.inactive)
                                    .frame(width: 8, height: 8)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedVariationIndex = index
                                        }
                                    }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Tap to play hint
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                        Text(L("tap_to_play"))
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    
                    Spacer()
                    
                    // Finger number toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFingerNumbers.toggle()
                        }
                    } label: {
                        Image(systemName: showFingerNumbers ? "hand.raised.fill" : "hand.raised")
                            .font(.system(size: 18))
                            .foregroundStyle(showFingerNumbers ? theme.accent : theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(theme.cardBackground)
                                    .shadow(color: theme.shadow, radius: 4)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
    
    private func playVariation(_ variation: ChordVariation) {
        // Create a temporary ChordDefinition to play
        let tempChord = ChordDefinition(
            rootNote: chord.rootNote,
            type: chord.type,
            midiNotes: variation.midiNotes,
            fretPositions: variation.fretPositions,
            startFret: variation.startFret,
            fingerPositions: variation.fingerPositions,
            barreInfo: variation.barreInfo
        )
        ChordEngine.shared.playChord(tempChord)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        if let cMajor = ChordDatabase.chord(root: .C, type: .major) {
            ChordDiagramView(chord: cMajor) {
                print("Tapped C Major")
            }
            .frame(width: 300, height: 380)
        }
        
        if let gMajor = ChordDatabase.chord(root: .G, type: .major) {
            ChordDiagramView(chord: gMajor) {
                print("Tapped G Major")
            }
            .frame(width: 300, height: 380)
        }
    }
    .padding()
    .background(ThemeManager.shared.background)
}
