//
//  GPRDisplayView.swift
//  X-cavators
//
//  GPR (Ground Penetrating Radar) display showing nearby artifacts
//

import SwiftUI

struct GPRDisplayView: View {
    let rover: Rover
    let artifacts: [Artifact]
    let hazards: [Hazard]
    let detectionRadius: CGFloat

    let displaySize: CGFloat = 120

    var body: some View {
        VStack(spacing: 4) {
            Text("GPR")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.2))

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: displaySize, height: displaySize)

                Circle()
                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.3), lineWidth: 1)
                    .frame(width: displaySize * 0.9, height: displaySize * 0.9)

                Circle()
                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.2), lineWidth: 1)
                    .frame(width: displaySize * 0.6, height: displaySize * 0.6)

                Circle()
                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.1), lineWidth: 1)
                    .frame(width: displaySize * 0.3, height: displaySize * 0.3)

                ForEach(hazards) { hazard in
                    if let relativePosition = getRelativePositionForHazard(hazard: hazard) {
                        Circle()
                            .fill(hazard.type.color.opacity(0.7))
                            .frame(width: max(8, hazard.radius / 5), height: max(8, hazard.radius / 5))
                            .position(relativePosition)
                    }
                }

                ForEach(artifacts) { artifact in
                    if let relativePosition = getRelativePosition(artifact: artifact) {
                        Circle()
                            .fill(
                                !artifact.isDiscovered ?
                                Color(red: 0.2, green: 0.8, blue: 0.2) :
                                artifact.isIdentified ?
                                Color(red: 0.95, green: 0.77, blue: 0.06) :
                                Color.white
                            )
                            .frame(width: 6, height: 6)
                            .opacity(!artifact.isDiscovered ? 0.6 : 1.0)
                            .position(relativePosition)
                    }
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .position(x: displaySize / 2, y: displaySize / 2)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 6)
                    .offset(y: -4)
                    .position(x: displaySize / 2, y: displaySize / 2)
                    .rotationEffect(rover.rotation)
            }
            .frame(width: displaySize, height: displaySize)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.5), lineWidth: 2)
                )
        )
    }

    private func getRelativePosition(artifact: Artifact) -> CGPoint? {
        let dx = artifact.position.x - rover.position.x
        let dy = artifact.position.y - rover.position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance <= detectionRadius else { return nil }

        let scale = (displaySize / 2 - 10) / detectionRadius
        let relativeX = (displaySize / 2) + (dx * scale)
        let relativeY = (displaySize / 2) + (dy * scale)

        return CGPoint(x: relativeX, y: relativeY)
    }

    private func getRelativePositionForHazard(hazard: Hazard) -> CGPoint? {
        let dx = hazard.position.x - rover.position.x
        let dy = hazard.position.y - rover.position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance <= detectionRadius else { return nil }

        let scale = (displaySize / 2 - 10) / detectionRadius
        let relativeX = (displaySize / 2) + (dx * scale)
        let relativeY = (displaySize / 2) + (dy * scale)

        return CGPoint(x: relativeX, y: relativeY)
    }
}
