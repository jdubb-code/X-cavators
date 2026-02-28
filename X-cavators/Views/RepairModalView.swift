//
//  RepairModalView.swift
//  X-cavators
//
//  Modal dialog displayed when rover needs repair
//

import SwiftUI

struct RepairModalView: View {
    let damage: Int
    let coins: Int
    let canAffordRepair: Bool
    let onRepair: () -> Void
    let onTrivia: () -> Void

    private let repairCost = 30
    private let goldenAccent = Color(red: 0.95, green: 0.77, blue: 0.06)

    var body: some View {
        ZStack {
            // Dimmed background overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Modal container
            VStack(spacing: 24) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                // Damage critical message
                VStack(spacing: 8) {
                    Text("DAMAGE CRITICAL!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.red)

                    Text("Rover has sustained \(damage)% damage")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                // Info box
                VStack(spacing: 12) {
                    Text("Your rover has been returned to base for repairs.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("You must repair the rover before continuing exploration.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )

                // Repair cost
                HStack(spacing: 12) {
                    Text("Repair Cost:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(goldenAccent)
                            .font(.system(size: 20))
                        Text("\(repairCost)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(goldenAccent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(goldenAccent.opacity(0.5), lineWidth: 2)
                        )
                )

                // Your coins
                HStack(spacing: 8) {
                    Text("Your Coins:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(goldenAccent)
                            .font(.system(size: 16))
                        Text("\(coins)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                // Repair button
                Button(action: onRepair) {
                    HStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 20))
                        Text("REPAIR ROVER")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(canAffordRepair ? .black : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canAffordRepair ? goldenAccent : Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                .disabled(!canAffordRepair)

                // Trivia option (always available)
                Button(action: onTrivia) {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ANSWER TRIVIA")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("Answer 2 questions for a free repair")
                                .font(.system(size: 12, weight: .regular))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.7))
                    .cornerRadius(12)
                }

                if !canAffordRepair {
                    Text("⚠️ Not enough coins! Earn coins by discovering artifacts, or answer trivia for a free repair.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(30)
            .frame(maxWidth: 450)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 3)
                    )
            )
            .shadow(color: Color.red.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

//#Preview {
//    RepairModalView(
//        damage: 100,
//        coins: 75,
//        canAffordRepair: true,
//        onRepair: {},
//        onTrivia: {}
//    )
//}
