import SwiftUI

/// A square multi-select checkbox: checked fills with `sAccent` + a white
/// checkmark, unchecked is a bordered square. Display-only — the enclosing row
/// owns the tap (e.g. the "Save to a list" sheet).
struct SCheckbox: View {
    let isOn: Bool
    var size: CGFloat = 26

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.sm)
            .fill(isOn ? Color.sAccent : Color.clear)
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(isOn ? Color.sAccent : Color.sBorderDefault, lineWidth: 1.5)
            }
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .animation(.easeOut(duration: 0.12), value: isOn)
    }
}

// MARK: - Preview

#Preview("SCheckbox") {
    HStack(spacing: Spacing.lg) {
        SCheckbox(isOn: false)
        SCheckbox(isOn: true)
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.sBackground)
}
