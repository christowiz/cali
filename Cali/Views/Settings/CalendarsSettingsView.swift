//
//  CalendarsSettingsView.swift
//  cali
//

import EventKit
import SwiftUI

struct CalendarsSettingsView: View {
    let calendarService: CalendarService
    @Bindable var settings: AppSettings
    var onCalendarToggled: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Calendars")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 24)

            if calendarService.calendarsBySource.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(calendarService.calendarsBySource, id: \.source) { group in
                            calendarSourceSection(group.source, calendars: group.calendars)
                        }
                    }
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

    // MARK: - Source Section

    private func calendarSourceSection(_ source: String, calendars: [EKCalendar]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(source)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 4)

            ForEach(calendars, id: \.calendarIdentifier) { calendar in
                calendarRow(calendar)
                Divider()
            }
        }
    }

    private func calendarRow(_ calendar: EKCalendar) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(cgColor: calendar.cgColor))
                .frame(width: 10, height: 10)

            Text(calendar.title)
                .font(.system(size: 13))

            Spacer()

            Toggle("", isOn: Binding(
                get: { settings.isCalendarEnabled(calendar.calendarIdentifier) },
                set: { _ in
                    settings.toggleCalendar(calendar.calendarIdentifier)
                    onCalendarToggled?()
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)

            Text("No calendars found")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text("Make sure calendar access is granted in System Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
