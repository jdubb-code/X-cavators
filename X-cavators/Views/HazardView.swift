//
//  HazardView.swift
//  X-cavators
//
//  Visual representation of hazards
//

import SwiftUI

struct HazardView: View {
    let hazard: Hazard

    var body: some View {
        ZStack {
            switch hazard.type {
            case .rock:
                rockView
            case .puddle:
                puddleView
            case .mud:
                mudView
            }
        }
        .position(hazard.position)
    }

    private var rockView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.45, blue: 0.4),
                            Color(red: 0.4, green: 0.35, blue: 0.3),
                            Color(red: 0.3, green: 0.25, blue: 0.2)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: hazard.radius
                    )
                )
                .frame(width: hazard.radius * 2, height: hazard.radius * 2)

            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: hazard.radius * 0.6, height: hazard.radius * 0.6)
                .offset(x: hazard.radius * 0.2, y: hazard.radius * 0.2)

            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: hazard.radius * 0.3, height: hazard.radius * 0.3)
                .offset(x: -hazard.radius * 0.3, y: -hazard.radius * 0.3)
        }
        .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 3)
    }

    private var puddleView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.4, green: 0.6, blue: 0.8).opacity(0.7),
                            Color(red: 0.3, green: 0.5, blue: 0.7).opacity(0.8),
                            Color(red: 0.25, green: 0.45, blue: 0.65).opacity(0.9)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: hazard.radius
                    )
                )
                .frame(width: hazard.radius * 2, height: hazard.radius * 2)

            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: hazard.radius * 1.8, height: hazard.radius * 1.8)

            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: hazard.radius * 0.4, height: hazard.radius * 0.2)
                .offset(x: -hazard.radius * 0.3, y: -hazard.radius * 0.3)
        }
        .opacity(0.8)
    }

    private var mudView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.4, blue: 0.3).opacity(0.6),
                            Color(red: 0.45, green: 0.35, blue: 0.25).opacity(0.7),
                            Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: hazard.radius
                    )
                )
                .frame(width: hazard.radius * 2, height: hazard.radius * 2)

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: hazard.radius * 0.3, height: hazard.radius * 0.3)
                    .offset(
                        x: cos(Double(index) * 1.2) * Double(hazard.radius) * 0.5,
                        y: sin(Double(index) * 1.2) * Double(hazard.radius) * 0.5
                    )
            }
        }
        .opacity(0.7)
    }
}
