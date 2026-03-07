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
    let screenHeight: CGFloat
    let screenWidth: CGFloat
    let onRepair: () -> Void
    let onTrivia: () -> Void

    private let repairCost = 30
    private let goldenAccent = Color(red: 0.95, green: 0.77, blue: 0.06)

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var scale: CGFloat { min(1.0, screenHeight / 950) }
    private var isCompact: Bool { horizontalSizeClass == .compact }

    @ViewBuilder
    private func infoBox() -> some View {
        VStack(spacing: 12) {
            Text("Your rover has been returned to base for repairs.")
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            Text("You must repair the rover before continuing exploration.")
                .font(.system(size: 14 * scale, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(20 * scale)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
    }

    @ViewBuilder
    private func repairCostRow() -> some View {
        HStack(spacing: 12) {
            Text("Repair Cost:")
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundColor(.white)
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(goldenAccent)
                    .font(.system(size: 20 * scale))
                Text("\(repairCost)")
                    .font(.system(size: 24 * scale, weight: .bold, design: .rounded))
                    .foregroundColor(goldenAccent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(goldenAccent.opacity(0.5), lineWidth: 2))
        )
    }

    @ViewBuilder
    private func repairButton() -> some View {
        Button(action: onRepair) {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 20 * scale))
                Text("REPAIR ROVER")
                    .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
            }
            .foregroundColor(canAffordRepair ? .black : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16 * scale)
            .background(canAffordRepair ? goldenAccent : Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .disabled(!canAffordRepair)
    }

    @ViewBuilder
    private func triviaButton() -> some View {
        Button(action: onTrivia) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20 * scale))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ANSWER TRIVIA")
                        .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                    Text("Answer 2 questions for a free repair")
                        .font(.system(size: 12 * scale, weight: .regular))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14 * scale)
            .padding(.horizontal, 16)
            .background(Color(red: 0.2, green: 0.8, blue: 0.7))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func cardContent(screenWidth: CGFloat) -> some View {
        VStack(spacing: 24 * scale) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60 * scale))
                .foregroundColor(.red)

            VStack(spacing: 8) {
                Text("DAMAGE CRITICAL!")
                    .font(.system(size: 32 * scale, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                Text("Rover has sustained \(damage)% damage")
                    .font(.system(size: 18 * scale, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            infoBox()
            repairCostRow()

            HStack(spacing: 8) {
                Text("Your Coins:")
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(goldenAccent)
                        .font(.system(size: 16 * scale))
                    Text("\(coins)")
                        .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            repairButton()
            triviaButton()

            if !canAffordRepair {
                Text("⚠️ Not enough coins! Earn coins by discovering artifacts, or answer trivia for a free repair.")
                    .font(.system(size: 13 * scale, weight: .medium))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(30 * scale)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red, lineWidth: 3))
        )
        .shadow(color: Color.red.opacity(0.5), radius: 30 * scale, x: 0, y: 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: min(500, screenWidth - 44))
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: 0)
                        cardContent(screenWidth: screenWidth)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

#Preview("RepairModalView") {
    RepairModalView(
        damage: 100,
        coins: 75,
        canAffordRepair: true,
        screenHeight: 900,
        screenWidth: 390,
        onRepair: {},
        onTrivia: {}
    )
}
