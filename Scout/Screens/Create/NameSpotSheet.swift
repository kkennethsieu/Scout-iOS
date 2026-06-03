import SwiftUI

/// "Name Picker" step of the create flow: after a photo/location is placed, the
/// user picks one of the nearby places to name the spot, or names it themselves.
///
/// Not wired yet — defaults to sample places and the actions are stubs.
struct NameSpotSheet: View {
    var placeNames: [String] = ["The Emerald Basin", "Bixby Creek Bridge", "Muir Woods"]
    var onSelect: (String) -> Void = { _ in }
    var onNameMyself: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

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
            dismiss()
            onSelect(name)
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

    private var nameMyselfRow: some View {
        Button {
            dismiss()
            onNameMyself()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 56, height: 56)
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

    // MARK: - Pieces

    /// Nearby places come from MapKit (no photos), so rows use a place glyph
    /// rather than a thumbnail.
    private var placeIcon: some View {
        Image(systemName: "mappin")
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
