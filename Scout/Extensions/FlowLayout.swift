import SwiftUI

/// A simple wrapping layout: lays children left-to-right, wrapping to the next
/// line when they exceed the available width. Used for chip/pill rows that
/// should flow onto multiple lines (e.g. Best Shooting Times).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        // The width we wrap against. On the real layout pass SwiftUI proposes a
        // finite width; on the ideal-size pass it proposes nil/.infinity. In the
        // latter case, fall back to the widest single item rather than the sum of
        // all items — otherwise we'd report a giant one-row width that blows out
        // the parent layout (content wider than the screen).
        let maxWidth: CGFloat
        if let proposed = proposal.width, proposed > 0, proposed != .infinity {
            maxWidth = proposed
        } else {
            maxWidth = sizes.map(\.width).max() ?? 0
        }

        var currentX: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for size in sizes {
            if currentX + size.width > maxWidth, currentX > 0 {
                totalHeight += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
