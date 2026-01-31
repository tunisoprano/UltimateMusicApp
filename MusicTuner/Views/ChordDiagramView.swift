//
//  ChordDiagramView.swift
//  MusicTuner
//
//  Dynamic SwiftUI chord diagram rendering using Path and Shapes
//

import SwiftUI

struct ChordDiagramView: View {
    let chord: ChordDefinition
    let onTap: (() -> Void)?
    
    @ObservedObject var theme = ThemeManager.shared
    
    // Layout constants
    private let stringCount = 6
    private let fretCount = 5
    
    init(chord: ChordDefinition, onTap: (() -> Void)? = nil) {
        self.chord = chord
        self.onTap = onTap
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 30
            let gridWidth = width - (padding * 2)
            let gridHeight = height - (padding * 2) - 20 // Extra space for indicators
            let stringSpacing = gridWidth / CGFloat(stringCount - 1)
            let fretSpacing = gridHeight / CGFloat(fretCount)
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(theme.cardBackground)
                
                VStack(spacing: 0) {
                    // Chord name header
                    Text(chord.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.top, 8)
                    
                    Text(chord.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    
                    Spacer()
                    
                    // The diagram
                    ZStack {
                        // Open/Muted indicators at top
                        openMutedIndicators(stringSpacing: stringSpacing, padding: padding)
                            .offset(y: -gridHeight / 2 - 15)
                        
                        // Fret grid
                        fretGrid(gridWidth: gridWidth, gridHeight: gridHeight, 
                                stringSpacing: stringSpacing, fretSpacing: fretSpacing)
                        
                        // Nut (thick line at top for open chords)
                        if chord.startFret == 1 {
                            nutLine(gridWidth: gridWidth, gridHeight: gridHeight)
                        }
                        
                        // Fret number indicator
                        if chord.startFret > 1 {
                            fretNumberIndicator(gridHeight: gridHeight, padding: padding)
                        }
                        
                        // Barre (if present)
                        if let barre = chord.barreInfo {
                            barreLine(barre: barre, stringSpacing: stringSpacing, 
                                     fretSpacing: fretSpacing, gridHeight: gridHeight)
                        }
                        
                        // Finger dots
                        fingerDots(stringSpacing: stringSpacing, fretSpacing: fretSpacing, 
                                  gridHeight: gridHeight)
                    }
                    .frame(width: gridWidth + 40, height: gridHeight + 40)
                    
                    Spacer()
                    
                    // Tap to play hint
                    if onTap != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                            Text(String(localized: "tap_to_play"))
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.bottom, 12)
                    }
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
                let fretPosition = chord.fretPositions[stringIndex]
                
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
        Text("\(chord.startFret)fr")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(theme.textSecondary)
            .offset(x: -padding - 15, y: -gridHeight / 2 + 15)
    }
    
    private func barreLine(barre: BarreInfo, stringSpacing: CGFloat, 
                          fretSpacing: CGFloat, gridHeight: CGFloat) -> some View {
        let barreWidth = CGFloat(barre.toString - barre.fromString) * stringSpacing + 16
        let adjustedFret = barre.fret - chord.startFret + 1
        let yOffset = -gridHeight / 2 + (CGFloat(adjustedFret) - 0.5) * fretSpacing
        let xOffset = CGFloat(barre.fromString + barre.toString) / 2 * stringSpacing - 
                     CGFloat(stringCount - 1) / 2 * stringSpacing
        
        return Capsule()
            .fill(theme.textPrimary)
            .frame(width: barreWidth, height: 18)
            .offset(x: xOffset, y: yOffset)
    }
    
    private func fingerDots(stringSpacing: CGFloat, fretSpacing: CGFloat, 
                           gridHeight: CGFloat) -> some View {
        ZStack {
            ForEach(0..<stringCount, id: \.self) { stringIndex in
                if let fretPos = chord.fretPositions[stringIndex], fretPos > 0 {
                    // Skip if this is part of a barre
                    let isBarre = chord.barreInfo != nil && 
                                 fretPos == chord.barreInfo!.fret &&
                                 stringIndex >= chord.barreInfo!.fromString &&
                                 stringIndex <= chord.barreInfo!.toString
                    
                    if !isBarre {
                        let adjustedFret = fretPos - chord.startFret + 1
                        let xOffset = CGFloat(stringIndex) * stringSpacing - 
                                     CGFloat(stringCount - 1) / 2 * stringSpacing
                        let yOffset = -gridHeight / 2 + (CGFloat(adjustedFret) - 0.5) * fretSpacing
                        
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Text("\(chord.fingerPositions[stringIndex])")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(chord.fingerPositions[stringIndex] > 0 ? 1 : 0)
                            )
                            .offset(x: xOffset, y: yOffset)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        if let gMajor = ChordDatabase.chord(root: .G, type: .major) {
            ChordDiagramView(chord: gMajor) {
                print("Tapped G Major")
            }
            .frame(width: 280, height: 350)
        }
        
        if let fMajor = ChordDatabase.chord(root: .F, type: .major) {
            ChordDiagramView(chord: fMajor) {
                print("Tapped F Major")
            }
            .frame(width: 280, height: 350)
        }
    }
    .padding()
    .background(ThemeManager.shared.background)
}
