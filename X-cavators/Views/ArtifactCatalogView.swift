//
//  ArtifactCatalogView.swift
//  X-cavators
//
//  Scrollable catalog of discovered artifacts
//

import SwiftUI

struct ArtifactCatalogView: View {
    let artifacts: [Artifact]

    var discoveredArtifacts: [Artifact] {
        artifacts.filter { $0.isDiscovered }.sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ARTIFACT CATALOG")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()
                .background(Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.5))

            if discoveredArtifacts.isEmpty {
                VStack {
                    Spacer()
                    Text("No artifacts\ndiscovered yet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(discoveredArtifacts) { artifact in
                            ArtifactCatalogRow(artifact: artifact)
                            if artifact.id != discoveredArtifacts.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.95, green: 0.77, blue: 0.06).opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct ArtifactCatalogRow: View {
    let artifact: Artifact

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: artifact.isIdentified ? "star.fill" : "questionmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(artifact.isIdentified ?
                                Color(red: 0.95, green: 0.77, blue: 0.06) :
                                Color.white.opacity(0.4))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if artifact.isDiscovered && !artifact.isIdentified {
                    HStack(spacing: 4) {
                        ForEach(0..<artifact.scansRequired, id: \.self) { index in
                            Circle()
                                .fill(index < artifact.scanCount ?
                                     Color(red: 0.2, green: 0.8, blue: 0.2) :
                                     Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                        Text("Scans")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
