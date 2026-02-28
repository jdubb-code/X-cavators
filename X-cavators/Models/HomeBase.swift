//
//  HomeBase.swift
//  X-cavators
//
//  Home base model for rover recharging
//

import SwiftUI

struct HomeBase {
    let position: CGPoint
    let size: CGSize
    let rechargeRadius: CGFloat

    init(position: CGPoint, size: CGSize = CGSize(width: 80, height: 80), rechargeRadius: CGFloat = 100) {
        self.position = position
        self.size = size
        self.rechargeRadius = rechargeRadius
    }

    func isRoverInRange(rover: Rover) -> Bool {
        let dx = rover.position.x - position.x
        let dy = rover.position.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= rechargeRadius
    }
}
