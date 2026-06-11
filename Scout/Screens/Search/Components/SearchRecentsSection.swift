import SwiftUI

/// The empty-query state of the SearchScreen: a "Recent Searches" header with a
/// Clear All action and a tappable list of previous terms.
struct SearchRecentsSection: View {
    let recents: [String]
    var onSelect: (String) -> Void = { _ in }
    var onClearAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            VStack(spacing: 0) {
                ForEach(recents.indices, id: \.self) { index in
                    Button {
                        onSelect(recents[index])
                    } label: {
                        row(recents[index])
                    }
                    .buttonStyle(.plain)

                    if index < recents.count - 1 {
                        Divider()
                            .overlay(Color.sBorderSubtle)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Recent Searches")
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)

            Spacer()

            Button("Clear All", action: onClearAll)
                .font(.sBodyS)
                .foregroundStyle(Color.sTextSecondary)
                .buttonStyle(.plain)
        }
    }

    // MARK: - Row

    private func row(_ term: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 17))
                .foregroundStyle(Color.sTextSecondary)
                .frame(width: 24)

            Text(term)
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Recent Searches") {
    SearchRecentsSection(recents: ["Big Sur", "Yosemite Valley", "Joshua Tree"])
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.sBackground)
}
