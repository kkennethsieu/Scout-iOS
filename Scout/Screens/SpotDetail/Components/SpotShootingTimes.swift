import SwiftUI

/// "Best Shooting Times" — a wrapping row of time-of-day pills. Renders nothing
/// when there are no times.
struct SpotShootingTimes: View {
    let times: [TimeOfDay]

    var body: some View {
        if !times.isEmpty {
            SSection(title: "Best Shooting Times") {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(times, id: \.self) { time in
                        pill(time)
                    }
                }
            }
        }
    }

    private func pill(_ time: TimeOfDay) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: time.icon)
                .font(.system(size: 13))
            Text(time.label)
                .font(.sBody)
        }
        .foregroundStyle(Color.sTextPrimary)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Capsule().fill(Color.sSurface))
        .overlay(Capsule().stroke(Color.sBorderDefault, lineWidth: 1))
    }
}
