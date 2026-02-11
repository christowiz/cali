//
//  CalendarEvent.swift
//  cali
//

import EventKit
import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarColor: CGColor?
    let calendarTitle: String
    let location: String?
    let notes: String?
    let url: URL?
    let isAllDay: Bool
    let meetingLink: URL?
    let attendeeCount: Int

    var isInProgress: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }

    var hasEnded: Bool {
        endDate <= Date()
    }

    var durationInHours: Double {
        endDate.timeIntervalSince(startDate) / 3600.0
    }

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "Untitled"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.calendarColor = ekEvent.calendar.cgColor
        self.calendarTitle = ekEvent.calendar.title
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url
        self.isAllDay = ekEvent.isAllDay
        self.meetingLink = MeetingLinkParser.extractMeetingLink(from: ekEvent)
        self.attendeeCount = ekEvent.attendees?.count ?? 0
    }
}
