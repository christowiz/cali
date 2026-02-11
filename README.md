# Cali

> [!NOTE]
> This is basicaly a clone of [dottt.app](https://dottt.app/) for personal use

A lightweight macOS menu bar app that displays your upcoming calendar events in a clean timeline view.

## Features

- **Menu bar integration** — Shows your next meeting and countdown directly in the macOS menu bar
- **Timeline view** — Visual hour-by-hour timeline with color-coded event blocks
- **Overlapping events** — Side-by-side column layout for events that overlap in time
- **Active meeting banner** — Quick-access "Join" button when a meeting with a video link is in progress
- **Meeting link detection** — Automatically detects Zoom, Google Meet, Teams, and Webex links from event details
- **Inline event details** — Click any event to expand an inline detail card with title, time, attendees, notes, and join link
- **Date navigation** — Browse previous and upcoming days
- **Resizable popup** — Vertically resizable to fit your screen
- **Dark theme** — Designed to blend with macOS dark mode
- **Configurable settings**:
  - Open at login
  - Auto-join meetings
  - Visible hour range
  - Menu bar title format (show/hide event title, max length, seconds)
  - Enable/disable individual calendars

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/cali.git
   ```
2. Open `Cali.xcodeproj` in Xcode
3. Build and run (`Cmd + R`)
4. Grant calendar access when prompted
5. Click the calendar icon in your menu bar

## Project Structure

```
cali/
├── CaliApp.swift                  # App entry point (MenuBarExtra + Settings window)
├── Cali.entitlements              # Sandbox & calendar permissions
├── Models/
│   ├── AppSettings.swift          # User preferences (UserDefaults + login items)
│   └── CalendarEvent.swift        # Calendar event model wrapping EKEvent
├── Services/
│   ├── CalendarService.swift      # EventKit integration (auth, fetch, calendars)
│   └── MeetingLinkParser.swift    # Regex-based meeting URL extraction
├── ViewModels/
│   └── MenuBarViewModel.swift     # Central state management and business logic
└── Views/
    ├── MenuBarView.swift          # Main popup view with header, timeline, footer
    ├── CalendarTimelineView.swift # Hour grid + positioned event blocks + overlap engine
    ├── EventBlockView.swift       # Individual event block in the timeline
    ├── EventDetailPopover.swift   # Inline detail card for selected events
    ├── EmptyStateView.swift       # Empty state when no events exist
    ├── PermissionView.swift       # Calendar access request prompt
    ├── SettingsView.swift         # Settings window with sidebar navigation
    └── Settings/
        ├── PreferencesSettingsView.swift  # Login & auto-join toggles
        ├── CalendarSettingsView.swift     # Visible hour range
        ├── MenuBarSettingsView.swift      # Menu bar display options
        └── CalendarsSettingsView.swift    # Per-calendar toggle list
```

## Permissions

Cali requires **Full Calendar Access** to read your events. The app runs sandboxed with only the following entitlements:

- `com.apple.security.app-sandbox`
- `com.apple.security.personal-information.calendars`
- `com.apple.security.files.user-selected.read-only`

No data leaves your machine.

## License

MIT
