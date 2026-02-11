//
//  SettingsView.swift
//  cali
//

import SwiftUI

struct SettingsView: View {
    let viewModel: MenuBarViewModel
    @State private var selectedTab: SettingsTab = .preferences

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .font(.system(size: 13))
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selectedTab {
                case .preferences:
                    PreferencesSettingsView(settings: viewModel.settings)
                case .calendar:
                    CalendarSettingsView(settings: viewModel.settings)
                case .menubar:
                    MenuBarSettingsView(settings: viewModel.settings)
                case .calendars:
                    CalendarsSettingsView(
                        calendarService: viewModel.calendarService,
                        settings: viewModel.settings,
                        onCalendarToggled: { viewModel.refresh() }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 560, minHeight: 400)
    }
}

// MARK: - Tab Definition

enum SettingsTab: String, CaseIterable {
    case preferences
    case calendar
    case menubar
    case calendars

    var title: String {
        switch self {
        case .preferences: "Preferences"
        case .calendar: "Calendar"
        case .menubar: "Menubar"
        case .calendars: "Calendars"
        }
    }

    var icon: String {
        switch self {
        case .preferences: "slider.horizontal.3"
        case .calendar: "calendar"
        case .menubar: "menubar.rectangle"
        case .calendars: "square.grid.2x2"
        }
    }
}
