//
//  ContentView.swift
//  X-cavators
//
//  Created by Scott Lee on 12/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showModeSelection = false
    @State private var selectedMode: GameMode? = nil
    @State private var showGame = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .border(Color.white, width: 4)
                    .shadow(radius: 10)

                Text("X-CAVATORS")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.83, green: 0.71, blue: 0.55))
                    .shadow(radius: 5)

                Button(action: {
                    showModeSelection = true
                }) {
                    Text("START EXPEDITION")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.77, blue: 0.06),
                                    Color(red: 0.85, green: 0.65, blue: 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showModeSelection) {
            ModeSelectionView(selectedMode: $selectedMode)
        }
        .onChange(of: selectedMode) { _, newMode in
            if newMode != nil {
                showGame = true
            }
        }
        .fullScreenCover(isPresented: $showGame, onDismiss: {
            selectedMode = nil
        }) {
            if let mode = selectedMode {
                GameView(gameMode: mode)
            }
        }
    }
}

#Preview {
    ContentView()
}
