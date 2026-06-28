import SwiftUI

/// "What photographers say" — a backend-generated, review-distilled blurb for a
/// spot, flagged with a subtle `sparkles` cue so it doesn't read as editorial
/// copy. Renders nothing until the summary exists (the backend leaves it `nil`
/// until a spot has ≥3 reviews and generation has run), so it self-hides like
/// the other detail sections (`SpotGearComposition`, `SpotAccessLogistics`).
struct SpotAISummary: View {
    let summary: String?

    private var trimmedSummary: String? {
        guard let summary else { return nil }
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        if let trimmedSummary {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("What photographers say")
                        .font(.sHeadingL)
                        .foregroundStyle(Color.sTextPrimary)
                }
                card(trimmedSummary)
            }
        }
    }

    private func card(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(summary)
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Summarized from reviews")
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("With summary") {
    SpotAISummary(summary: SpotDetail.sample.aiSummary)
        .padding(Spacing.lg)
}

#Preview("Hidden when nil") {
    SpotAISummary(summary: nil)
        .padding(Spacing.lg)
}
