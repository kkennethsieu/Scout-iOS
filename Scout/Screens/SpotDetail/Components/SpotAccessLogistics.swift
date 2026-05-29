import SwiftUI

/// "Access & Logistics" — permit / drone / tripod rows with a yes/no/unknown
/// indicator. Renders nothing when all three values are unknown.
struct SpotAccessLogistics: View {
    let permitRequired: Bool?
    let droneAllowed: Bool?
    let tripodAllowed: Bool?

    private var hasAny: Bool {
        permitRequired != nil || droneAllowed != nil || tripodAllowed != nil
    }

    var body: some View {
        if hasAny {
            SpotDetailSection(title: "Access & Logistics") {
                VStack(spacing: Spacing.sm) {
                    row(icon: "doc.text", label: "Permit Required", value: permitRequired)
                    row(icon: "airplane", label: "Drone Allowed", value: droneAllowed)
                    row(icon: "camera", label: "Tripod Allowed", value: tripodAllowed)
                }
            }
        }
    }

    private func row(icon: String, label: String, value: Bool?) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.sTextPrimary)
                .frame(width: 24)
            Text(label)
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
            Spacer()
            Image(systemName: symbol(value))
                .font(.system(size: 20))
                .foregroundStyle(color(value))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.sBorderSubtle, lineWidth: 1)
        )
    }

    private func symbol(_ value: Bool?) -> String {
        switch value {
        case .some(true): return "checkmark.circle"
        case .some(false): return "nosign"
        case .none: return "questionmark.circle"
        }
    }

    private func color(_ value: Bool?) -> Color {
        switch value {
        case .some(true): return Color.sSuccess
        case .some(false): return Color.sError
        case .none: return Color.sTextSecondary
        }
    }
}
