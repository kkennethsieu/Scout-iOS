import SwiftUI

/// A styled, on-brand modal confirmation — the reusable alternative to the system
/// `.alert` when a prompt needs two **vertically stacked** actions (primary on top,
/// secondary below). Title + message are centered; the buttons reuse
/// `SPrimaryButton` / `SSecondaryButton` so they match the rest of the app.
///
/// Present it with the `.sConfirmationDialog(item:dialog:)` modifier, which adds
/// the dimmed, tap-to-dismiss backdrop and the show/hide animation — callers just
/// describe the dialog.
struct SConfirmationDialog: View {
    let title: String
    let message: String
    let primaryTitle: String
    /// Spins the primary button while its action is in flight (e.g. a network call
    /// kicked off from the dialog itself).
    var isPrimaryLoading: Bool = false
    /// Renders the primary button red — for a destructive confirm (e.g. "Discard
    /// changes").
    var isDestructive: Bool = false
    let primaryAction: () -> Void
    var secondaryTitle: String = "Cancel"
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.sBodyL)
                    .foregroundStyle(Color.sTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.sm) {
                SPrimaryButton(title: primaryTitle, isLoading: isPrimaryLoading,
                               tint: isDestructive ? .sError : .sAccent, action: primaryAction)
                SSecondaryButton(title: secondaryTitle, action: secondaryAction)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 360)
        .background(RoundedRectangle(cornerRadius: Radius.xl).fill(Color.sSurface))
        .shadow(color: .black.opacity(0.18), radius: 28, y: 10)
    }
}

extension View {
    /// Presents a centered `SConfirmationDialog` over this view, dimming and
    /// blocking the backdrop (tap outside to dismiss). Bind `item` to an optional
    /// value describing the active prompt; the `dialog` builder maps it to a
    /// dialog. Set `item` to `nil` to dismiss.
    /// Bool-driven convenience for a single fixed dialog (e.g. a discard-changes
    /// confirmation). Delegates to the item-driven overlay.
    func sConfirmationDialog<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder dialog: @escaping () -> Content
    ) -> some View {
        sConfirmationDialog(
            item: Binding(get: { isPresented.wrappedValue ? true : nil },
                          set: { isPresented.wrappedValue = ($0 != nil) })
        ) { (_: Bool) in dialog() }
    }

    func sConfirmationDialog<Item, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder dialog: @escaping (Item) -> Content
    ) -> some View {
        overlay {
            ZStack {
                if let value = item.wrappedValue {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { item.wrappedValue = nil }

                    dialog(value)
                        .padding(.horizontal, Spacing.xl)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.28), value: item.wrappedValue == nil)
        }
    }
}

// MARK: - Preview

#Preview("Confirmation Dialog") {
    struct Demo: View {
        @State private var shown: String? = "x"
        var body: some View {
            Color.sBackground
                .sConfirmationDialog(item: $shown) { _ in
                    SConfirmationDialog(
                        title: "You've already reviewed this spot",
                        message: "Would you like to replace your existing review with this one?",
                        primaryTitle: "Update Review",
                        primaryAction: { shown = nil },
                        secondaryAction: { shown = nil }
                    )
                }
        }
    }
    return Demo()
}
