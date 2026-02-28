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
    @State private var showShop = false
    @State private var triviaQuestions: [TriviaQuestion] = []
    @State private var triviaSuccessAction: (() -> Void)? = nil

    init(gameMode: GameMode) {
        _viewModel = StateObject(wrappedValue: GameViewModel(gameMode: gameMode))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // World container (scrolls with camera)
                ZStack {
                    MapView()

                    if viewModel.gameMode == .auto {
                        GridOverlayView(
                            waypoints: viewModel.gridWaypoints,
                            currentIndex: viewModel.currentWaypointIndex,
                            roverPosition: viewModel.rover.position
                        )
                    }

                    // Home Base (drawn first, below everything)
                    if let homeBase = viewModel.homeBase {
                        HomeBaseView(
                            homeBase: homeBase,
                            isRoverInRange: homeBase.isRoverInRange(rover: viewModel.rover)
                        )
                    }

                    ForEach(viewModel.hazards) { hazard in
                        HazardView(hazard: hazard)
                    }

                    ForEach(viewModel.artifacts) { artifact in
                        ArtifactView(artifact: artifact)
                    }

                    RoverView(rover: viewModel.rover)
                }
                .frame(width: viewModel.worldSize.width, height: viewModel.worldSize.height)
                .offset(
                    x: viewModel.worldSize.width / 2 - geometry.size.width / 2 - viewModel.cameraOffset.x,
                    y: viewModel.worldSize.height / 2 - geometry.size.height / 2 - viewModel.cameraOffset.y
                )

                VStack {
                    HStack {
                        // Exit button
                        Button(action: {
                            viewModel.stopGame()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }

                        // Battery Indicator (compact, left side)
                        HStack(spacing: 8) {
                            // Battery icon
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 40, height: 20)

                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                    .offset(x: 41)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(viewModel.rover.batteryLevel > 50 ? .green : (viewModel.rover.batteryLevel > 25 ? .yellow : .red))
                                    .frame(width: max(0, 36 * (viewModel.rover.batteryLevel / viewModel.getMaxBattery())), height: 16)
                                    .padding(.leading, 2)

                                if viewModel.homeBase?.isRoverInRange(rover: viewModel.rover) ?? false {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 20)
                                }
                            }

                            Text("\(Int(viewModel.rover.batteryLevel / viewModel.getMaxBattery() * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.5))
                        )

                        // Damage Indicator
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(viewModel.damage >= 100 ? .red : (viewModel.damage >= 70 ? .orange : (viewModel.damage >= 40 ? .yellow : .green)))

                            // Damage bar
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 60, height: 12)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(viewModel.damage >= 100 ? .red : (viewModel.damage >= 70 ? .orange : (viewModel.damage >= 40 ? .yellow : .green)))
                                    .frame(width: CGFloat(viewModel.damage) / 100.0 * 60, height: 12)
                            }

                            Text("\(viewModel.damage)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.damage >= 70 ? Color.red.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )

                        Spacer()

                        HStack(spacing: 12) {
                            // Coin Bank
                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))
                                    Text("\(viewModel.coins)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Text("Coins")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.5))
                            )

                            // Artifact Count
                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))
                                    Text("\(viewModel.artifacts.filter { $0.isDiscovered }.count)/\(viewModel.artifacts.count)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Text("Artifacts")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.5))
                            )
                        }
                        .padding()
                    }

                    // Low Battery Warning
                    if viewModel.rover.batteryLevel < 25 && viewModel.rover.batteryLevel > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text("LOW BATTERY!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                )
                        )
                    }

                    // Dead Battery Warning
                    if viewModel.rover.batteryLevel == 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "battery.0")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text("BATTERY DEPLETED!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        )
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
                            detectionRadius: viewModel.effectiveGPRRadius
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
                            showShop = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("SHOP")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 1.0),
                                        Color(red: 0.15, green: 0.5, blue: 0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.5), radius: 5, x: 0, y: 2)
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

                // Artifact Discovery Modal (over everything)
                if let artifact = viewModel.discoveredArtifactModalData,
                   let fact = viewModel.currentArchaeologyFact {
                    ArtifactDiscoveryModalView(
                        artifact: artifact,
                        fact: fact,
                        onDismiss: {
                            viewModel.discoveredArtifactModalData = nil
                            viewModel.currentArchaeologyFact = nil
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.discoveredArtifactModalData != nil)
                    .zIndex(1000)
                }

                // Shop View (over everything)
                if showShop {
                    ShopView(
                        onDismiss: {
                            showShop = false
                        },
                        currentCoins: viewModel.coins,
                        upgrades: viewModel.upgrades,
                        onPurchase: { upgradeType in
                            viewModel.purchaseUpgrade(upgradeType)
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showShop)
                    .zIndex(2000)
                }

                // Repair Modal (highest priority)
                if viewModel.needsRepair {
                    RepairModalView(
                        damage: viewModel.damage,
                        coins: viewModel.coins,
                        canAffordRepair: viewModel.canAffordRepair,
                        onRepair: {
                            viewModel.repairRover()
                        },
                        onTrivia: {
                            triviaSuccessAction = { viewModel.triviaRepairRover() }
                            triviaQuestions = Array(viewModel.triviaQuestions.shuffled().prefix(2))
                            viewModel.showingTrivia = true
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.needsRepair)
                    .zIndex(3000)
                }

                // Battery Depleted Modal (manual mode only)
                if viewModel.batteryDepleted && !viewModel.showingTrivia {
                    BatteryDepletedModalView(
                        coins: viewModel.coins,
                        canAffordTow: viewModel.coins >= 20,
                        onPayCoins: {
                            viewModel.towRoverCoins()
                        },
                        onTrivia: {
                            triviaSuccessAction = { viewModel.towRoverTrivia() }
                            triviaQuestions = Array(viewModel.triviaQuestions.shuffled().prefix(2))
                            viewModel.showingTrivia = true
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.batteryDepleted)
                    .zIndex(2500)
                }

                // Trivia Modal (above repair/battery modals)
                if viewModel.showingTrivia {
                    TriviaModalView(
                        questions: triviaQuestions,
                        onSuccess: {
                            triviaSuccessAction?()
                            triviaSuccessAction = nil
                        },
                        onDismiss: {
                            triviaQuestions = Array(viewModel.triviaQuestions.shuffled().prefix(2))
                            viewModel.showingTrivia = false
                            triviaSuccessAction = nil
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingTrivia)
                    .zIndex(3500)
                }
            }
            .clipped()
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

//#Preview {
//    GameView(gameMode: .manual)
//}
