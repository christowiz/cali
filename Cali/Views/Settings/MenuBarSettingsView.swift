//
//  MenuBarSettingsView.swift
//  cali
//

import SwiftUI

struct MenuBarSettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Menubar")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 24)

            // Info box
            VStack(alignment: .leading, spacing: 4) {
                Text("Don't see the menu bar text?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)

                Text("Hold ⌘ and drag the icon to the right or adjust the maximum length below.\nThis should only occur if you have too many icons in your menu bar.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.red.opacity(0.4), lineWidth: 1)
            )
            .padding(.bottom, 20)

            // Show event title
            settingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show event title")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Display the event title in the menu bar")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } control: {
                Toggle("", isOn: $settings.showEventTitle)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            settingsDivider

            // Maximum event title length
            settingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Maximum event title length")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Maximum number of event title characters to display in the menubar")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } control: {
                TextField("", value: $settings.maxEventTitleLength, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
            }

            settingsDivider

            // Show seconds in tray
            settingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show seconds in tray")
                        .font(.system(size: 13, weight: .semibold))
                    Text("More precision, much wow")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } control: {
                Toggle("", isOn: $settings.showSeconds)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Spacer()

            HStack {
                Spacer()
                Text("version 1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
    }

    // MARK: - Reusable Components

    private func settingsRow<Label: View, Control: View>(
        @ViewBuilder label: () -> Label,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack {
            label()
            Spacer()
            control()
        }
        .padding(.vertical, 12)
    }

    private var settingsDivider: some View {
        Divider().padding(.vertical, 2)
    }
}
