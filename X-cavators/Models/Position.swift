//
//  Position.swift
//  X-cavators
//
//  Game math helpers for position and vector calculations
//

import SwiftUI

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func +=(lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }

    func angle(to point: CGPoint) -> Angle {
        let dx = point.x - x
        let dy = point.y - y
        return Angle(radians: atan2(dy, dx))
    }
}

extension CGVector {
    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    var normalized: CGVector {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return CGVector(dx: dx / mag, dy: dy / mag)
    }

    func scaled(by factor: CGFloat) -> CGVector {
        CGVector(dx: dx * factor, dy: dy * factor)
    }

    var angle: Angle {
        Angle(radians: atan2(dy, dx))
    }

    static func *(lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}
