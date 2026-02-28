//
//  ArtifactDiscoveryModalView.swift
//  X-cavators
//
//  Modal dialog displayed when rover discovers an artifact for the first time
//

import SwiftUI

struct ArtifactDiscoveryModalView: View {
    let artifact: Artifact
    let fact: String
    let onDismiss: () -> Void

    private let goldenAccent = Color(red: 0.95, green: 0.77, blue: 0.06)

    var body: some View {
        ZStack {
            // Dimmed background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Modal container
            VStack(spacing: 20) {
                // Close button in top-right
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                }

                // Fun Fact header
                Text("FUN FACT")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(goldenAccent)

                // Archaeology fact
                Text(fact)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)

                // Continue button
                Button(action: onDismiss) {
                    Text("CONTINUE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(goldenAccent)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(goldenAccent, lineWidth: 3)
                    )
            )
            .shadow(color: goldenAccent.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

//#Preview {
//    ArtifactDiscoveryModalView(
//        artifact: Artifact(
//            position: .zero,
//            name: "Ancient Pottery",
//            isDeep: true,
//            scansRequired: 3
//        ),
//        fact: "Archaeology comes from the Greek words \"archia\", meaning \"ancient things\", and \"logos\", meaning \"theory\" or \"science\".",
//        onDismiss: {}
//    )
//}
