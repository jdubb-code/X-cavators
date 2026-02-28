//
//  ShopView.swift
//  X-cavators
//
//  Shop interface for purchasing items with coins
//

import SwiftUI

struct ShopView: View {
    let onDismiss: () -> Void
    let currentCoins: Int
    let upgrades: [Upgrade]
    let onPurchase: (UpgradeType) -> Void

    private let goldenAccent = Color(red: 0.95, green: 0.77, blue: 0.06)

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SHOP")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(goldenAccent)

                    Spacer()

                    // Coin display
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(goldenAccent)
                            .font(.system(size: 20))
                        Text("\(currentCoins)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(goldenAccent.opacity(0.5), lineWidth: 2)
                            )
                    )

                    Spacer()

                    // Close button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Scrollable shop items
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(upgrades) { upgrade in
                            ShopUpgradeRow(
                                upgrade: upgrade,
                                currentCoins: currentCoins,
                                goldenAccent: goldenAccent,
                                onPurchase: onPurchase
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }

                // Footer with close button
                Button(action: onDismiss) {
                    Text("CLOSE SHOP")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.red,
                                    Color.red.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }
}

struct ShopUpgradeRow: View {
    let upgrade: Upgrade
    let currentCoins: Int
    let goldenAccent: Color
    let onPurchase: (UpgradeType) -> Void

    var canAfford: Bool {
        currentCoins >= upgrade.price && upgrade.canUpgrade
    }

    var isMaxLevel: Bool {
        !upgrade.canUpgrade
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon with level badge
            ZStack {
                Circle()
                    .fill(isMaxLevel ? Color.purple.opacity(0.3) : (upgrade.isPurchased ? Color.green.opacity(0.3) : (canAfford ? goldenAccent.opacity(0.2) : Color.gray.opacity(0.2))))
                    .frame(width: 60, height: 60)

                if isMaxLevel {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.purple)
                } else {
                    Image(systemName: upgrade.icon)
                        .font(.system(size: 28))
                        .foregroundColor(upgrade.isPurchased ? .green : (canAfford ? goldenAccent : .gray))
                }

                // Level badge
                if upgrade.level > 0 {
                    Text("\(upgrade.level)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(isMaxLevel ? Color.purple : Color.blue))
                        .offset(x: 20, y: -20)
                }
            }

            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(upgrade.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isMaxLevel ? .purple : (upgrade.isPurchased ? .green : (canAfford ? .white : .gray)))

                Text(upgrade.displayDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isMaxLevel ? .purple.opacity(0.8) : (upgrade.isPurchased ? .green.opacity(0.8) : (canAfford ? .white.opacity(0.7) : .gray.opacity(0.7))))
                    .lineLimit(2)
            }

            Spacer()

            // Price and buy button
            VStack(spacing: 8) {
                if !isMaxLevel {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(goldenAccent)
                            .font(.system(size: 14))
                        Text("\(upgrade.price)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        onPurchase(upgrade.id)
                    }) {
                        Text(upgrade.isPurchased ? "UPGRADE" : "BUY")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(canAfford ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(canAfford ? goldenAccent : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .disabled(!canAfford)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                        Text("MAX")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isMaxLevel ? Color.purple.opacity(0.5) : (upgrade.isPurchased ? Color.green.opacity(0.5) : (canAfford ? goldenAccent.opacity(0.3) : Color.gray.opacity(0.2))), lineWidth: 2)
                )
        )
    }
}

//#Preview {
//    var upgrades = [
//        Upgrade(id: .gprUpgrade, name: "GPR Upgrade", description: "Increase detection radius", basePrice: 150, icon: "antenna.radiowaves.left.and.right"),
//        Upgrade(id: .speedBoost, name: "Speed Boost", description: "Faster rover movement", basePrice: 200, icon: "hare.fill", level: 2)
//    ]
//
//    return ShopView(
//        onDismiss: {},
//        currentCoins: 250,
//        upgrades: upgrades,
//        onPurchase: { _ in }
//    )
//}
