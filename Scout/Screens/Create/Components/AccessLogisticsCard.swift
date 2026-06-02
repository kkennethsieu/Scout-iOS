import SwiftUI

/// Bordered "Access & Logistics" card in the review form: three boolean toggles
/// plus an entrance-fee field and a crowd-level dropdown. Plain `Toggle`s are
/// used (no leading icons) to match the mockup — unlike Explore's
/// `FilterToggleRow`.
struct AccessLogisticsCard: View {
    @Binding var permitRequired: Bool
    @Binding var droneAllowed: Bool
    @Binding var tripodAllowed: Bool
    @Binding var entranceFee: String
    @Binding var crowdLevel: String

    var crowdOptions: [String] = ["Low", "Moderate", "High"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Access & Logistics")
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)

            VStack(spacing: Spacing.md) {
                toggleRow("Permit required", isOn: $permitRequired)
                toggleRow("Drone allowed", isOn: $droneAllowed)
                toggleRow("Tripod allowed", isOn: $tripodAllowed)
            }

            HStack(alignment: .top, spacing: Spacing.md) {
                fieldColumn("ENTRANCE FEE") { entranceFeeField }
                fieldColumn("CROWD LEVEL") { crowdMenu }
            }
        }
        .padding(Spacing.lg)
        .background(Color.sSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.sBorderDefault, lineWidth: 1)
        )
    }

    // MARK: - Rows

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
        }
        .tint(Color.sAccent)
    }

    private func fieldColumn<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.sCaption)
                .foregroundStyle(Color.sTextTertiary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var entranceFeeField: some View {
        HStack(spacing: Spacing.xs) {
            Text("$")
                .font(.sBody)
                .foregroundStyle(Color.sTextSecondary)
            TextField("0.00", text: $entranceFee)
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
                .tint(Color.sAccent)
                .keyboardType(.decimalPad)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
        .background(Color.sBackground, in: RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.sBorderDefault, lineWidth: 1)
        )
    }

    private var crowdMenu: some View {
        Menu {
            ForEach(crowdOptions, id: \.self) { option in
                Button(option) { crowdLevel = option }
            }
        } label: {
            HStack {
                Text(crowdLevel)
                    .font(.sBody)
                    .foregroundStyle(Color.sTextPrimary)
                Spacer(minLength: Spacing.sm)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.sTextTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 44)
            .background(Color.sBackground, in: RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.sBorderDefault, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Access & Logistics") {
    struct Demo: View {
        @State private var permit = false
        @State private var drone = true
        @State private var tripod = true
        @State private var fee = ""
        @State private var crowd = "Moderate"
        var body: some View {
            AccessLogisticsCard(
                permitRequired: $permit,
                droneAllowed: $drone,
                tripodAllowed: $tripod,
                entranceFee: $fee,
                crowdLevel: $crowd
            )
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    return Demo()
}
