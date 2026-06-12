import SwiftUI

/// Stacks rows (typically `SListRow`s) in a vertical group with a hairline
/// `sBorderSubtle` divider inserted automatically between each — callers no
/// longer thread dividers by hand. Used for the grouped lists on Settings and
/// future account screens.
///
/// Built on `_VariadicView` so it can read its child views and insert separators
/// only *between* them (never a trailing one).
struct SListGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        _VariadicView.Tree(DividedRows()) {
            content
        }
    }
}

/// Lays the group's children into a `spacing: 0` stack, dropping a divider after
/// every child except the last.
private struct DividedRows: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let lastID = children.last?.id
        VStack(spacing: 0) {
            ForEach(children) { child in
                child
                if child.id != lastID {
                    Divider().background(Color.sBorderSubtle)
                }
            }
        }
    }
}
