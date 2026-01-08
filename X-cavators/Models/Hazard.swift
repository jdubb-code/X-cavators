//
//  Hazard.swift
//  X-cavators
//
//  Hazard model for obstacles and terrain effects
//

import SwiftUI

enum HazardType {
    case rock
    case puddle
    case mud

    var isObstacle: Bool {
        switch self {
        case .rock, .puddle:
            return true
        case .mud:
            return false
        }
    }

    var speedMultiplier: CGFloat {
        switch self {
        case .rock, .puddle:
            return 1.0
        case .mud:
            return 0.3
        }
    }

    var color: Color {
        switch self {
        case .rock:
            return Color(red: 0.4, green: 0.35, blue: 0.3)
        case .puddle:
            return Color(red: 0.3, green: 0.5, blue: 0.7)
        case .mud:
            return Color(red: 0.45, green: 0.35, blue: 0.25)
        }
    }
}

struct Hazard: Identifiable {
    let id = UUID()
    let position: CGPoint
    let radius: CGFloat
    let type: HazardType

    func contains(point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= radius
    }

    func willCollide(with rover: Rover) -> Bool {
        guard type.isObstacle else { return false }

        let dx = rover.position.x - position.x
        let dy = rover.position.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        let minDistance = radius + min(rover.size.width, rover.size.height) / 2

        return distance < minDistance
    }
}
