import SwiftUI

struct FretboardInteractiveView: View {
    @ObservedObject var viewModel: ChordMakerViewModel

    // 6 strings (0 to 5, mapping to E A D G B e). We draw 6 columns.
    // Low E is on the left (index 0).

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                nutRow

                // Frets 1 to 12
                ForEach(1...12, id: \.self) { fret in
                    fretRow(fret: fret)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private var nutRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { stringIndex in
                let state = viewModel.state.strings[stringIndex]

                Button(action: {
                    viewModel.toggleNut(stringIndex: stringIndex)
                }) {
                    Text(state == nil ? "X" : (state == 0 ? "O" : ""))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(state == nil ? Color(hex: "FF5A5A") : LearningPath.acid)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private func fretRow(fret: Int) -> some View {
        ZStack {
            // Fret background and string lines
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { stringIndex in
                    ZStack {
                        // Fretboard background
                        Rectangle()
                            .fill(Color(hex: "1F1F1F"))

                        // String line
                        // Thicker for lower strings
                        Rectangle()
                            .fill(Color(hex: "6B6B66"))
                            .frame(width: CGFloat(6 - stringIndex) * 0.5 + 0.5)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 0)

                        // Fret marker dots (on 3, 5, 7, 9, 12)
                        if stringIndex == 2 && [3, 5, 7, 9].contains(fret) {
                            Circle()
                                .fill(Color(hex: "929277").opacity(0.5))
                                .frame(width: 12, height: 12)
                        } else if (stringIndex == 1 || stringIndex == 4) && fret == 12 {
                            Circle()
                                .fill(Color(hex: "929277").opacity(0.5))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    // Tap interaction for placing tool
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.placeTool(stringIndex: stringIndex, fret: fret)
                    }
                }
            }

            // Fret wire at the bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(hex: "353534"))
                    .frame(height: 2)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            }

            // Render barre if present
            if let barreFret = viewModel.state.barreFret, barreFret == fret {
                barreOverlay
            }

            // Render fingers
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { stringIndex in
                    ZStack {
                        if viewModel.state.strings[stringIndex] == fret {
                            Circle()
                                .fill(LearningPath.acid)
                                .frame(width: 28, height: 28)
                                .shadow(color: LearningPath.acid.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var barreOverlay: some View {
        GeometryReader { geo in
            Capsule()
                .fill(LearningPath.acid.opacity(0.6))
                .frame(height: 20)
                .padding(.horizontal, geo.size.width / 12) // Approximate padding to center on outer strings
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .allowsHitTesting(false)
    }
}
