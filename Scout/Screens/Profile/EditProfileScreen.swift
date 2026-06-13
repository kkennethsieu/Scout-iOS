import SwiftUI

/// Edit Profile: a pushed sub-screen of the Profile tab for editing the display
/// name, home location, and profile picture. Seeded from the current `UserProfile`;
/// "Save" persists the changes via `EditProfileViewModel` and dismisses. Email is
/// read-only (owned by Firebase Auth).
struct EditProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProfileViewModel

    init(profile: UserProfile, onSaved: @escaping (UserProfile) -> Void) {
        _viewModel = State(initialValue: EditProfileViewModel(profile: profile, onSaved: onSaved))
    }

    var body: some View {
        VStack(spacing: 0) {
            SNavHeader(
                title: "Edit profile",
                trailingTitle: "Save",
                trailingAction: { save() },
                trailingDisabled: viewModel.isSaving
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    EditableAvatar(
                        image: viewModel.avatarPreview,
                        url: viewModel.currentPhotoURL,
                        onPick: { viewModel.pickedPhoto($0) }
                    )
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
        .alert(
            "Couldn't save profile",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.dismissSaveError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.saveError ?? "")
        }
        .overlay { savingOverlay }
    }

    // MARK: - Actions

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }

    // MARK: - Sections

    private var personalInformation: some View {
        SSection(title: "Personal information") {
            VStack(spacing: Spacing.lg) {
                STextField(label: "Display name", text: $viewModel.displayName)

                STextField(
                    label: "Email",
                    text: .constant(viewModel.email),
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
                .disabled(true)
                .opacity(0.6)
            }
        }
    }

    private var location: some View {
        SSection(title: "Location") {
            VStack(spacing: Spacing.lg) {
                STextField(label: "Home city", text: $viewModel.homeCity)
                STextField(label: "Home country", text: $viewModel.homeCountry)
            }
        }
    }

    // MARK: - Saving overlay

    @ViewBuilder
    private var savingOverlay: some View {
        if viewModel.isSaving {
            ZStack {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView("Saving…")
                    .tint(Color.sAccent)
                    .padding(Spacing.xl)
                    .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
            }
        }
    }
}

// MARK: - Preview

#Preview("Edit Profile") {
    EditProfileScreen(profile: .sample, onSaved: { _ in })
}
