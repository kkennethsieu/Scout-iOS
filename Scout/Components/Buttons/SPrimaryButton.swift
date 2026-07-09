import SwiftUI

struct SPrimaryButton: View {
    // MARK: - Data In
    let title: String
    var icon: String? = nil
    var trailingIcon: String? = nil
    var isLoading: Bool = false
    /// Fill color — defaults to the brand accent; pass `.sError` for a destructive
    /// action (e.g. a "Discard changes" confirmation).
    var tint: Color = .sAccent
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                    if let trailingIcon {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .font(.sHeadingS)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(SPrimaryButtonStyle(tint: tint))
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
    }
}

private struct SPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .sAccent
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(tint)
            )
            .opacity(opacity(for: configuration))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
    
    private func opacity(for configuration: Configuration) -> Double {
        if !isEnabled { return 0.4 }
        if configuration.isPressed { return 0.85 }
        return 1.0
    }
}

// MARK: - Previews

#Preview("SPrimary Button") {
    VStack(spacing: Spacing.lg) {
        SPrimaryButton(title: "Continue") {
            print("tapped")
        }
        
        SPrimaryButton(title: "Continue with email", icon: "envelope") {
            print("tapped")
        }
        
        SPrimaryButton(title: "Submitting...", isLoading: true) {
            print("tapped")
        }
        
        SPrimaryButton(title: "Disabled") {
            print("tapped")
        }
        .disabled(true)
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
