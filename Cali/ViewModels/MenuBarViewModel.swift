//
//  MenuBarViewModel.swift
//  cali
//

import AppKit
import Combine
import EventKit
import Foundation

@Observable
final class MenuBarViewModel {

    // MARK: - Public State

    let calendarService = CalendarService()
    let settings = AppSettings()

    var menuBarTitle: String = "Cali"
    var currentDate = Date()
    var selectedDate = Date()
    var activeMeeting: CalendarEvent?

    // MARK: - Computed Properties

    var timedEvents: [CalendarEvent] {
        calendarService.events.filter { !$0.isAllDay }
    }

    var allDayEvents: [CalendarEvent] {
        calendarService.events.filter { $0.isAllDay }
    }

    var nextEvent: CalendarEvent? {
        let now = currentDate
        return timedEvents.first { $0.endDate > now }
    }

    var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var headerDateString: String {
        let cal = Calendar.current
        let formatter = DateFormatter()

        let dayLabel: String
        if cal.isDateInToday(selectedDate) {
            dayLabel = "Today"
        } else if cal.isDateInTomorrow(selectedDate) {
            dayLabel = "Tomorrow"
        } else if cal.isDateInYesterday(selectedDate) {
            dayLabel = "Yesterday"
        } else {
            formatter.dateFormat = "EEEE"
            dayLabel = formatter.string(from: selectedDate)
        }

        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: selectedDate)
        let daysInMonth = cal.range(of: .day, in: .month, for: selectedDate)?.count ?? 30

        return "\(dayLabel) - \(dateStr) of \(daysInMonth)"
    }

    // MARK: - Private

    private var hasStarted = false
    private var refreshTimer: Timer?
    private var countdownTimer: Timer?
    private var eventStoreObserver: Any?
    private var autoJoinedEventIDs: Set<String> = []

    // MARK: - Lifecycle

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let granted = await calendarService.requestAccess()
        if granted {
            fetchEventsForSelectedDate()
            updateActiveMeeting()
            updateMenuBarTitle()
            startTimers()
            observeEventStoreChanges()
        }
    }

    func refresh() {
        fetchEventsForSelectedDate()
        currentDate = Date()
        updateActiveMeeting()
        updateMenuBarTitle()
    }

    // MARK: - Date Navigation

    func navigateDay(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) else {
            return
        }
        selectedDate = newDate
        fetchEventsForSelectedDate()
    }

    func goToToday() {
        selectedDate = Date()
        fetchEventsForSelectedDate()
    }

    // MARK: - Actions

    func joinMeeting(_ event: CalendarEvent) {
        guard let link = event.meetingLink else { return }
        NSWorkspace.shared.open(link)
    }

    func openCalendarSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    func activateApp() {
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Private Methods

    private func fetchEventsForSelectedDate() {
        calendarService.fetchEvents(for: selectedDate, disabledCalendarIDs: settings.disabledCalendarIDs)
    }

    private func updateActiveMeeting() {
        activeMeeting = findActiveMeeting()
    }

    private func updateMenuBarTitle() {
        guard let next = nextUpcomingEvent() else {
            menuBarTitle = "Cali"
            return
        }

        let now = currentDate
        let truncatedTitle = truncateTitle(next.title)

        // Currently in a meeting
        if next.startDate <= now && next.endDate > now {
            if settings.showEventTitle {
                menuBarTitle = "\(truncatedTitle) now"
            } else {
                menuBarTitle = "now"
            }
            return
        }

        // Time until next meeting
        let interval = next.startDate.timeIntervalSince(now)
        let timeStr: String

        if settings.showSeconds && interval < 3600 {
            let mins = Int(interval / 60)
            let secs = Int(interval.truncatingRemainder(dividingBy: 60))
            timeStr = "\(mins)m \(secs)s left"
        } else if interval < 60 {
            timeStr = "<1m left"
        } else if interval < 3600 {
            timeStr = "\(Int(interval / 60))m left"
        } else {
            let hours = Int(interval / 3600)
            let mins = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
            timeStr = mins > 0 ? "\(hours)h \(mins)m left" : "\(hours)h left"
        }

        if settings.showEventTitle {
            menuBarTitle = "\(truncatedTitle) · \(timeStr)"
        } else {
            menuBarTitle = timeStr
        }
    }

    private func truncateTitle(_ title: String) -> String {
        if title.count > settings.maxEventTitleLength {
            return String(title.prefix(settings.maxEventTitleLength)) + "..."
        }
        return title
    }

    /// Finds the currently in-progress meeting with a join link (always from today).
    private func findActiveMeeting() -> CalendarEvent? {
        guard calendarService.authorizationStatus == .fullAccess else { return nil }

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let predicate = calendarService.eventStore.predicateForEvents(
            withStart: startOfToday, end: endOfToday, calendars: nil
        )
        return calendarService.eventStore.events(matching: predicate)
            .map { CalendarEvent(from: $0) }
            .filter { !$0.isAllDay && $0.startDate <= now && $0.endDate > now && $0.meetingLink != nil }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    /// Finds the next upcoming event from TODAY (always today, regardless of selectedDate).
    private func nextUpcomingEvent() -> CalendarEvent? {
        guard calendarService.authorizationStatus == .fullAccess else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let predicate = calendarService.eventStore.predicateForEvents(
            withStart: startOfToday,
            end: endOfToday,
            calendars: nil
        )

        return calendarService.eventStore.events(matching: predicate)
            .map { CalendarEvent(from: $0) }
            .filter { !$0.isAllDay && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    private func startTimers() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
            self?.updateActiveMeeting()
            self?.updateMenuBarTitle()
            self?.checkAutoJoin()
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func observeEventStoreChanges() {
        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: calendarService.eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    private func checkAutoJoin() {
        guard settings.autoJoinEnabled else { return }
        guard let next = nextUpcomingEvent(), let link = next.meetingLink else { return }
        guard !autoJoinedEventIDs.contains(next.id) else { return }

        let now = Date()
        let timeUntilStart = next.startDate.timeIntervalSince(now)

        if timeUntilStart <= 15 && timeUntilStart >= -60 {
            autoJoinedEventIDs.insert(next.id)
            NSWorkspace.shared.open(link)
        }
    }
}
