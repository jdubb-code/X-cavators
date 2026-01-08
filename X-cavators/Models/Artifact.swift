//
//  Artifact.swift
//  X-cavators
//
//  Artifact model for archaeological discoveries
//

import SwiftUI

struct Artifact: Identifiable {
    let id = UUID()
    let position: CGPoint
    let name: String
    let isDeep: Bool
    let scansRequired: Int
    var isDiscovered: Bool = false
    var scanCount: Int = 0

    var isIdentified: Bool {
        if !isDeep {
            return isDiscovered
        } else {
            return isDiscovered && scanCount >= scansRequired
        }
    }

    var displayName: String {
        if !isDiscovered {
            return "???"
        } else if !isIdentified {
            return "Unknown"
        } else {
            return name
        }
    }

    func isInRange(of rover: Rover, detectionRadius: CGFloat) -> Bool {
        let dx = rover.position.x - position.x
        let dy = rover.position.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= detectionRadius
    }
}
