//
//  MeetingLinkParser.swift
//  cali
//

import EventKit
import Foundation

enum MeetingLinkParser {

    // MARK: - Public

    static func extractMeetingLink(from event: EKEvent) -> URL? {
        if let url = event.url, isMeetingLink(url) {
            return url
        }

        if let location = event.location, let url = findMeetingURL(in: location) {
            return url
        }

        if let notes = event.notes, let url = findMeetingURL(in: notes) {
            return url
        }

        return nil
    }

    // MARK: - Private

    private static let meetingPatterns: [String] = [
        "https?://[\\w.-]*zoom\\.us/j/[\\w?=&%-]+",
        "https?://meet\\.google\\.com/[\\w-]+",
        "https?://teams\\.microsoft\\.com/l/meetup-join/[\\w%/.?=&-]+",
        "https?://[\\w.-]*webex\\.com/[\\w/.?=&-]+",
    ]

    private static func isMeetingLink(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us")
            || host.contains("meet.google.com")
            || host.contains("teams.microsoft.com")
            || host.contains("webex.com")
    }

    private static func findMeetingURL(in text: String) -> URL? {
        for pattern in meetingPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  let matchRange = Range(match.range, in: text)
            else {
                continue
            }
            return URL(string: String(text[matchRange]))
        }
        return nil
    }
}
