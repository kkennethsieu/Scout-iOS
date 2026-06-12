import SwiftUI

/// Edit Profile: a pushed sub-screen of the Profile tab for editing personal
/// info, location, and the profile picture. Currently UI-only with hardcoded
/// fake data — "Save" just dismisses; nothing is persisted or uploaded.
struct EditProfileScreen: View {
    @Environment(\.dismiss) private var dismiss

    // Seeded fake data (no backend wiring yet).
    @State private var firstName = "Kenneth"
    @State private var lastName = "Sieu"
    @State private var email = "kkennethsieu@gmail.com"
    @State private var city = "Arcadia, California"

    var body: some View {
        VStack(spacing: 0) {
            SNavHeader(
                title: "Edit profile",
                trailingTitle: "Save",
                trailingAction: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    EditableAvatar()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.sm)

                    personalInformation
                    location
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.sBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var personalInformation: some View {
        SSection(title: "Personal information") {
            VStack(spacing: Spacing.lg) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    STextField(label: "First name", text: $firstName)
                    STextField(label: "Last name", text: $lastName)
                }

                STextField(
                    label: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
            }
        }
    }

    private var location: some View {
        SSection(title: "Location") {
            STextField(label: "City", text: $city)
        }
    }
}

// MARK: - Preview

#Preview("Edit Profile") {
    EditProfileScreen()
}

#Preview("Edit Profile — Dark") {
    EditProfileScreen()
        .preferredColorScheme(.dark)
}
