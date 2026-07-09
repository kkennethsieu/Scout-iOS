import SwiftUI

/// The LOCATION block at the top of the review form: a caption label, the spot
/// name, and an optional "Change location" button that pops back to the map step
/// (review state is preserved by the flow). Editing an existing review omits the
/// button — the spot is fixed — by leaving `onChangeLocation` nil.
struct ReviewLocationHeader: View {
    let spotName: String
    var onChangeLocation: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("LOCATION")
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)

            Text(spotName)
                .font(.sDisplayM)
                .foregroundStyle(Color.sTextPrimary)

            if let onChangeLocation {
                Button(action: onChangeLocation) {
                    Text("Change location")
                        .font(.sBody)
                        .foregroundStyle(Color.sAccent)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Review Location Header") {
    ReviewLocationHeader(spotName: "The Emerald Basin") {}
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sBackground)
}
