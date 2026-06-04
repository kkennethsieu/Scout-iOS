import SwiftUI

/// "Name Picker" step of the create flow: after a photo/location is placed, the
/// user picks one of the nearby places to name the spot, or names it themselves
/// via the inline field. Either path produces a non-empty, trimmed name through
/// the single `onSelect` callback.
struct NameSpotSheet: View {
    var placeNames: [String] = ["The Emerald Basin", "Bixby Creek Bridge", "Muir Woods"]
    var onSelect: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var isNaming = false
    @State private var customName = ""
    @FocusState private var nameFieldFocused: Bool

    private var trimmedCustomName: String {
        customName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(placeNames, id: \.self) { name in
                        placeRow(name)
                        Divider().background(Color.sBorderSubtle)
                    }
                    nameMyselfRow
                }
                .padding(.horizontal, Spacing.lg)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.xl)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Name this spot")
                .font(.sHeadingL)
                .foregroundStyle(Color.sTextPrimary)

            Text("We found \(placeNames.count) spots near your photo — which one?\nTap a nearby place or add your own")
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Rows

    private func placeRow(_ name: String) -> some View {
        Button {
            commit(name)
        } label: {
            HStack(spacing: Spacing.md) {
                placeIcon
                Text(name)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)
                Spacer(minLength: Spacing.sm)
                chevron
            }
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityAddTraits(.isButton)
    }

    /// Collapsed: a tappable "Name it myself" row. Expanded: an inline text field
    /// + confirm, so a non-empty name is collected before `onSelect` fires.
    @ViewBuilder
    private var nameMyselfRow: some View {
        if isNaming {
            HStack(spacing: Spacing.md) {
                rowGlyph("pencil")

                TextField("Name your spot", text: $customName)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .tint(Color.sAccent)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .onChange(of: customName) { _, newValue in
                        if newValue.count > CreateReviewViewModel.maxNameLength {
                            customName = String(newValue.prefix(CreateReviewViewModel.maxNameLength))
                        }
                    }
                    .onSubmit(confirmCustomName)

                Button(action: confirmCustomName) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(trimmedCustomName.isEmpty ? Color.sTextTertiary : Color.sAccent)
                }
                .buttonStyle(.plain)
                .disabled(trimmedCustomName.isEmpty)
                .accessibilityLabel("Use this name")
            }
            .padding(.vertical, Spacing.md)
        } else {
            Button {
                isNaming = true
                nameFieldFocused = true
            } label: {
                HStack(spacing: Spacing.md) {
                    rowGlyph("plus")
                    Text("Name it myself")
                        .font(.sHeadingM)
                        .foregroundStyle(Color.sTextPrimary)
                    Spacer(minLength: Spacing.sm)
                    chevron
                }
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Name it myself")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Actions

    private func confirmCustomName() {
        let name = trimmedCustomName
        guard !name.isEmpty else { return }
        commit(name)
    }

    private func commit(_ name: String) {
        dismiss()
        onSelect(name)
    }

    // MARK: - Pieces

    /// Nearby places come from MapKit (no photos), so rows use a place glyph
    /// rather than a thumbnail.
    private var placeIcon: some View { rowGlyph("mappin") }

    private func rowGlyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.sAccent)
            .frame(width: 56, height: 56)
            .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.sTextTertiary)
    }
}

// MARK: - Preview

#Preview("Name this spot") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            NameSpotSheet()
        }
}

#Preview("Name this spot — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            NameSpotSheet()
        }
        .preferredColorScheme(.dark)
}
