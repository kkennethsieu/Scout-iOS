import SwiftUI

/// Single-candidate confirmation: when a photo upload matches one likely spot,
/// confirm it's the same place before jumping into the review flow. The
/// multi-candidate variant is `NearbySpotsSheet`.
///
/// Not wired yet — `spot` defaults to sample data and the actions are stubs.
struct SameSpotSheet: View {
    var spot: NearbySpot = NearbySpot.samples[1]   // Bixby Creek Bridge
    var onConfirm: (NearbySpot) -> Void = { _ in }
    var onDifferentSpot: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: Spacing.lg) {
                photo

                HStack(spacing: Spacing.sm) {
                    Text(spot.name)
                        .font(.sHeadingL)
                        .foregroundStyle(Color.sTextPrimary)
                        .lineLimit(1)

                    STag(text: spot.distance)
                }
            }
            .padding(.horizontal, Spacing.lg)

            actions

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
        .navigationTitle("Same spot?")
    }

    // MARK: - Header

    private var header: some View {
        Text("\(spot.name) nearby — same spot?")
            .font(.sHeadingL)
            .foregroundStyle(Color.sTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.lg)
    }

    // MARK: - Photo

    private var photo: some View {
        // Size from a flexible Color, overlay the image — same pattern as
        // `SpotCard` so a loaded photo can't drive the card wider than its frame.
        Color.sBorderSubtle
            .overlay {
                AsyncImage(url: spot.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var placeholder: some View {
        ZStack {
            Color.sAccentSoft
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.sTextTertiary)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            SPrimaryButton(title: "Yes, review this spot") {
                onConfirm(spot)
            }
            SSecondaryButton(title: "No, this is a different spot") {
                onDifferentSpot()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Same Spot") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            SameSpotSheet()
        }
}

#Preview("Same Spot — Dark") {
    Color.sBackground
        .sheet(isPresented: .constant(true)) {
            SameSpotSheet()
        }
        .preferredColorScheme(.dark)
}
