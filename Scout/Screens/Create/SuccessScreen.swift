import SwiftUI

/// Confirmation screen shown after a review is submitted: a success badge, a
/// compact preview of the just-created spot, share shortcuts, and the exit CTAs.
///
/// Presentational only — nothing is wired yet. The owner supplies the display
/// values and handles `onSeeSpot` / `onDone` / `onShare`. Once the create
/// endpoint exists this gets fed from the saved `Spot` / `CreateReviewViewModel`.
struct SuccessScreen: View {
    var spotName: String
    /// Human-readable place, e.g. "Altadena, CA".
    var place: String = ""
    /// Best time-of-day label appended after the place, e.g. "golden hour".
    var timeOfDay: String? = nil
    var rating: Int = 5
    var photos: [Data] = []

    var onSeeSpot: () -> Void = {}
    var onDone: () -> Void = {}
    var onShare: (ShareDestination) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.xl) {
                header
                spotCard
                shareSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxxl)
            .padding(.bottom, Spacing.xl)

            bottomBar
        }
        .background(Color.sBackground)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.lg) {
            Circle()
                .fill(Color.sAccent)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.sAccent.opacity(0.3), radius: 12, y: 4)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text("Your spot is live")
                    .font(.sDisplayM)
                    .foregroundStyle(Color.sTextPrimary)

                Text("Other shooters can find it now")
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Spot card

    private var spotCard: some View {
        VStack(spacing: 0) {
            photo
            cardInfo
        }
        .background(Color.sSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    private var photo: some View {
        // Color base + overlaid image + clip so a decoded photo's native size
        // can't stretch the card wider than its container.
        Color.sAccentSoft
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .overlay {
                if let image = photos.first.flatMap(Image.init(data:)) {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.sTextTertiary)
                }
            }
            .clipped()
            .overlay(alignment: .topLeading) {
                SBadge("Just Added")
                    .padding(Spacing.md)
            }
            .overlay(alignment: .bottom) {
                if photos.count > 1 {
                    pageDots
                        .padding(.bottom, Spacing.md)
                }
            }
    }

    private var pageDots: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(photos.indices, id: \.self) { _ in
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var cardInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(spotName)
                    .font(.sHeadingL)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)

                Spacer(minLength: Spacing.sm)

                SStarRating(rating: .constant(rating), size: 14,
                            tint: .sWarning, isInteractive: false)
            }

            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.sTextSecondary)
                Text(subtitle)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
    }

    private var subtitle: String {
        [place, timeOfDay]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(spacing: Spacing.lg) {
            Text("Share your spot")
                .font(.sHeadingS)
                .foregroundStyle(Color.sTextPrimary)

            HStack(alignment: .top, spacing: 0) {
                ForEach(ShareDestination.allCases) { destination in
                    shareButton(destination)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func shareButton(_ destination: ShareDestination) -> some View {
        Button {
            onShare(destination)
        } label: {
            VStack(spacing: Spacing.sm) {
                Image(systemName: destination.icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.sSurface, in: Circle())
                    .overlay {
                        Circle().stroke(Color.sBorderSubtle, lineWidth: 1)
                    }

                Text(destination.label)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(destination.label)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: Spacing.sm) {
            SPrimaryButton(title: "See your spot", action: onSeeSpot)

            Button(action: onDone) {
                Text("Done")
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }
}

// MARK: - Share destinations

/// The share shortcuts shown on the success screen. Targets are stubbed until a
/// share/deep-link layer exists; the screen just reports taps via `onShare`.
nonisolated enum ShareDestination: String, CaseIterable, Identifiable {
    case copyLink, instagram, messages, more

    nonisolated var id: String { rawValue }

    var label: String {
        switch self {
        case .copyLink:  "Copy link"
        case .instagram: "Instagram"
        case .messages:  "Messages"
        case .more:      "More"
        }
    }

    var icon: String {
        switch self {
        case .copyLink:  "link"
        case .instagram: "camera"
        case .messages:  "message"
        case .more:      "ellipsis"
        }
    }
}

// MARK: - Preview

#Preview("Success") {
    SuccessScreen(
        spotName: "Eaton Canyon Falls",
        place: "Altadena, CA",
        timeOfDay: "golden hour",
        rating: 5
    )
}

#Preview("Success — Dark") {
    SuccessScreen(
        spotName: "Eaton Canyon Falls",
        place: "Altadena, CA",
        timeOfDay: "golden hour",
        rating: 5
    )
    .preferredColorScheme(.dark)
}
