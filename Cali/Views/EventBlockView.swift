//
//  EventBlockView.swift
//  cali
//

import SwiftUI

struct EventBlockView: View {
    let event: CalendarEvent
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Calendar color stripe
            UnevenRoundedRectangle(
                topLeadingRadius: 3,
                bottomLeadingRadius: 3,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(calendarColor)
            .frame(width: 4)

            // Event content
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))

                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(calendarColor.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.45))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - Computed

    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startDate)) → \(formatter.string(from: event.endDate))"
    }
}
