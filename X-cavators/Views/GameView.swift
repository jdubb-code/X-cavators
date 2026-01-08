//
//  GameView.swift
//  X-cavators
//
//  Main game view container
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    init(gameMode: GameMode) {
        _viewModel = StateObject(wrappedValue: GameViewModel(gameMode: gameMode))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MapView()

                if viewModel.gameMode == .auto {
                    GridOverlayView(
                        waypoints: viewModel.gridWaypoints,
                        currentIndex: viewModel.currentWaypointIndex,
                        roverPosition: viewModel.rover.position
                    )
                }

                ForEach(viewModel.hazards) { hazard in
                    HazardView(hazard: hazard)
                }

                ForEach(viewModel.artifacts) { artifact in
                    ArtifactView(artifact: artifact)
                }

                RoverView(rover: viewModel.rover)

                VStack {
                    HStack {
                        Button(action: {
                            viewModel.stopGame()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                        Spacer()

                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))
                                Text("\(viewModel.artifacts.filter { $0.isDiscovered }.count)/\(viewModel.artifacts.count)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text("Artifact Count")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding()
                    }
                    Spacer()
                }

                VStack {
                    HStack {
                        Spacer()
                        GPRDisplayView(
                            rover: viewModel.rover,
                            artifacts: viewModel.artifacts,
                            hazards: viewModel.hazards,
                            detectionRadius: viewModel.gprDetectionRadius
                        )
                        .padding(.top, 80)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }

                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        ArtifactCatalogView(artifacts: viewModel.artifacts)
                            .frame(maxHeight: geometry.size.height * 0.6)
                            .padding(.trailing, 16)
                    }

                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.toggleGameMode()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.gameMode == .auto ? "gamecontroller.fill" : "grid")
                                    .font(.system(size: 16, weight: .bold))
                                Text(viewModel.gameMode == .auto ? "MANUAL" : "AUTO")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        viewModel.gameMode == .auto ? Color(red: 0.95, green: 0.77, blue: 0.06) : Color(red: 0.2, green: 0.8, blue: 0.2),
                                        viewModel.gameMode == .auto ? Color(red: 0.85, green: 0.65, blue: 0.05) : Color(red: 0.15, green: 0.7, blue: 0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: (viewModel.gameMode == .auto ? Color(red: 0.95, green: 0.77, blue: 0.06) : Color(red: 0.2, green: 0.8, blue: 0.2)).opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                    }

                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.resetGame()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .bold))
                                Text("RESET")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
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
                            .cornerRadius(10)
                            .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 220)

                if viewModel.gameMode == .manual {
                    VStack {
                        Spacer()
                        HStack {
                            JoystickView(output: $viewModel.joystickInput)
                                .padding(30)
                            Spacer()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.startGame(size: geometry.size)
            }
            .onDisappear {
                viewModel.stopGame()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GameView(gameMode: .manual)
}
