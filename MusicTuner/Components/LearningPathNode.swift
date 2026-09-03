//
//  LearningPathNode.swift
//  MusicTuner
//
//  Shared "winding path" curriculum map visual (Duolingo-style) used by
//  Ear Training, Fretboard Training, and Chord Mastery level-select screens.
//

import SwiftUI

// MARK: - Node State

enum PathNodeState {
    case completed
    case current
    case locked
}

// MARK: - Shared Layout Math

enum LearningPath {
    static let acid = Color(hex: "E1EC00")
    static let acidDim = Color(hex: "C5CF00")
    static let lockedFill = Color(hex: "353535")
    static let lockedBorder = Color(hex: "0E0E0E")

    static let nodeSpacing: CGFloat = 130

    /// Horizontal offset for a node at the given index, creating an organic winding path.
    static func offset(for index: Int) -> CGFloat {
        CGFloat(sin(Double(index) * 1.4)) * 70
    }

    /// Center point (relative to the path container) for a node at the given index.
    static func center(for index: Int, containerWidth: CGFloat) -> CGPoint {
        CGPoint(
            x: containerWidth / 2 + offset(for: index),
            y: CGFloat(index) * nodeSpacing + nodeSpacing / 2
        )
    }
}

// MARK: - Connector Shape

/// Draws the curved connector line through every node's center, from `startIndex` to `endIndex` (inclusive).
struct LearningPathConnector: Shape {
    let nodeCount: Int
    let startIndex: Int
    let endIndex: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard nodeCount > 1, endIndex > startIndex else { return path }

        let points = (startIndex...endIndex).map { LearningPath.center(for: $0, containerWidth: rect.width) }
        path.move(to: points[0])
        for i in 1..<points.count {
            let previous = points[i - 1]
            let current = points[i]
            let controlY = (previous.y + current.y) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: previous.x, y: controlY),
                control2: CGPoint(x: current.x, y: controlY)
            )
        }
        return path
    }
}

// MARK: - Node View

struct LearningPathNodeView: View {
    let state: PathNodeState
    let icon: String
    let startLessonLabel: String

    @State private var pulse = false

    private var diameter: CGFloat {
        switch state {
        case .completed: return 72
        case .current: return 88
        case .locked: return 64
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if state == .current {
                Text(startLessonLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LearningPath.acid)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "2A2A2A"))
                    )
                    .padding(.bottom, 10)
            }

            ZStack {
                if state == .current {
                    Circle()
                        .fill(LearningPath.acid.opacity(0.25))
                        .frame(width: diameter * 1.6, height: diameter * 1.6)
                        .scaleEffect(pulse ? 1.08 : 0.92)
                        .opacity(pulse ? 0.35 : 0.7)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }

                Circle()
                    .fill(state == .locked ? LearningPath.lockedFill : LearningPath.acid)
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle()
                            .strokeBorder(state == .locked ? LearningPath.lockedBorder : LearningPath.acidDim, lineWidth: 4)
                            .offset(y: 3)
                            .mask(Circle().frame(width: diameter, height: diameter))
                    )
                    .shadow(color: state == .locked ? .clear : LearningPath.acid.opacity(state == .current ? 0.5 : 0.25),
                            radius: state == .current ? 20 : 10)

                Image(systemName: icon)
                    .font(.system(size: diameter * 0.42, weight: .bold))
                    .foregroundStyle(state == .locked ? Color(hex: "929277") : Color(hex: "303300"))
            }
        }
        .opacity(state == .locked ? 0.6 : 1)
        .onAppear { pulse = true }
    }
}
