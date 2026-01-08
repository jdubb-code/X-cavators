//
//  GridOverlayView.swift
//  X-cavators
//
//  Grid overlay for autonomous scan mode
//

import SwiftUI

struct GridOverlayView: View {
    let waypoints: [CGPoint]
    let currentIndex: Int
    let roverPosition: CGPoint
    let gridSpacing: CGFloat = 50

    var body: some View {
        Canvas { context, size in
            // Draw grid lines
            for x in stride(from: gridSpacing, through: size.width - gridSpacing, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }

            for y in stride(from: gridSpacing, through: size.height - gridSpacing, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }

            // Draw waypoints
            for (index, waypoint) in waypoints.enumerated() {
                let circle = Path(ellipseIn: CGRect(
                    x: waypoint.x - 3,
                    y: waypoint.y - 3,
                    width: 6,
                    height: 6
                ))

                if index < currentIndex {
                    // Completed waypoints
                    context.fill(circle, with: .color(.gray.opacity(0.5)))
                } else if index == currentIndex {
                    // Current waypoint
                    context.fill(circle, with: .color(.green))
                    context.stroke(circle, with: .color(.white), lineWidth: 2)
                } else {
                    // Future waypoints
                    context.fill(circle, with: .color(.white.opacity(0.3)))
                }
            }
        }
    }
}
