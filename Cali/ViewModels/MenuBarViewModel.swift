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

    var menuBarTitle: String = ""
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
    private var titleTimer: Timer?       // 1-second: menu bar title + auto-join
    private var clockTimer: Timer?       // 10-second: time indicator + event cache
    private var refreshTimer: Timer?     // 5-minute: full calendar refresh
    private var eventStoreObserver: Any?
    private var autoJoinedEventIDs: Set<String> = []

    /// Cached today events so the 1-second title timer doesn't query EventKit each tick.
    private var cachedTodayEvents: [CalendarEvent] = []

    // MARK: - Initialization

    init() {
        Task { @MainActor [weak self] in
            await self?.start()
        }
    }

    // MARK: - Lifecycle

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let granted = await calendarService.requestAccess()
        guard granted else { return }

        await MainActor.run {
            refreshTodayEventsCache()
            fetchEventsForSelectedDate()
            updateActiveMeeting()
            updateMenuBarTitle()
            startTimers()
            observeEventStoreChanges()
        }
    }

    func refresh() {
        refreshTodayEventsCache()
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

    // MARK: - Private — Event Cache

    /// Queries EventKit for today's timed events (respecting disabled calendars) and caches them.
    private func refreshTodayEventsCache() {
        guard calendarService.authorizationStatus == .fullAccess else {
            cachedTodayEvents = []
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let enabledCalendars = calendarService.availableCalendars.filter {
            !settings.disabledCalendarIDs.contains($0.calendarIdentifier)
        }

        let predicate = calendarService.eventStore.predicateForEvents(
            withStart: startOfToday,
            end: endOfToday,
            calendars: enabledCalendars.isEmpty ? nil : enabledCalendars
        )

        cachedTodayEvents = calendarService.eventStore.events(matching: predicate)
            .map { CalendarEvent(from: $0) }
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Private — Event Queries (use cache)

    /// Currently active events, sorted by start time.
    private func activeEvents() -> [CalendarEvent] {
        let now = Date()
        return cachedTodayEvents
            .filter { $0.startDate <= now && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Future events that haven't started yet, sorted by start time.
    private func upcomingEvents() -> [CalendarEvent] {
        let now = Date()
        return cachedTodayEvents
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Events from a list that start at the same minute as the given date.
    private func eventsStartingAtSameTime(as date: Date, in events: [CalendarEvent]) -> [CalendarEvent] {
        let cal = Calendar.current
        let targetMinute = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return events.filter {
            cal.dateComponents([.year, .month, .day, .hour, .minute], from: $0.startDate) == targetMinute
        }
    }

    // MARK: - Private — Menu Bar Title

    private func updateMenuBarTitle() {
        let now = Date()
        let active = activeEvents()
        let upcoming = upcomingEvents()

        // ── HIGHEST PRIORITY: event starting in < 1 minute → second-by-second countdown ──
        if let next = upcoming.first {
            let secondsUntil = Int(next.startDate.timeIntervalSince(now))
            if secondsUntil >= 0 && secondsUntil < 60 {
                let sameStart = eventsStartingAtSameTime(as: next.startDate, in: upcoming)
                if sameStart.count > 1 {
                    menuBarTitle = "\(sameStart.count) events in \(secondsUntil)s"
                } else {
                    menuBarTitle = "\(truncateTitle(next.title)) in \(secondsUntil)s"
                }
                return
            }
        }

        // ── HIGH PRIORITY: event starting in < 2 minutes → show name / count ──
        if let next = upcoming.first {
            let secsUntil = next.startDate.timeIntervalSince(now)
            if secsUntil < 120 {
                let sameStart = eventsStartingAtSameTime(as: next.startDate, in: upcoming)
                let timeStr = formatTimeInterval(secsUntil)
                if sameStart.count > 1 {
                    menuBarTitle = "\(sameStart.count) events in \(timeStr)"
                } else {
                    menuBarTitle = "\(truncateTitle(next.title)) · in \(timeStr)"
                }
                return
            }
        }

        // ── CURRENT: events in progress ──
        if !active.isEmpty {
            if active.count == 1 {
                let remaining = active[0].endDate.timeIntervalSince(now)
                let timeStr = formatTimeInterval(remaining)
                let title = truncateTitle(active[0].title)
                menuBarTitle = "\(title) · \(timeStr) left"
            } else {
                menuBarTitle = "\(active.count) events now"
            }
            return
        }

        // ── UPCOMING: events more than 2 min away ──
        if let next = upcoming.first {
            let timeStr = formatTimeInterval(next.startDate.timeIntervalSince(now))
            let sameStart = eventsStartingAtSameTime(as: next.startDate, in: upcoming)

            if sameStart.count > 1 {
                menuBarTitle = "\(sameStart.count) events in \(timeStr)"
            } else {
                let title = truncateTitle(next.title)
                if settings.showEventTitle {
                    menuBarTitle = "\(title) · in \(timeStr)"
                } else {
                    menuBarTitle = "in \(timeStr)"
                }
            }
            return
        }

        // ── No events remaining today ──
        menuBarTitle = ""
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval), 0)

        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
        } else {
            let hours = totalSeconds / 3600
            let mins = (totalSeconds % 3600) / 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }

    private func truncateTitle(_ title: String) -> String {
        if title.count > settings.maxEventTitleLength {
            return String(title.prefix(settings.maxEventTitleLength)) + "..."
        }
        return title
    }

    // MARK: - Private — Active Meeting (banner)

    private func updateActiveMeeting() {
        let now = Date()
        activeMeeting = cachedTodayEvents
            .filter { $0.startDate <= now && $0.endDate > now && $0.meetingLink != nil }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    // MARK: - Private — Data Fetching

    private func fetchEventsForSelectedDate() {
        calendarService.fetchEvents(for: selectedDate, disabledCalendarIDs: settings.disabledCalendarIDs)
    }

    // MARK: - Private — Timers & Observers

    private func startTimers() {
        // 1-second: update menu bar title (uses cached events, lightweight)
        titleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateMenuBarTitle()
            self?.checkAutoJoin()
        }

        // 10-second: update time indicator, refresh event cache, update active meeting
        clockTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
            self?.refreshTodayEventsCache()
            self?.updateActiveMeeting()
        }

        // 5-minute: full data refresh (re-fetch for timeline view)
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

        let now = Date()
        let candidates = cachedTodayEvents
            .filter { $0.meetingLink != nil && !autoJoinedEventIDs.contains($0.id) }

        for event in candidates {
            let timeUntilStart = event.startDate.timeIntervalSince(now)
            if timeUntilStart <= 15 && timeUntilStart >= -60 {
                autoJoinedEventIDs.insert(event.id)
                NSWorkspace.shared.open(event.meetingLink!)
                break
            }
        }
    }
}
