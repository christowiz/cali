//
//  CalendarSettingsView.swift
//  cali
//

import SwiftUI

struct CalendarSettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Calendar")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 24)

            // Earliest Visible Hour
            VStack(alignment: .leading, spacing: 8) {
                Text("Earliest Visible Hour")
                    .font(.system(size: 13, weight: .semibold))

                Text("Slider determines hours to show in the calendar.\nValue is in 24 hour format, eg: 0 = 12am and 17 = 5pm")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Slider(
                        value: $settings.earliestVisibleHour,
                        in: 0...Double(max(Int(settings.latestVisibleHour) - 1, 1)),
                        step: 1
                    )

                    Text("\(Int(settings.earliestVisibleHour))")
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.controlBackgroundColor))
                        )
                }

                HStack {
                    Text("0")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(max(Int(settings.latestVisibleHour) - 1, 1))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.bottom, 28)

            // Latest Visible Hour
            VStack(alignment: .leading, spacing: 8) {
                Text("Latest Visible Hour")
                    .font(.system(size: 13, weight: .semibold))

                Text("Determines hours to show in the calendar.\nValue is in 24 hour format, eg: 0 = 12am and 17 = 5pm")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Slider(
                        value: $settings.latestVisibleHour,
                        in: Double(Int(settings.earliestVisibleHour) + 1)...23,
                        step: 1
                    )

                    Text("\(Int(settings.latestVisibleHour))")
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.controlBackgroundColor))
                        )
                }

                HStack {
                    Text("\(Int(settings.earliestVisibleHour) + 1)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("23")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Text("version 1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
    }
}
