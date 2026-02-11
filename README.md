# Cali

> [!NOTE]
> This is basicaly a clone of https://dottt.app for personal use

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

## Permissions

Cali requires **Full Calendar Access** to read your events. The app runs sandboxed with only the following entitlements:

- `com.apple.security.app-sandbox`
- `com.apple.security.personal-information.calendars`
- `com.apple.security.files.user-selected.read-only`

No data leaves your machine.

## License

MIT
