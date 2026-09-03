//
//  HeadstockView.swift
//  MusicTuner
//
//  Abstract vector/line-art headstock — "Playful Premium" acid/black theme.
//  Draws a stylized paddle-shaped headstock with a diamond nut marker and
//  floating peg buttons for each string, generically laid out left/right.
//

import SwiftUI

/// Headstock view — abstract vector line-art design, shared across all instruments
struct HeadstockView: View {
    let instrument: Instrument
    let strings: [InstrumentString]
    let selectedString: InstrumentString?
    let tunedString: InstrumentString?
    let onPegTap: (InstrumentString) -> Void

    var body: some View {
        if instrument == .free || strings.isEmpty {
            EmptyView()
        } else {
            GeometryReader { geo in
                ZStack {
                    vectorHeadstockShape
                        .padding(.horizontal, geo.size.width * 0.28)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    pegLayer(size: geo.size)
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Vector Headstock Shape
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var vectorHeadstockShape: some View {
        HeadstockPaddleShape()
            .fill(Color(hex: "1F1F1F"))
            .overlay(
                HeadstockPaddleShape()
                    .stroke(LearningPath.acidDim.opacity(0.5), lineWidth: 2)
            )
            .overlay(nutMarker, alignment: .bottom)
            .aspectRatio(0.62, contentMode: .fit)
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }

    /// Diamond marker representing the nut, where the (off-screen) neck meets the headstock
    private var nutMarker: some View {
        Rectangle()
            .fill(LearningPath.acid)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
            .shadow(color: LearningPath.acid.opacity(0.6), radius: 4)
            .offset(y: 4)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Peg Layout (generic, left/right split)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    /// Splits strings into left/right peg groups (top-to-bottom order),
    /// mirroring a classic 3-a-side / 2-a-side headstock layout.
    private var leftIndices: [Int] {
        let half = strings.count / 2
        return Array((0..<half).reversed())
    }

    private var rightIndices: [Int] {
        let half = strings.count / 2
        return Array(half..<strings.count)
    }

    private func yFractions(count: Int) -> [CGFloat] {
        guard count > 0 else { return [] }
        if count == 1 { return [0.28] }
        let top: CGFloat = 0.12
        let bottom: CGFloat = 0.52
        return (0..<count).map { top + (bottom - top) * CGFloat($0) / CGFloat(count - 1) }
    }

    private func pegLayer(size: CGSize) -> some View {
        let leftY = yFractions(count: leftIndices.count)
        let rightY = yFractions(count: rightIndices.count)

        return ZStack {
            ForEach(Array(leftIndices.enumerated()), id: \.offset) { pos, stringIndex in
                if stringIndex < strings.count {
                    pegButton(for: strings[stringIndex])
                        .position(x: size.width * 0.06, y: size.height * leftY[pos])
                }
            }

            ForEach(Array(rightIndices.enumerated()), id: \.offset) { pos, stringIndex in
                if stringIndex < strings.count {
                    pegButton(for: strings[stringIndex])
                        .position(x: size.width * 0.94, y: size.height * rightY[pos])
                }
            }
        }
    }

    private func pegButton(for string: InstrumentString) -> some View {
        StringPegButton(
            string: string,
            isSelected: selectedString?.id == string.id,
            isTuned: tunedString?.id == string.id,
            onTap: { onPegTap(string) }
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Headstock Paddle Shape
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// A simplified, abstract headstock paddle — wide at the top (peg area),
/// tapering down to a narrow nut at the bottom where the neck continues off-screen.
struct HeadstockPaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w * 0.5, y: h))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.82))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.02, y: h * 0.22),
            control: CGPoint(x: w * 0.0, y: h * 0.55)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.22, y: 0),
            control: CGPoint(x: w * 0.02, y: 0)
        )
        path.addLine(to: CGPoint(x: w * 0.78, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.98, y: h * 0.22),
            control: CGPoint(x: w * 0.98, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.82),
            control: CGPoint(x: w, y: h * 0.55)
        )
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - String Peg Button (floating label, acid/black theme)

/// Circular floating note label for each tuning peg
struct StringPegButton: View {
    let string: InstrumentString
    let isSelected: Bool
    let isTuned: Bool
    let onTap: () -> Void

    private var bgColor: Color {
        if isTuned { return LearningPath.acid }
        if isSelected { return Color(hex: "D5FBFF") }
        return Color(hex: "353534")
    }

    private var textColor: Color {
        if isTuned { return Color(hex: "1F1F1F") }
        if isSelected { return Color(hex: "1F1F1F") }
        return Color(hex: "E2E2E2")
    }

    private var glowColor: Color {
        if isTuned { return LearningPath.acid }
        if isSelected { return Color(hex: "D5FBFF") }
        return .clear
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected || isTuned {
                    Circle()
                        .fill(glowColor.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)
                }

                Circle()
                    .fill(bgColor)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isTuned ? 0.5 : 0.1), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                Text(NoteFormatter.formatLetter(string.name))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
            }
        }
        .buttonStyle(PegTapStyle())
        .scaleEffect(isTuned ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isTuned)
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

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "131313").ignoresSafeArea()
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
    }
}
