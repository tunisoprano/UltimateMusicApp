//
//  TempoTrainingSignatureSelectView.swift
//  MusicTuner
//
//  Entry screen for Tempo Training — pick a time signature, then start.
//  "Playful Premium" acid/black theme, matches MetronomeView/TunerView.
//

import SwiftUI

struct TempoTrainingSignatureSelectView: View {
    private let acid = Color(hex: "E1EC00")

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(acid.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "metronome.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(acid)
                }

                VStack(spacing: 8) {
                    Text(L("tempo_training_select_signature"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "E2E2E2"))

                    Text(L("tempo_training_select_signature_desc"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "929277"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    ForEach(TempoSignatureChoice.allCases) { choice in
                        NavigationLink(destination: TempoTrainingView(signatureChoice: choice)) {
                            signatureRow(choice)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
        .navigationTitle(L("tempo_training"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func signatureRow(_ choice: TempoSignatureChoice) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(acid.opacity(0.15))
                    .frame(width: 52, height: 52)

                if choice == .mixed {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(acid)
                } else {
                    Text(choice.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(acid)
                }
            }

            Text(choice.localizedTitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "929277"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1F1F1F"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "353534"), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        TempoTrainingSignatureSelectView()
    }
}
