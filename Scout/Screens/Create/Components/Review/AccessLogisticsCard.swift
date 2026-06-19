import SwiftUI

/// Bordered "Access & Logistics" card in the review form: three tristate
/// Yes/No/Unknown logistics rows plus an entrance-fee field and a crowd-level
/// dropdown. The logistics are `Bool?` — `nil` ("Unknown") is a distinct answer
/// from "No", matching the backend's tristate contract.
struct AccessLogisticsCard: View {
    @Binding var permitRequired: Bool?
    @Binding var droneAllowed: Bool?
    @Binding var tripodAllowed: Bool?
    @Binding var entranceFee: String
    @Binding var crowdLevel: String?

    /// Crowd-level vocabulary — must match the backend `CrowdLevel` Literal, since
    /// the selected value is sent verbatim as `crowd_level`.
    nonisolated static let defaultCrowdOptions = ["Empty", "Light", "Moderate", "Crowded"]

    var crowdOptions: [String] = defaultCrowdOptions

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Access & Logistics")
                .font(.sHeadingM)
                .foregroundStyle(Color.sTextPrimary)

            VStack(spacing: Spacing.md) {
                tristateRow("Permit required", value: $permitRequired)
                tristateRow("Drone allowed", value: $droneAllowed)
                tristateRow("Tripod allowed", value: $tripodAllowed)
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

    private func tristateRow(_ title: String, value: Binding<Bool?>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.sBody)
                .foregroundStyle(Color.sTextPrimary)
            SYesNoUnknownPicker(value: value)
        }
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
                .numbersOnly($entranceFee, allowDecimals: true, maxDecimalPlaces: 2)
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
            if crowdLevel != nil {
                Divider()
                Button("Clear", role: .destructive) { crowdLevel = nil }
            }
        } label: {
            HStack {
                Text(crowdLevel ?? "Select")
                    .font(.sBody)
                    .foregroundStyle(crowdLevel == nil ? Color.sTextTertiary : Color.sTextPrimary)
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
        @State private var permit: Bool? = nil
        @State private var drone: Bool? = true
        @State private var tripod: Bool? = false
        @State private var fee = ""
        @State private var crowd: String? = "Moderate"
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
