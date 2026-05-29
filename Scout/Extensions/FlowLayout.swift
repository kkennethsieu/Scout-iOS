import SwiftUI

/// A simple wrapping layout: lays children left-to-right, wrapping to the next
/// line when they exceed the available width. Used for chip/pill rows that
/// should flow onto multiple lines (e.g. Best Shooting Times).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = [[LayoutSubviews.Element]]()
        var currentRow = [LayoutSubviews.Element]()
        var currentX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }
            currentRow.append(subview)
            currentX += size.width + spacing
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        var totalHeight: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            totalHeight += rowHeight + spacing
        }
        totalHeight = max(0, totalHeight - spacing)

        return CGSize(width: maxWidth == .infinity ? currentX : maxWidth,
                      height: totalHeight)
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
