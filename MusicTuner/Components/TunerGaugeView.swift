//
//  TunerGaugeView.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import SwiftUI

/// Animated tuner gauge/needle indicator
struct TunerGaugeView: View {
    let needlePosition: Double // -1 (flat) to 1 (sharp)
    let tuningState: TuningState
    let centsDeviation: Double
    
    private let gaugeWidth: CGFloat = 280
    private let gaugeHeight: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 16) {
            // Gauge Container
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: gaugeWidth, height: gaugeHeight)
                
                // Center line (perfect tune indicator)
                Rectangle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 4, height: gaugeHeight + 10)
                
                // Side markers
                HStack(spacing: 0) {
                    ForEach(-5..<6) { i in
                        if i != 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1, height: i % 5 == 0 ? 20 : 10)
                        }
                        if i < 5 {
                            Spacer()
                        }
                    }
                }
                .frame(width: gaugeWidth - 20)
                
                // Needle/Indicator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [needleColor, needleColor.opacity(0.6)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: needleColor.opacity(0.5), radius: 10)
                    .offset(x: CGFloat(needlePosition) * (gaugeWidth / 2 - CGFloat(20)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: needlePosition)
            }
            
            // Cents display
            HStack {
                Text("-50")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.gray)
                
                Spacer()
                
                Text(centsText)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(needleColor)
                
                Spacer()
                
                Text("+50")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.gray)
            }
            .frame(width: gaugeWidth)
        }
    }
    
    private var needleColor: Color {
        switch tuningState {
        case .inTune:
            return .green
        case .close:
            return .yellow
        case .sharp, .flat:
            return .red
        case .noSignal:
            return .gray
        }
    }
    
    private var centsText: String {
        if tuningState == .noSignal {
            return "-- cents"
        }
        let sign = centsDeviation >= 0 ? "+" : ""
        return "\(sign)\(Int(centsDeviation)) cents"
    }
}

/// Alternative circular gauge design
struct CircularTunerGauge: View {
    let needlePosition: Double
    let tuningState: TuningState
    
    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            // Colored arc based on tuning
            Circle()
                .trim(from: 0.25, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [.red, .yellow, .green, .yellow, .red],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(90)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(180))
            
            // Needle
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 80)
                .offset(y: -40)
                .rotationEffect(.degrees(needlePosition * 90))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: needlePosition)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            TunerGaugeView(needlePosition: 0.3, tuningState: .sharp, centsDeviation: 15)
            TunerGaugeView(needlePosition: 0, tuningState: .inTune, centsDeviation: 2)
            TunerGaugeView(needlePosition: -0.5, tuningState: .flat, centsDeviation: -25)
        }
    }
}
