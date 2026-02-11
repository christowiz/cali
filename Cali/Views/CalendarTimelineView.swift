//
//  CalendarTimelineView.swift
//  cali
//

import SwiftUI

struct CalendarTimelineView: View {
    let events: [CalendarEvent]
    let currentDate: Date
    let selectedDate: Date
    let earliestHour: Int
    let latestHour: Int
    let onJoin: (CalendarEvent) -> Void

    @State private var selectedEvent: CalendarEvent?

    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 56
    private let contentLeading: CGFloat = 8
    private let contentTrailing: CGFloat = 8
    private let columnGap: CGFloat = 3
    private let detailCardEstimatedHeight: CGFloat = 220
    private let topPadding: CGFloat = 10

    private var totalHeight: CGFloat {
        CGFloat(latestHour - earliestHour) * hourHeight + topPadding
    }

    /// Extra space at the bottom when a card is shown near the end of the timeline.
    private var bottomPadding: CGFloat {
        guard let selected = selectedEvent else { return 0 }
        let blockHeight = max(CGFloat(selected.durationInHours) * hourHeight, 28)
        let cardTop = yPosition(for: selected.startDate) + blockHeight
        let remaining = totalHeight - cardTop
        return max(detailCardEstimatedHeight - remaining + 16, 0)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var eventLayouts: [String: OverlapLayout.LayoutInfo] {
        OverlapLayout.compute(for: events)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                hourGrid
                    .frame(height: totalHeight + bottomPadding)
                    .overlay(alignment: .topLeading) {
                        GeometryReader { geometry in
                            eventBlocksLayer(totalWidth: geometry.size.width)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if isToday {
                            currentTimeIndicator
                        }
                    }
                    .id("timeline")
            }
            .onAppear {
                scrollToRelevantPosition(proxy: proxy)
            }
            .onChange(of: selectedDate) {
                selectedEvent = nil
            }
        }
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 10)

            ForEach(earliestHour..<latestHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    Text(hourLabel(hour))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -7)

                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
            }

            // Extra space for detail card overflow
            if bottomPadding > 0 {
                Color.clear.frame(height: bottomPadding)
            }
        }
    }

    // MARK: - Event Blocks + Inline Detail Card

    private func eventBlocksLayer(totalWidth: CGFloat) -> some View {
        let availableWidth = totalWidth - timeColumnWidth - contentLeading - contentTrailing
        let layouts = eventLayouts

        return ZStack(alignment: .topLeading) {
            // Event blocks
            ForEach(events) { event in
                let layout = layouts[event.id] ?? OverlapLayout.LayoutInfo(column: 0, totalColumns: 1)
                let colWidth = availableWidth / CGFloat(layout.totalColumns)
                let blockWidth = colWidth - columnGap
                let blockHeight = max(CGFloat(event.durationInHours) * hourHeight, 28)

                let xCenter = timeColumnWidth + contentLeading
                    + CGFloat(layout.column) * colWidth
                    + blockWidth / 2
                let yCenter = yPosition(for: event.startDate) + blockHeight / 2

                EventBlockView(event: event) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedEvent = selectedEvent?.id == event.id ? nil : event
                    }
                }
                .frame(width: blockWidth, height: blockHeight)
                .position(x: xCenter, y: yCenter)
            }

            // Inline detail card below the selected event
            if let selected = selectedEvent {
                let blockHeight = max(CGFloat(selected.durationInHours) * hourHeight, 28)
                let cardTop = yPosition(for: selected.startDate) + blockHeight + 6

                VStack(spacing: 0) {
                    Color.clear.frame(height: cardTop)

                    EventDetailCard(event: selected) { onJoin(selected) }
                        .padding(.leading, timeColumnWidth + contentLeading)
                        .padding(.trailing, contentTrailing)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    Spacer(minLength: 0)
                }
                .zIndex(100)
            }
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let yPos = currentTimeYPosition

        return HStack(spacing: 0) {
            Circle()
                .fill(.yellow)
                .frame(width: 8, height: 8)
                .padding(.leading, timeColumnWidth)

            Rectangle()
                .fill(.yellow)
                .frame(height: 1.5)
        }
        .offset(y: yPos - 4)
    }

    // MARK: - Position Calculations

    private func yPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let hourOffset = CGFloat(hour - earliestHour) + CGFloat(minute) / 60.0
        return topPadding + hourOffset * hourHeight
    }

    private var currentTimeYPosition: CGFloat {
        yPosition(for: currentDate)
    }

    // MARK: - Helpers

    private func hourLabel(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour) \(period)"
    }

    private func scrollToRelevantPosition(proxy: ScrollViewProxy) {
        proxy.scrollTo("timeline", anchor: .top)
    }
}

// MARK: - Overlap Layout Engine

private enum OverlapLayout {

    struct LayoutInfo {
        let column: Int
        let totalColumns: Int
    }

    static func compute(for events: [CalendarEvent]) -> [String: LayoutInfo] {
        guard !events.isEmpty else { return [:] }

        let sorted = events.sorted {
            if $0.startDate == $1.startDate {
                return $0.endDate > $1.endDate
            }
            return $0.startDate < $1.startDate
        }

        let eventColumn = assignColumns(sorted)
        return buildLayoutMap(sorted: sorted, eventColumn: eventColumn)
    }

    private static func assignColumns(_ sorted: [CalendarEvent]) -> [String: Int] {
        var columnEndTimes: [Date] = []
        var eventColumn: [String: Int] = [:]

        for event in sorted {
            var assignedColumn: Int?

            for i in 0..<columnEndTimes.count {
                if columnEndTimes[i] <= event.startDate {
                    columnEndTimes[i] = event.endDate
                    assignedColumn = i
                    break
                }
            }

            if let col = assignedColumn {
                eventColumn[event.id] = col
            } else {
                eventColumn[event.id] = columnEndTimes.count
                columnEndTimes.append(event.endDate)
            }
        }

        return eventColumn
    }

    private static func buildLayoutMap(
        sorted: [CalendarEvent],
        eventColumn: [String: Int]
    ) -> [String: LayoutInfo] {
        var visited = Set<String>()
        var result: [String: LayoutInfo] = [:]

        for event in sorted {
            guard !visited.contains(event.id) else { continue }

            var group: [CalendarEvent] = []
            var queue = [event]

            while !queue.isEmpty {
                let current = queue.removeFirst()
                guard !visited.contains(current.id) else { continue }
                visited.insert(current.id)
                group.append(current)

                for other in sorted where !visited.contains(other.id) {
                    if overlaps(current, other) {
                        queue.append(other)
                    }
                }
            }

            let maxCol = group.compactMap { eventColumn[$0.id] }.max() ?? 0
            let totalColumns = maxCol + 1

            for member in group {
                result[member.id] = LayoutInfo(
                    column: eventColumn[member.id] ?? 0,
                    totalColumns: totalColumns
                )
            }
        }

        return result
    }

    private static func overlaps(_ a: CalendarEvent, _ b: CalendarEvent) -> Bool {
        a.startDate < b.endDate && b.startDate < a.endDate
    }
}
