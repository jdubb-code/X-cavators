//
//  JoystickView.swift
//  X-cavators
//
//  Joystick control component with drag gesture
//

import SwiftUI

struct JoystickView: View {
    @Binding var output: CGVector

    @State private var knobPosition: CGSize = .zero

    let baseRadius: CGFloat = 60
    let knobRadius: CGFloat = 25
    let deadZone: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.55, green: 0.40, blue: 0.27).opacity(0.4),
                            Color(red: 0.45, green: 0.32, blue: 0.20).opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseRadius
                    )
                )
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.65, green: 0.47, blue: 0.32),
                            Color(red: 0.55, green: 0.40, blue: 0.27)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: knobRadius
                    )
                )
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .offset(knobPosition)
                .gesture(dragGesture)
        }
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation
                let distance = sqrt(translation.width * translation.width + translation.height * translation.height)

                if distance <= baseRadius {
                    knobPosition = translation
                } else {
                    let angle = atan2(translation.height, translation.width)
                    knobPosition = CGSize(
                        width: cos(angle) * baseRadius,
                        height: sin(angle) * baseRadius
                    )
                }

                if distance < deadZone {
                    output = .zero
                } else {
                    let clampedDistance = min(distance, baseRadius)
                    let normalizedDistance = (clampedDistance - deadZone) / (baseRadius - deadZone)
                    let angle = atan2(translation.height, translation.width)

                    output = CGVector(
                        dx: cos(angle) * normalizedDistance,
                        dy: sin(angle) * normalizedDistance
                    )
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    knobPosition = .zero
                }
                output = .zero
            }
    }
}
