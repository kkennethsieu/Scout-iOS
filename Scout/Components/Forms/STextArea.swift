import SwiftUI

/// A filled, rounded multiline text input with a placeholder. Grows with its
/// content from `minHeight`. Use this where a soft "box" field is wanted
/// (review notes, hints); for the underline-style single-line inputs (auth),
/// use `STextField`.
struct STextArea: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 56

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(.sBody)
            .foregroundStyle(Color.sTextPrimary)
            .tint(Color.sAccent)
            .focused($isFocused)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isFocused ? Color.sAccent : Color.sBorderDefault,
                            lineWidth: isFocused ? 1.5 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
    }
}

// MARK: - Preview

#Preview("STextArea") {
    struct Demo: View {
        @State private var notes = ""
        @State private var hint = "Best from the north ridge"
        var body: some View {
            VStack(spacing: Spacing.lg) {
                STextArea(text: $notes,
                          placeholder: "Share your experience…",
                          minHeight: 140)
                STextArea(text: $hint,
                          placeholder: "e.g., Best from low angle near the rocks")
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Demo()
}
