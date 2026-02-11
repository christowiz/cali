//
//  MenuBarView.swift
//  cali
//

import AppKit
import EventKit
import SwiftUI

struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    @Environment(\.openWindow) private var openWindow

    private static let panelWidth: CGFloat = 440

    var body: some View {
        VStack(spacing: 0) {
            // Active meeting banner (pinned above everything)
            if let meeting = viewModel.activeMeeting {
                activeMeetingBanner(meeting)
            }

            headerView

            Divider().opacity(0.3)

            if viewModel.calendarService.authorizationStatus != .fullAccess {
                PermissionView(
                    onOpenSettings: { viewModel.openCalendarSettings() },
                    onRetry: { await viewModel.start() }
                )
            } else if viewModel.timedEvents.isEmpty && viewModel.allDayEvents.isEmpty {
                EmptyStateView()
            } else {
                if !viewModel.allDayEvents.isEmpty {
                    allDayBanner
                    Divider().opacity(0.3)
                }

                CalendarTimelineView(
                    events: viewModel.timedEvents,
                    currentDate: viewModel.currentDate,
                    selectedDate: viewModel.selectedDate,
                    earliestHour: Int(viewModel.settings.earliestVisibleHour),
                    latestHour: Int(viewModel.settings.latestVisibleHour),
                    onJoin: { event in viewModel.joinMeeting(event) }
                )
                .layoutPriority(1)
            }

            Divider().opacity(0.3)

            footerView
        }
        .frame(
            minWidth: Self.panelWidth, idealWidth: Self.panelWidth, maxWidth: Self.panelWidth,
            minHeight: 900, idealHeight: 1200, maxHeight: .infinity
        )
        .background(Color(nsColor: NSColor(white: 0.11, alpha: 1)))
        .background(PanelResizer())
        .task {
            await viewModel.start()
        }
    }

    // MARK: - Active Meeting Banner

    private func activeMeetingBanner(_ meeting: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(timeRange(meeting))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Now")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.2), in: Capsule())
                }

                Text(meeting.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { viewModel.joinMeeting(meeting) }) {
                HStack(spacing: 5) {
                    Image(systemName: "video")
                        .font(.system(size: 11))
                    Text("Join")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.purple.opacity(0.7))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(viewModel.headerDateString)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            HStack(spacing: 4) {
                Button(action: { viewModel.navigateDay(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Previous day")

                Button(action: { viewModel.goToToday() }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Go to today")

                Button(action: { viewModel.navigateDay(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Next day")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - All Day Banner

    private var allDayBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.allDayEvents) { event in
                HStack(spacing: 8) {
                    Circle()
                        .fill(event.calendarColor.map { Color(cgColor: $0) } ?? .gray)
                        .frame(width: 6, height: 6)

                    Text(event.title)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.activateApp()
                openWindow(id: "settings")
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()

            Button(action: { viewModel.quit() }) {
                Text("Quit")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func timeRange(_ event: CalendarEvent) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startDate)) → \(formatter.string(from: event.endDate))"
    }
}

// MARK: - Panel Resizer

/// Configures the MenuBarExtra NSPanel: vertical-only resize, dark appearance, right-aligned.
private struct PanelResizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        PanelResizerView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class PanelResizerView: NSView {
    private static let panelWidth: CGFloat = 440
    private static let minHeight: CGFloat = 300

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configurePanel()
    }

    private func configurePanel() {
        guard let window else { return }

        // Force dark appearance
        window.appearance = NSAppearance(named: .darkAqua)

        // Enable vertical-only resize (lock width, allow height)
        window.styleMask.insert(.resizable)

        let screenHeight = window.screen?.visibleFrame.height
            ?? NSScreen.main?.visibleFrame.height
            ?? 800

        window.minSize = NSSize(width: Self.panelWidth, height: Self.minHeight)
        window.maxSize = NSSize(width: Self.panelWidth, height: screenHeight)

        // Ensure width stays locked after any resize
        if window.frame.width != Self.panelWidth {
            var frame = window.frame
            frame.size.width = Self.panelWidth
            window.setFrame(frame, display: true)
        }
    }
}
