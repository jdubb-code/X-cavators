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
    var batteryLevel: CGFloat

    let maxSpeed: CGFloat = 200
    let acceleration: CGFloat = 800
    let deceleration: CGFloat = 600
    let maxBattery: CGFloat = 100.0
    let batteryDrainRate: CGFloat = 2.0  // Battery per second while moving
    let batteryRechargeRate: CGFloat = 15.0  // Battery per second at home base

    init(position: CGPoint = .zero, size: CGSize = CGSize(width: 50, height: 50)) {
        self.position = position
        self.rotation = .zero
        self.velocity = .zero
        self.size = size
        self.batteryLevel = 100.0
    }

    mutating func update(joystickInput: CGVector, deltaTime: Double, bounds: CGRect, speedMultiplier: CGFloat = 1.0, effectiveMaxSpeed: CGFloat? = nil, effectiveDrainRate: CGFloat? = nil) {
        let dt = CGFloat(deltaTime)
        let speed = effectiveMaxSpeed ?? maxSpeed
        let drainRate = effectiveDrainRate ?? batteryDrainRate

        // Only allow movement if battery is available
        let effectiveInput = batteryLevel > 0 ? joystickInput : .zero

        if effectiveInput.magnitude > 0.1 {
            let targetVelocity = effectiveInput.normalized.scaled(by: speed * effectiveInput.magnitude * speedMultiplier)
            velocity = lerp(from: velocity, to: targetVelocity, factor: min(acceleration * dt / speed, 1.0))
            if velocity.magnitude > 0.1 {
                rotation = velocity.angle
            }

            // Drain battery while moving
            batteryLevel = max(0, batteryLevel - drainRate * dt)
        } else {
            let decelerationFactor = max(0, 1.0 - (deceleration * dt / speed))
            velocity = velocity.scaled(by: decelerationFactor)
            if velocity.magnitude < 1 {
                velocity = .zero
            }
        }

        position += velocity.scaled(by: dt)

        position.x = max(bounds.minX + size.width / 2, min(bounds.maxX - size.width / 2, position.x))
        position.y = max(bounds.minY + size.height / 2, min(bounds.maxY - size.height / 2, position.y))
    }

    mutating func recharge(deltaTime: Double, effectiveMaxBattery: CGFloat? = nil) {
        let dt = CGFloat(deltaTime)
        let maxBatt = effectiveMaxBattery ?? maxBattery
        batteryLevel = min(maxBatt, batteryLevel + batteryRechargeRate * dt)
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
