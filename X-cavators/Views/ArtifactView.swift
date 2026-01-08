//
//  ArtifactView.swift
//  X-cavators
//
//  Visual representation of discovered artifacts
//

import SwiftUI

struct ArtifactView: View {
    let artifact: Artifact

    var body: some View {
        if artifact.isDiscovered {
            ZStack {
                Circle()
                    .stroke(
                        artifact.isIdentified ?
                        Color(red: 0.95, green: 0.77, blue: 0.06) :
                        Color.white.opacity(0.6),
                        lineWidth: 3
                    )
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(
                        artifact.isIdentified ?
                        Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.3) :
                        Color.white.opacity(0.2)
                    )
                    .frame(width: 30, height: 30)

                Image(systemName: artifact.isIdentified ? "sparkles" : "questionmark")
                    .foregroundColor(
                        artifact.isIdentified ?
                        Color(red: 0.95, green: 0.77, blue: 0.06) :
                        Color.white.opacity(0.7)
                    )
                    .font(.system(size: 16, weight: .bold))
            }
            .shadow(
                color: artifact.isIdentified ?
                Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.5) :
                Color.white.opacity(0.3),
                radius: 8
            )
            .position(artifact.position)
        }
    }
}
