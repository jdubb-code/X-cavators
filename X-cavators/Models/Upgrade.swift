//
//  Upgrade.swift
//  X-cavators
//
//  Upgrade system for shop purchases
//

import Foundation

enum UpgradeType: String, Codable {
    case gprUpgrade
    case speedBoost
    case extraBattery
    case terrainScanner
    case deepDrill
    case armorPlating
    case solarPanel
}

struct Upgrade: Identifiable, Codable {
    let id: UpgradeType
    let name: String
    let description: String
    let basePrice: Int
    let icon: String
    var level: Int = 0
    let maxLevel: Int = 5

    var price: Int {
        let multiplier = pow(1.5, Double(level))
        return Int(Double(basePrice) * multiplier)
    }

    var isPurchased: Bool {
        level > 0
    }

    var canUpgrade: Bool {
        level < maxLevel
    }

    var displayName: String {
        if level > 0 {
            return "\(name) Lv.\(level + 1)"
        }
        return name
    }

    var displayDescription: String {
        if level > 0 {
            let bonus: Int
            switch id {
            case .gprUpgrade, .extraBattery:
                bonus = level * 50  // 50% per level
            case .speedBoost, .deepDrill:
                bonus = level * 25  // 25% per level
            case .solarPanel:
                bonus = level * 20  // 20% per level
            case .terrainScanner, .armorPlating:
                bonus = level * 30  // 30% per level (visual/protection)
            }
            return "\(description) (+\(bonus)%)"
        }
        return description
    }
}
