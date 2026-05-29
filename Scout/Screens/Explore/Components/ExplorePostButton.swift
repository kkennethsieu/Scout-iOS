import SwiftUI

/// Floating "+" action button (FAB) to start a new post/review.
struct ExplorePostButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.sAccent, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
