import SwiftUI

/// A single skeleton placeholder block — the building unit for loading skeletons.
/// Fills its width by default; pass `width` for a fixed-width bar (e.g. a title).
struct SkeletonBox: View {
    var height: CGFloat
    var width: CGFloat? = nil
    var cornerRadius: CGFloat = Radius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.sBorderSubtle)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

// MARK: - Shimmer

/// Sweeps a soft highlight across the content to signal loading. Respects Reduce
/// Motion — when set, the content shows as a static placeholder with no animation.
private struct Shimmer: ViewModifier {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content
                .overlay {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [.clear, Color.sSurface.opacity(0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width)
                        // Sweep from fully off the leading edge to off the trailing edge.
                        .offset(x: phase * (width * 2))
                    }
                    .allowsHitTesting(false)
                }
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Sweeps a shimmer highlight across this view while `active` (Reduce-Motion aware).
    func shimmering(_ active: Bool = true) -> some View {
        modifier(Shimmer(active: active))
    }
}

// MARK: - Preview

#Preview("Skeleton Box") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        SkeletonBox(height: 220, cornerRadius: Radius.lg)
        SkeletonBox(height: 24, width: 180)
        SkeletonBox(height: 16, width: 120)
        SkeletonBox(height: 16)
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
    .shimmering()
}
