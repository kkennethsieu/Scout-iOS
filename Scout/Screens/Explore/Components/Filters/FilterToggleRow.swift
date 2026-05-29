import SwiftUI

/// A labeled on/off row with a leading icon, for the boolean logistics filters
/// in the Explore filter sheet. Local to Explore — promote to a shared
/// `SToggleRow` if a second screen needs it.
struct FilterToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sTextSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextPrimary)
            }
        }
        .tint(Color.sAccent)
        .padding(.vertical, Spacing.xs)
    }
}
