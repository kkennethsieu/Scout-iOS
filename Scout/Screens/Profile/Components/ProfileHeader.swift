import SwiftUI

/// The top of the Profile screen: avatar, name, location, and the single
/// "Reviews" stat (`reviewCount` from the backend). While the profile is still
/// loading (`nil`), it renders redacted placeholders.
struct ProfileHeader: View {
    let profile: UserProfile?

    private var isLoading: Bool { profile == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SAvatar(url: profile?.photoUrl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(profile?.displayName ?? "Marcus Chen")
                    .font(.sDisplayM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                if let profile {
                    let parts = [profile.homeCity, profile.homeCountry]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }

                    if !parts.isEmpty {
                        Text(parts.joined(separator: ", "))
                            .font(.sBody)
                            .foregroundStyle(Color.sTextSecondary)
                            .lineLimit(1)
                    }
                } else if isLoading {
                    Text("San Francisco, USA")
                        .font(.sBody)
                        .foregroundStyle(Color.sTextSecondary)
                        .lineLimit(1)
                }
            }

            stat(value: profile.map { "\($0.reviewCount)" } ?? "—", label: "Reviews")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: isLoading ? .placeholder : [])
    }

    // MARK: - Stat

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(value)
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)
            Text(label)
                .font(.sCaption)
                .foregroundStyle(Color.sTextSecondary)
                .textCase(.uppercase)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("Profile Header") {
    VStack(spacing: Spacing.xl) {
        ProfileHeader(profile: .sample)
        ProfileHeader(profile: nil)   // loading / redacted
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
}
