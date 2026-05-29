import SwiftUI

struct SSheetHeader: View {
    let title: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(title)
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)

            HStack {
                Spacer()

                Button { onDismiss?() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.sTextSecondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.sSurface))
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
        .overlay(alignment: .bottom) {
            Divider().background(Color.sBorderSubtle)
        }
    }
}
