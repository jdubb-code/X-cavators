//
//  MapView.swift
//  X-cavators
//
//  Game terrain/background with archeological theme
//

import SwiftUI

struct MapView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.83, green: 0.71, blue: 0.55),
                        Color(red: 0.76, green: 0.63, blue: 0.47),
                        Color(red: 0.70, green: 0.60, blue: 0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Canvas { context, size in
                    let gridSpacing: CGFloat = 50
                    context.stroke(
                        Path { path in
                            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            }
                            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            }
                        },
                        with: .color(.white.opacity(0.1)),
                        lineWidth: 1
                    )
                }
            )
    }
}
