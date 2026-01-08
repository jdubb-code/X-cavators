//
//  ModeSelectionView.swift
//  X-cavators
//
//  Mode selection screen for choosing game mode
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: GameMode?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 40) {
                Text("SELECT MODE")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.83, green: 0.71, blue: 0.55))
                    .shadow(radius: 5)

                VStack(spacing: 20) {
                    Button {
                        selectedMode = .manual
                        dismiss()
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))

                            Text("GAME MODE")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Manual control with joystick")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: 280, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.95, green: 0.77, blue: 0.06), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.3), radius: 10)
                    }

                    Button {
                        selectedMode = .auto
                        dismiss()
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "grid")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.2))

                            Text("AUTO MODE")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Autonomous grid scan")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: 280, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.2, green: 0.8, blue: 0.2), lineWidth: 3)
                                )
                        )
                        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.3), radius: 10)
                    }
                }
            }
        }
    }
}
