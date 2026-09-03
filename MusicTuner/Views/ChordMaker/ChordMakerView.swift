import SwiftUI

struct ChordMakerView: View {
    @StateObject private var viewModel = ChordMakerViewModel()
    let theme = ThemeManager.shared

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (Chord Info + Strum)

                headerView
                suggestionsView


                // Interactive Fretboard
                FretboardInteractiveView(viewModel: viewModel)
                    .background(Color(hex: "1A1A1A").ignoresSafeArea())

                // Toolbar
                toolbarView
            }
        }
        .navigationTitle(L("chord_maker"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.clearAll()
                }) {
                    Text(L("clear"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LearningPath.acid)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.identifiedChordName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "E2E2E2"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                viewModel.strum()
            }) {
                HStack {
                    Image(systemName: "guitars.fill")
                    Text(L("strum"))
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "303300"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(LearningPath.acid)
                .cornerRadius(12)
                .shadow(color: LearningPath.acid.opacity(0.35), radius: 8, y: 3)
            }
        }
        .padding(20)
        .background(Color(hex: "1F1F1F"))
    }


    private var suggestionsView: some View {
        Group {
            if !viewModel.suggestedChords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Text(L("did_you_mean"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "C8C8AB"))

                        ForEach(viewModel.suggestedChords, id: \.id) { chord in
                            Button(action: {
                                withAnimation {
                                    viewModel.applySuggestion(chord)
                                }
                            }) {
                                Text(chord.displayName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "303300"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(LearningPath.acid)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .background(Color(hex: "1F1F1F"))
            }
        }
    }

    private var toolbarView: some View {
        HStack(spacing: 24) {
            Spacer()

            toolButton(tool: .finger, icon: "hand.point.up.fill", label: L("finger"))

            Divider().frame(height: 30)
                .overlay(Color(hex: "353534"))

            toolButton(tool: .barre, icon: "B", label: L("barre"))

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(hex: "1F1F1F").shadow(radius: 5))
    }

    private func toolButton(tool: ChordMakerTool, icon: String, label: String? = nil) -> some View {
        let isActive = viewModel.activeTool == tool

        return Button(action: {
            viewModel.activeTool = tool
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isActive ? LearningPath.acid : Color(hex: "353534"))
                        .frame(width: 44, height: 44)

                    if icon.count > 2 {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(isActive ? Color(hex: "303300") : Color(hex: "E2E2E2"))
                    } else {
                        Text(icon)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(isActive ? Color(hex: "303300") : Color(hex: "E2E2E2"))
                    }
                }

                if let label = label {
                    Text(label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? LearningPath.acid : Color(hex: "929277"))
                }
            }
        }
    }
}
