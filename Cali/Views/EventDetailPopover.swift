//
//  EventDetailPopover.swift
//  cali
//

import AppKit
import SwiftUI

/// Inline detail card shown beneath a selected event in the timeline.
struct EventDetailCard: View {
    let event: CalendarEvent
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(event.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(3)

            // Notes excerpt
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(3)
            }

            // Time
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 14)

                Text(timeString)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Attendees
            if event.attendeeCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(width: 14)

                    Text("\(event.attendeeCount) attendees")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            // Meeting link + Join button
            if let link = event.meetingLink {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(width: 14)
                        .padding(.top, 1)

                    Text(link.absoluteString)
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                        .lineLimit(2)
                }

                Button(action: onJoin) {
                    HStack(spacing: 6) {
                        Image(systemName: "video")
                            .font(.system(size: 12))
                        Text("Join")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(.white, in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: NSColor(white: 0.16, alpha: 1)))
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        )
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }
}
