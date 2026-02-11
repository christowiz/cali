//
//  AppSettings.swift
//  cali
//

import Foundation
import ServiceManagement

@Observable
final class AppSettings {

    // MARK: - Preferences

    var autoJoinEnabled: Bool {
        didSet { UserDefaults.standard.set(autoJoinEnabled, forKey: "autoJoinEnabled") }
    }

    var launchAtLogin: Bool {
        didSet { updateLoginItem(enabled: launchAtLogin) }
    }

    // MARK: - Calendar

    var earliestVisibleHour: Double {
        didSet { UserDefaults.standard.set(earliestVisibleHour, forKey: "earliestVisibleHour") }
    }

    var latestVisibleHour: Double {
        didSet { UserDefaults.standard.set(latestVisibleHour, forKey: "latestVisibleHour") }
    }

    // MARK: - Menu Bar

    var showEventTitle: Bool {
        didSet { UserDefaults.standard.set(showEventTitle, forKey: "showEventTitle") }
    }

    var maxEventTitleLength: Int {
        didSet { UserDefaults.standard.set(maxEventTitleLength, forKey: "maxEventTitleLength") }
    }

    var showSeconds: Bool {
        didSet { UserDefaults.standard.set(showSeconds, forKey: "showSeconds") }
    }

    // MARK: - Calendars

    var disabledCalendarIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(disabledCalendarIDs), forKey: "disabledCalendarIDs")
        }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        defaults.register(defaults: [
            "autoJoinEnabled": true,
            "earliestVisibleHour": 8.0,
            "latestVisibleHour": 20.0,
            "showEventTitle": true,
            "maxEventTitleLength": 10,
            "showSeconds": false,
        ])

        self.autoJoinEnabled = defaults.bool(forKey: "autoJoinEnabled")
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.earliestVisibleHour = defaults.double(forKey: "earliestVisibleHour")
        self.latestVisibleHour = defaults.double(forKey: "latestVisibleHour")
        self.showEventTitle = defaults.bool(forKey: "showEventTitle")
        self.maxEventTitleLength = defaults.integer(forKey: "maxEventTitleLength")
        self.showSeconds = defaults.bool(forKey: "showSeconds")

        let savedIDs = defaults.stringArray(forKey: "disabledCalendarIDs") ?? []
        self.disabledCalendarIDs = Set(savedIDs)
    }

    // MARK: - Login Item

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[AppSettings] Failed to update login item: \(error.localizedDescription)")
            // Revert to actual system state without re-triggering didSet
            let actualStatus = SMAppService.mainApp.status == .enabled
            if launchAtLogin != actualStatus {
                launchAtLogin = actualStatus
            }
        }
    }

    // MARK: - Helpers

    func isCalendarEnabled(_ calendarID: String) -> Bool {
        !disabledCalendarIDs.contains(calendarID)
    }

    func toggleCalendar(_ calendarID: String) {
        if disabledCalendarIDs.contains(calendarID) {
            disabledCalendarIDs.remove(calendarID)
        } else {
            disabledCalendarIDs.insert(calendarID)
        }
    }
}
