//
//  LookAroundExplorer.swift
//  Scout
//
//  Created by Kenneth Sieu on 6/18/26.
//

import SwiftUI
import MapKit

/// A reusable Look Around preview card. Hand it an already-resolved
/// `MKLookAroundScene`; tapping opens the system's full-screen Look Around
/// experience (`allowsNavigation`), so there's no custom presentation to manage
/// and it stays cross-platform (no `fullScreenCover`).
///
/// `height` and `cornerRadius` are configurable so it fits anywhere — a detail
/// section, a map callout, the create flow. Fetching the scene from coordinates
/// is the caller's job (see `SpotLookAround`), which keeps this view presentational.
struct LookAroundExplorer: View {
    let scene: MKLookAroundScene
    var height: CGFloat = 200
    var cornerRadius: CGFloat = Radius.lg

    var body: some View {
        LookAroundPreview(
            initialScene: scene,
            allowsNavigation: true,
            badgePosition: .bottomTrailing
        )
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) {
            Label("Tap to explore", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.sCaption)
                .foregroundStyle(Color.sTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(Spacing.sm)
        }
    }
}

// MARK: - Preview

/// Loads a scene for fixed coordinates so the presentational card can be previewed.
private struct LookAroundExplorerPreview: View {
    let latitude: Double
    let longitude: Double
    var height: CGFloat = 200
    @State private var scene: MKLookAroundScene?

    var body: some View {
        Group {
            if let scene {
                LookAroundExplorer(scene: scene, height: height)
            } else {
                ProgressView()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.lg)
        .task {
            let request = MKLookAroundSceneRequest(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
            scene = try? await request.scene
        }
    }
}

#Preview("Santa Monica Pier") {
    LookAroundExplorerPreview(latitude: 34.0094, longitude: -118.4973)
}

#Preview("Griffith Observatory — short") {
    LookAroundExplorerPreview(latitude: 34.1184, longitude: -118.3004, height: 140)
}
