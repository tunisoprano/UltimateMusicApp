//
//  HeadstockView.swift
//  MusicTuner
//
//  Guitar: Real headstock photo with floating note labels at peg positions
//  Bass & Ukulele: Vector-based shapes (unchanged, awaiting real photos)
//

import SwiftUI

/// Headstock view — real photo for Guitar, vector shapes for Bass & Ukulele
struct HeadstockView: View {
    let instrument: Instrument
    let strings: [InstrumentString]
    let selectedString: InstrumentString?
    let tunedString: InstrumentString?
    let onPegTap: (InstrumentString) -> Void
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        switch instrument {
        case .guitar:
            guitarPhotoHeadstock
        case .bass:
            bassPhotoHeadstock
        case .ukulele:
            ukulelePhotoHeadstock
        case .free:
            EmptyView()
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Guitar: Real Photo Headstock
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Headstock photo aspect ratio (width / height of the PNG)
    /// Measure your actual image and set this. ~500x830 ≈ 0.602
    private let headstockImageAspect: CGFloat = 0.602
    
    private var guitarPhotoHeadstock: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            
            // Calculate actual image rect (scaledToFit, bottom-aligned)
            let imgH = viewW / headstockImageAspect
            let actualH = min(imgH, viewH)
            let actualW = actualH * headstockImageAspect
            let imgX = (viewW - actualW) / 2        // centered horizontally
            let imgY = viewH - actualH               // bottom-aligned
            
            ZStack(alignment: .topLeading) {
                // Real headstock image
                Image("guitar_headstock")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: viewW)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                // Peg buttons positioned relative to the actual image rect
                guitarNotePegs(imgRect: CGRect(x: imgX, y: imgY, width: actualW, height: actualH))
            }
        }
    }
    

    private func guitarNotePegs(imgRect: CGRect) -> some View {
        // Peg positions as fractions of the headstock IMAGE dimensions
        // Left side: D(top), A(mid), E-low(bottom) — reversed order
        // Right side: G(top), B(mid), E-high(bottom)
        
        // Left peg positions (top to bottom) — all same X
        let leftPositions: [(CGFloat, CGFloat)] = [
            (0.01, 0.16),   // D — top left peg (up a bit)
            (0.01, 0.31),   // A — middle left peg
            (0.01, 0.46),   // E — bottom left peg (down a bit)
        ]
        // Left strings: top=D(index 2), mid=A(index 1), bottom=E-low(index 0)
        let leftStringIndices = [2, 1, 0]
        
        // Right peg positions (top to bottom) — all same X
        let rightPositions: [(CGFloat, CGFloat)] = [
            (0.96, 0.16),   // G — top right peg
            (0.96, 0.31),   // B — middle right peg
            (0.96, 0.46),   // E high — bottom right peg
        ]
        // Right strings: top=G(index 3), mid=B(index 4), bottom=E-high(index 5)
        let rightStringIndices = [3, 4, 5]
        
        return ZStack {
            // Left pegs (D, A, E)
            ForEach(0..<3, id: \.self) { i in
                let si = leftStringIndices[i]
                guard si < strings.count else { return AnyView(EmptyView()) }
                return AnyView(
                    StringPegButton(
                        string: strings[si],
                        isSelected: selectedString?.id == strings[si].id,
                        isTuned: tunedString?.id == strings[si].id,
                        onTap: { onPegTap(strings[si]) }
                    )
                    .position(
                        x: imgRect.minX + imgRect.width * leftPositions[i].0,
                        y: imgRect.minY + imgRect.height * leftPositions[i].1
                    )
                )
            }
            
            // Right pegs (G, B, E)
            ForEach(0..<3, id: \.self) { i in
                let si = rightStringIndices[i]
                guard si < strings.count else { return AnyView(EmptyView()) }
                return AnyView(
                    StringPegButton(
                        string: strings[si],
                        isSelected: selectedString?.id == strings[si].id,
                        isTuned: tunedString?.id == strings[si].id,
                        onTap: { onPegTap(strings[si]) }
                    )
                    .position(
                        x: imgRect.minX + imgRect.width * rightPositions[i].0,
                        y: imgRect.minY + imgRect.height * rightPositions[i].1
                    )
                )
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Bass: Real Photo Headstock
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Bass headstock photo aspect ratio (width / height)
    private let bassImageAspect: CGFloat = 0.644
    
    private var bassPhotoHeadstock: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            
            let imgH = viewW / bassImageAspect
            let actualH = min(imgH, viewH)
            let actualW = actualH * bassImageAspect
            let imgX = (viewW - actualW) / 2
            let imgY = viewH - actualH
            
            ZStack(alignment: .topLeading) {
                Image("bass_headstock")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: viewW)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                bassNotePegs(imgRect: CGRect(x: imgX, y: imgY, width: actualW, height: actualH))
            }
        }
    }
    
    /// 4 floating note labels — all pegs on the left side (Fender-style)
    /// Top to bottom: G(thinnest), D, A, E(thickest)
    private func bassNotePegs(imgRect: CGRect) -> some View {
        // Peg positions — to the left of each peg, fanning out leftward
        let pegPositions: [(CGFloat, CGFloat)] = [
            (0.13, 0.135),  // G — just left of its paddle
            (0.075, 0.30),  // D
            (0.035, 0.50),  // A
            (-0.005, 0.68), // E
        ]
        // String order: G(index 3), D(index 2), A(index 1), E(index 0)
        let stringIndices = [3, 2, 1, 0]
        
        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let si = stringIndices[i]
                guard si < strings.count else { return AnyView(EmptyView()) }
                return AnyView(
                    StringPegButton(
                        string: strings[si],
                        isSelected: selectedString?.id == strings[si].id,
                        isTuned: tunedString?.id == strings[si].id,
                        onTap: { onPegTap(strings[si]) }
                    )
                    .position(
                        x: imgRect.minX + imgRect.width * pegPositions[i].0,
                        y: imgRect.minY + imgRect.height * pegPositions[i].1
                    )
                )
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Ukulele: Real Photo Headstock
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Ukulele headstock photo aspect ratio (width / height)
    private let ukuleleImageAspect: CGFloat = 0.58
    
    private var ukulelePhotoHeadstock: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            
            // Narrower than the view so the note labels get clean side gutters
            let displayW = viewW * 0.72
            let imgH = displayW / ukuleleImageAspect
            let actualH = min(imgH, viewH)
            let actualW = actualH * ukuleleImageAspect
            let imgX = (viewW - actualW) / 2
            let imgY = viewH - actualH
            
            ZStack(alignment: .topLeading) {
                Image("ukulele_headstock")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: actualW)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                ukuleleNotePegs(imgRect: CGRect(x: imgX, y: imgY, width: actualW, height: actualH))
            }
        }
    }
    
    /// 4 floating note labels — 2 left (G, C) + 2 right (E, A)
    private func ukuleleNotePegs(imgRect: CGRect) -> some View {
        // Labels sit in the side gutters, clear of the protruding paddles,
        // vertically centered on their paddle rows
        // Left pegs: G(top), C(bottom)
        let leftPositions: [(CGFloat, CGFloat)] = [
            (-0.10, 0.158), // G — beside top-left paddle
            (-0.10, 0.32),  // C — beside bottom-left paddle
        ]
        let leftStringIndices = [0, 1] // G=0, C=1
        
        // Right pegs: E(top), A(bottom)
        let rightPositions: [(CGFloat, CGFloat)] = [
            (1.10, 0.158),  // E — beside top-right paddle
            (1.10, 0.32),   // A — beside bottom-right paddle
        ]
        let rightStringIndices = [2, 3] // E=2, A=3
        
        return ZStack {
            // Left pegs (G, C)
            ForEach(0..<2, id: \.self) { i in
                let si = leftStringIndices[i]
                guard si < strings.count else { return AnyView(EmptyView()) }
                return AnyView(
                    StringPegButton(
                        string: strings[si],
                        isSelected: selectedString?.id == strings[si].id,
                        isTuned: tunedString?.id == strings[si].id,
                        onTap: { onPegTap(strings[si]) }
                    )
                    .position(
                        x: imgRect.minX + imgRect.width * leftPositions[i].0,
                        y: imgRect.minY + imgRect.height * leftPositions[i].1
                    )
                )
            }
            
            // Right pegs (E, A)
            ForEach(0..<2, id: \.self) { i in
                let si = rightStringIndices[i]
                guard si < strings.count else { return AnyView(EmptyView()) }
                return AnyView(
                    StringPegButton(
                        string: strings[si],
                        isSelected: selectedString?.id == strings[si].id,
                        isTuned: tunedString?.id == strings[si].id,
                        onTap: { onPegTap(strings[si]) }
                    )
                    .position(
                        x: imgRect.minX + imgRect.width * rightPositions[i].0,
                        y: imgRect.minY + imgRect.height * rightPositions[i].1
                    )
                )
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Vector Headstock (legacy, kept for reference)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func vectorHeadstock<S: Shape>(shape: S, aspect: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack {
                shape
                    .fill(headstockGradient)
                    .overlay(
                        shape.stroke(theme.textSecondary.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                vectorPegs(in: geo.size)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
    }
    
    private var headstockGradient: LinearGradient {
        let baseColor: Color
        switch instrument {
        case .bass:
            baseColor = Color(red: 0.25, green: 0.15, blue: 0.08)
        case .ukulele:
            baseColor = Color(red: 0.55, green: 0.38, blue: 0.20)
        default:
            baseColor = Color(red: 0.45, green: 0.28, blue: 0.15)
        }
        return LinearGradient(
            colors: [baseColor.opacity(0.9), baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func vectorPegs(in size: CGSize) -> some View {
        let positions = vectorPegPositions(for: size)
        return ZStack {
            ForEach(Array(zip(strings.indices, strings)), id: \.0) { index, string in
                if index < positions.count {
                    TuningPegView(
                        string: string,
                        isSelected: selectedString?.id == string.id,
                        isTuned: tunedString?.id == string.id,
                        onTap: { onPegTap(string) }
                    )
                    .position(positions[index])
                }
            }
        }
    }
    
    private func vectorPegPositions(for size: CGSize) -> [CGPoint] {
        let w = size.width
        let h = size.height
        switch instrument {
        case .bass:
            return [
                CGPoint(x: w * 0.22, y: h * 0.20),
                CGPoint(x: w * 0.22, y: h * 0.40),
                CGPoint(x: w * 0.22, y: h * 0.60),
                CGPoint(x: w * 0.22, y: h * 0.80),
            ]
        case .ukulele:
            return [
                CGPoint(x: w * 0.20, y: h * 0.30),
                CGPoint(x: w * 0.20, y: h * 0.55),
                CGPoint(x: w * 0.80, y: h * 0.30),
                CGPoint(x: w * 0.80, y: h * 0.55),
            ]
        default: return []
        }
    }
}

// MARK: - String Peg Button (floating label for photo headstock)

/// Circular floating note label — used for Guitar photo headstock
struct StringPegButton: View {
    let string: InstrumentString
    let isSelected: Bool
    let isTuned: Bool
    let onTap: () -> Void
    
    @ObservedObject var theme = ThemeManager.shared
    
    private var bgColor: Color {
        if isTuned { return theme.success }
        if isSelected { return theme.accent }
        return Color(white: 0.22)
    }
    
    private var glowColor: Color {
        if isTuned { return theme.success }
        if isSelected { return theme.accent }
        return .clear
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow
                if isSelected || isTuned {
                    Circle()
                        .fill(glowColor.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)
                }
                
                // Glass background circle
                Circle()
                    .fill(bgColor.opacity(0.85))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isTuned ? 0.5 : 0.15), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                
                // Note letter
                Text(NoteFormatter.formatLetter(string.name))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PegTapStyle())
        .scaleEffect(isTuned ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isTuned)
    }
}

// MARK: - Tuning Peg View (vector headstock — Bass & Ukulele)

struct TuningPegView: View {
    let string: InstrumentString
    let isSelected: Bool
    let isTuned: Bool
    let onTap: () -> Void
    
    @ObservedObject var theme = ThemeManager.shared
    
    private var pegColor: Color {
        if isTuned { return theme.success }
        if isSelected { return theme.accent }
        return Color(white: 0.85)
    }
    
    private var glowColor: Color {
        if isTuned { return theme.success }
        if isSelected { return theme.accent }
        return .clear
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected || isTuned {
                    Circle()
                        .fill(glowColor.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                }
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [pegColor, pegColor.opacity(0.7)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 1, y: 2)
                
                Text(NoteFormatter.formatLetter(string.name))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isTuned || isSelected ? .white : theme.textPrimary)
            }
        }
        .buttonStyle(PegTapStyle())
    }
}

// MARK: - Button Style

struct PegTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Bass Headstock Shape

struct BassHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.40, y: h))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.10),
            control: CGPoint(x: w * 0.03, y: h * 0.50)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: 0),
            control: CGPoint(x: w * 0.15, y: 0)
        )
        path.addLine(to: CGPoint(x: w * 0.55, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.10),
            control: CGPoint(x: w * 0.60, y: 0)
        )
        path.addLine(to: CGPoint(x: w * 0.60, y: h))
        path.addLine(to: CGPoint(x: w * 0.40, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Ukulele Headstock Shape

struct UkuleleHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.35, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.20),
            control: CGPoint(x: w * 0.10, y: h * 0.55)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.05),
            control: CGPoint(x: w * 0.30, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.20),
            control: CGPoint(x: w * 0.70, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h),
            control: CGPoint(x: w * 0.90, y: h * 0.55)
        )
        path.addLine(to: CGPoint(x: w * 0.35, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        HeadstockView(
            instrument: .guitar,
            strings: Instrument.guitar.strings,
            selectedString: Instrument.guitar.strings[1],
            tunedString: Instrument.guitar.strings.first,
            onPegTap: { _ in }
        )
        .frame(height: 280)
    }
    .padding(20)
    .background(Color.black)
}
