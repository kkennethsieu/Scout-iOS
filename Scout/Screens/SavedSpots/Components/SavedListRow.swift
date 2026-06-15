import SwiftUI

/// A single saved-list row: a leading 56pt square (photo thumbnail or symbol
/// tile), the list name, and a "N spots" subtitle, with a trailing chevron.
/// Screen-local because `SListRow` supports neither image thumbnails nor a
/// subtitle line. Drop these inside `SListGroup` to inherit hairline dividers.
struct SavedListRow: View {
    /// Trailing accessory: a disclosure chevron (Saved tab) or a multi-select
    /// checkbox (the "Save to a list" sheet).
    enum Accessory {
        case chevron
        case checkbox(Bool)
    }

    let list: SavedList
    var accessory: Accessory = .chevron

    private let side: CGFloat = 56

    var body: some View {
        HStack(spacing: Spacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(list.name)
                    .font(.sHeadingM)
                    .foregroundStyle(Color.sTextPrimary)
                    .lineLimit(1)
                Text(list.spotCountLabel)
                    .font(.sBodyS)
                    .foregroundStyle(Color.sTextSecondary)
            }

            Spacer(minLength: Spacing.sm)

            trailing
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var trailing: some View {
        switch accessory {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.sTextTertiary)
        case .checkbox(let isOn):
            SCheckbox(isOn: isOn)
        }
    }

    /// Icon priority: the app-managed Favorites always shows a heart; otherwise a
    /// cover photo if the list has one, else a generic list glyph.
    @ViewBuilder
    private var thumbnail: some View {
        if list.isSystem {
            symbolTile("heart")
        } else if let url = list.coverPhotoUrl {
            // `Color` base + overlaid AsyncImage + clipped — the codebase's fix
            // for AsyncImage stretching its container to the image's native size.
            Color.sBorderSubtle
                .frame(width: side, height: side)
                .overlay {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.sBorderSubtle
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        } else {
            symbolTile("list.bullet")
        }
    }

    private func symbolTile(_ name: String) -> some View {
        RoundedRectangle(cornerRadius: Radius.md)
            .fill(Color.sBorderSubtle)
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: name)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.sTextPrimary)
            }
    }
}

// MARK: - Preview

#Preview("SavedListRow") {
    SListGroup {
        ForEach(SavedList.samples) { list in
            SavedListRow(list: list)
        }
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.sBackground)
}
