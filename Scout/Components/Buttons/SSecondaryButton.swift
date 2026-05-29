import SwiftUI

struct SSecondaryButton: View {
    // MARK: - Data In
    let title: String
    var icon: String? = nil
    var trailingIcon: String? = nil
    var isLoading: Bool = false
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
                        .tint(Color.sTextPrimary)
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
            .foregroundStyle(Color.sTextPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
        .buttonStyle(SSecondaryButtonStyle())
        .disabled(isLoading)
    }
}

private struct SSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.sSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.sBorderDefault, lineWidth: 1)
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

#Preview("SSecondary Button") {
    VStack(spacing: Spacing.lg) {
        SSecondaryButton(title: "Continue with email") {
            print("tapped")
        }
        
        SSecondaryButton(title: "Pick location on map", icon: "map") {
            print("tapped")
        }
        
        SSecondaryButton(title: "Loading", isLoading: true) {
            print("tapped")
        }
        
        SSecondaryButton(title: "Disabled") {
            print("tapped")
        }
        .disabled(true)
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
