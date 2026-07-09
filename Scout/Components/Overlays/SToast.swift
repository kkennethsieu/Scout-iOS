import SwiftUI

/// A brief, auto-dismissing confirmation pill — the reusable "it worked" feedback
/// (e.g. "Review updated"). An icon + message on an elevated surface. Present it
/// with the `.sToast(message:)` modifier, which owns the top placement, the
/// slide/fade animation, the auto-dismiss timer, and the success haptic — callers
/// just bind an optional message string.
struct SToast: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var tint: Color = .sSuccess

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)

            Text(message)
                .font(.sHeadingS)
                .foregroundStyle(Color.sTextPrimary)
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
        .background(
            Capsule().fill(Color.sSurfaceElevated)
        )
        .overlay(
            Capsule().stroke(Color.sBorderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }
}

extension View {
    /// Presents a top-anchored `SToast` over this view while `message` is non-nil,
    /// then clears it after `duration` (and plays a success haptic on show). Bind
    /// an optional string; set it to show, it self-clears. Reusable across flows.
    func sToast(message: Binding<String?>, duration: Duration = .seconds(2)) -> some View {
        overlay(alignment: .top) {
            if let text = message.wrappedValue {
                SToast(message: text)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: text) {
                        try? await Task.sleep(for: duration)
                        withAnimation { message.wrappedValue = nil }
                    }
            }
        }
        .animation(.spring(duration: 0.3), value: message.wrappedValue)
        .sensoryFeedback(trigger: message.wrappedValue) { _, new in
            new != nil ? .success : nil
        }
    }
}

// MARK: - Preview

#Preview("Toast") {
    struct Demo: View {
        @State private var message: String? = "Review updated"
        var body: some View {
            Color.sBackground
                .sToast(message: $message)
                .overlay(alignment: .bottom) {
                    Button("Show again") { message = "Review updated" }
                        .padding()
                }
        }
    }
    return Demo()
}
