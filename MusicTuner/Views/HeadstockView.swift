//
//  HeadstockView.swift
//  MusicTuner
//
//  Vector-based instrument headstock with tuning pegs
//

import SwiftUI

/// Headstock view with vector graphics for Guitar, Bass, and Ukulele
struct HeadstockView: View {
    let instrument: Instrument
    let strings: [InstrumentString]
    let selectedString: InstrumentString?
    let tunedString: InstrumentString?
    let onPegTap: (InstrumentString) -> Void
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Draw headstock shape
                scaledHeadstock(in: geo.size)
                
                // Draw tuning pegs
                pegsOverlay(in: geo.size)
            }
        }
        .aspectRatio(headstockAspect, contentMode: .fit)
    }
    
    // MARK: - Headstock Shape
    
    private var headstockPath: Path {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        switch instrument {
        case .guitar, .free:
            return GuitarHeadstockShape().path(in: rect)
        case .bass:
            return BassHeadstockShape().path(in: rect)
        case .ukulele:
            return UkuleleHeadstockShape().path(in: rect)
        }
    }
    
    private func scaledHeadstock(in size: CGSize) -> some View {
        let shape: any Shape
        switch instrument {
        case .guitar, .free:
            shape = GuitarHeadstockShape()
        case .bass:
            shape = BassHeadstockShape()
        case .ukulele:
            shape = UkuleleHeadstockShape()
        }
        
        return AnyShape(shape)
            .fill(headstockGradient)
            .overlay(
                AnyShape(shape)
                    .stroke(theme.textSecondary.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var headstockAspect: CGFloat {
        switch instrument {
        case .guitar: return 0.55
        case .bass: return 0.45
        case .ukulele: return 0.65
        case .free: return 0.55
        }
    }
    
    private var headstockGradient: LinearGradient {
        let baseColor: Color
        switch instrument {
        case .guitar:
            baseColor = Color(red: 0.45, green: 0.28, blue: 0.15)
        case .bass:
            baseColor = Color(red: 0.25, green: 0.15, blue: 0.08)
        case .ukulele:
            baseColor = Color(red: 0.55, green: 0.38, blue: 0.20)
        case .free:
            baseColor = Color(red: 0.40, green: 0.25, blue: 0.12)
        }
        
        return LinearGradient(
            colors: [baseColor.opacity(0.9), baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Tuning Pegs
    
    private func pegsOverlay(in size: CGSize) -> some View {
        let positions = pegPositions(for: size)
        
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
    
    private func pegPositions(for size: CGSize) -> [CGPoint] {
        let w = size.width
        let h = size.height
        
        switch instrument {
        case .guitar:
            // 6 strings: 3 left, 3 right (E-A-D left, G-B-E right)
            return [
                CGPoint(x: w * 0.18, y: h * 0.25), // E (low)
                CGPoint(x: w * 0.15, y: h * 0.45), // A
                CGPoint(x: w * 0.18, y: h * 0.65), // D
                CGPoint(x: w * 0.82, y: h * 0.25), // G
                CGPoint(x: w * 0.85, y: h * 0.45), // B
                CGPoint(x: w * 0.82, y: h * 0.65), // E (high)
            ]
        case .bass:
            // 4 strings: inline on left side
            return [
                CGPoint(x: w * 0.22, y: h * 0.20), // E
                CGPoint(x: w * 0.22, y: h * 0.40), // A
                CGPoint(x: w * 0.22, y: h * 0.60), // D
                CGPoint(x: w * 0.22, y: h * 0.80), // G
            ]
        case .ukulele:
            // 4 strings: 2 left, 2 right
            return [
                CGPoint(x: w * 0.20, y: h * 0.30), // G
                CGPoint(x: w * 0.20, y: h * 0.55), // C
                CGPoint(x: w * 0.80, y: h * 0.30), // E
                CGPoint(x: w * 0.80, y: h * 0.55), // A
            ]
        case .free:
            return []
        }
    }
}

// MARK: - Tuning Peg Button

struct TuningPegView: View {
    let string: InstrumentString
    let isSelected: Bool
    let isTuned: Bool
    let onTap: () -> Void
    
    @ObservedObject var theme = ThemeManager.shared
    
    private var pegColor: Color {
        if isTuned {
            return theme.success
        } else if isSelected {
            return theme.accent
        } else {
            return Color(white: 0.85)
        }
    }
    
    private var glowColor: Color {
        if isTuned {
            return theme.success
        } else if isSelected {
            return theme.accent
        } else {
            return .clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect
                if isSelected || isTuned {
                    Circle()
                        .fill(glowColor.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                }
                
                // Peg base (metallic look)
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
                
                // String label
                Text(NoteFormatter.formatLetter(string.name))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isTuned || isSelected ? .white : theme.textPrimary)
            }
        }
        .buttonStyle(PegButtonStyle())
    }
}

struct PegButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Guitar Headstock Shape

struct GuitarHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Classic guitar headstock shape
        path.move(to: CGPoint(x: w * 0.35, y: h))
        
        // Left curve up
        path.addQuadCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.15),
            control: CGPoint(x: w * 0.05, y: h * 0.60)
        )
        
        // Top curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: 0),
            control: CGPoint(x: w * 0.25, y: 0)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: w * 0.90, y: h * 0.15),
            control: CGPoint(x: w * 0.75, y: 0)
        )
        
        // Right curve down
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h),
            control: CGPoint(x: w * 0.95, y: h * 0.60)
        )
        
        // Neck
        path.addLine(to: CGPoint(x: w * 0.35, y: h))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Bass Headstock Shape

struct BassHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Elongated bass headstock (Fender style)
        path.move(to: CGPoint(x: w * 0.40, y: h))
        
        // Left side - straighter
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.10),
            control: CGPoint(x: w * 0.03, y: h * 0.50)
        )
        
        // Top
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: 0),
            control: CGPoint(x: w * 0.15, y: 0)
        )
        
        path.addLine(to: CGPoint(x: w * 0.55, y: 0))
        
        path.addQuadCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.10),
            control: CGPoint(x: w * 0.60, y: 0)
        )
        
        // Right side
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
        
        // Compact ukulele headstock
        path.move(to: CGPoint(x: w * 0.35, y: h))
        
        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.20),
            control: CGPoint(x: w * 0.10, y: h * 0.55)
        )
        
        // Top - more rounded
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.05),
            control: CGPoint(x: w * 0.30, y: 0)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.20),
            control: CGPoint(x: w * 0.70, y: 0)
        )
        
        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h),
            control: CGPoint(x: w * 0.90, y: h * 0.55)
        )
        
        path.addLine(to: CGPoint(x: w * 0.35, y: h))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        HeadstockView(
            instrument: .guitar,
            strings: Instrument.guitar.strings,
            selectedString: nil,
            tunedString: Instrument.guitar.strings.first,
            onPegTap: { _ in }
        )
        .frame(height: 200)
        
        HeadstockView(
            instrument: .bass,
            strings: Instrument.bass.strings,
            selectedString: Instrument.bass.strings[1],
            tunedString: nil,
            onPegTap: { _ in }
        )
        .frame(height: 220)
        
        HeadstockView(
            instrument: .ukulele,
            strings: Instrument.ukulele.strings,
            selectedString: nil,
            tunedString: nil,
            onPegTap: { _ in }
        )
        .frame(height: 160)
    }
    .padding()
    .background(Color.black)
}
