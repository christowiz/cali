//
//  CalendarService.swift
//  cali
//

import EventKit
import Foundation

@Observable
final class CalendarService {
    private(set) var authorizationStatus: EKAuthorizationStatus
    private(set) var events: [CalendarEvent] = []

    let eventStore = EKEventStore()

    init() {
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        let currentStatus = EKEventStore.authorizationStatus(for: .event)

        switch currentStatus {
        case .fullAccess:
            authorizationStatus = .fullAccess
            return true

        case .notDetermined:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                return granted
            } catch {
                print("[CalendarService] Access request failed: \(error.localizedDescription)")
                return false
            }

        default:
            authorizationStatus = currentStatus
            return false
        }
    }

    // MARK: - Fetching Events

    func fetchEvents(for date: Date, disabledCalendarIDs: Set<String> = []) {
        guard authorizationStatus == .fullAccess else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let enabledCalendars = availableCalendars.filter {
            !disabledCalendarIDs.contains($0.calendarIdentifier)
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: enabledCalendars.isEmpty ? nil : enabledCalendars
        )
        let ekEvents = eventStore.events(matching: predicate)

        events = ekEvents
            .map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Calendars

    var availableCalendars: [EKCalendar] {
        eventStore.calendars(for: .event)
    }

    /// Calendars grouped by their source (iCloud, Google, etc.)
    var calendarsBySource: [(source: String, calendars: [EKCalendar])] {
        let grouped = Dictionary(grouping: availableCalendars) { $0.source.title }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (source: $0.key, calendars: $0.value.sorted { $0.title < $1.title }) }
    }
}
