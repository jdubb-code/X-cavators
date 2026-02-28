//
//  BatteryDepletedModalView.swift
//  X-cavators
//
//  Modal displayed when rover battery hits 0 in manual mode
//

import SwiftUI

struct BatteryDepletedModalView: View {
    let coins: Int
    let canAffordTow: Bool
    let onPayCoins: () -> Void
    let onTrivia: () -> Void

    private let towCost = 20
    private let orangeAccent = Color.orange

    var body: some View {
        ZStack {
            // Dimmed background overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Modal container
            VStack(spacing: 24) {
                // Battery icon
                Image(systemName: "battery.0percent")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                // Heading
                VStack(spacing: 8) {
                    Text("BATTERY DEPLETED")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Text("Your rover has run out of power")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                // Info box
                VStack(spacing: 12) {
                    Text("Your rover is stranded in the field.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("Call for a tow to be brought back to base with a 40% charge.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )

                // Tow cost
                HStack(spacing: 12) {
                    Text("Tow Cost:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(orangeAccent)
                            .font(.system(size: 20))
                        Text("\(towCost)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(orangeAccent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(orangeAccent.opacity(0.5), lineWidth: 2)
                        )
                )

                // Your coins
                HStack(spacing: 8) {
                    Text("Your Coins:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(orangeAccent)
                            .font(.system(size: 16))
                        Text("\(coins)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                // Pay coins button
                Button(action: onPayCoins) {
                    HStack(spacing: 12) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 20))
                        Text("TOW TO BASE — \(towCost) COINS")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(canAffordTow ? .black : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canAffordTow ? orangeAccent : Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                .disabled(!canAffordTow)

                // Trivia option (always available)
                Button(action: onTrivia) {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ANSWER TRIVIA")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("Answer 2 questions for a free tow")
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

                if !canAffordTow {
                    Text("⚠️ Not enough coins! Earn coins by discovering artifacts, or answer trivia for a free tow.")
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
                            .stroke(Color.orange, lineWidth: 3)
                    )
            )
            .shadow(color: Color.orange.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}
