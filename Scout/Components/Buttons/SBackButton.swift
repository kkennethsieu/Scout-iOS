import SwiftUI

struct SBackButton: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.sTextPrimary)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            Spacer()
        }
        .padding(.top, Spacing.sm)
    }
}
