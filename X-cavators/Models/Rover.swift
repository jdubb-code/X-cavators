//
//  Rover.swift
//  X-cavators
//
//  Rover model with movement and physics logic
//

import SwiftUI

struct Rover {
    var position: CGPoint
    var rotation: Angle
    var velocity: CGVector
    var size: CGSize

    let maxSpeed: CGFloat = 200
    let acceleration: CGFloat = 800
    let deceleration: CGFloat = 600

    init(position: CGPoint = .zero, size: CGSize = CGSize(width: 50, height: 50)) {
        self.position = position
        self.rotation = .zero
        self.velocity = .zero
        self.size = size
    }

    mutating func update(joystickInput: CGVector, deltaTime: Double, bounds: CGRect, speedMultiplier: CGFloat = 1.0) {
        let dt = CGFloat(deltaTime)

        if joystickInput.magnitude > 0.1 {
            let targetVelocity = joystickInput.normalized.scaled(by: maxSpeed * joystickInput.magnitude * speedMultiplier)
            velocity = lerp(from: velocity, to: targetVelocity, factor: min(acceleration * dt / maxSpeed, 1.0))
            if velocity.magnitude > 0.1 {
                rotation = velocity.angle
            }
        } else {
            let decelerationFactor = max(0, 1.0 - (deceleration * dt / maxSpeed))
            velocity = velocity.scaled(by: decelerationFactor)
            if velocity.magnitude < 1 {
                velocity = .zero
            }
        }

        position += velocity.scaled(by: dt)

        position.x = max(bounds.minX + size.width / 2, min(bounds.maxX - size.width / 2, position.x))
        position.y = max(bounds.minY + size.height / 2, min(bounds.maxY - size.height / 2, position.y))
    }

    mutating func revertPosition(to oldPosition: CGPoint) {
        position = oldPosition
    }

    private func lerp(from: CGVector, to: CGVector, factor: CGFloat) -> CGVector {
        CGVector(
            dx: from.dx + (to.dx - from.dx) * factor,
            dy: from.dy + (to.dy - from.dy) * factor
        )
    }
}
