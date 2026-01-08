//
//  RoverView.swift
//  X-cavators
//
//  Rover visual representation
//

import SwiftUI

struct RoverView: View {
    let rover: Rover

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.77, blue: 0.06),
                            Color(red: 0.85, green: 0.65, blue: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: rover.size.width, height: rover.size.height)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                .frame(width: rover.size.width * 0.6, height: rover.size.height * 0.5)

            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 12, height: 12)
                .offset(x: rover.size.width * 0.25, y: 0)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                .frame(width: 15, height: 8)
                .offset(x: rover.size.width * 0.35, y: 0)
        }
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        .rotationEffect(rover.rotation)
        .position(rover.position)
    }
}
