//
//  PreferencesSettingsView.swift
//  cali
//

import SwiftUI

struct PreferencesSettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Preferences")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 24)

            // Open at login
            settingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open at login")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Start up the app when your computer turns on")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } control: {
                Toggle("", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            settingsDivider

            // Auto join meetings
            settingsRow {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Auto join meetings")
                                .font(.system(size: 13, weight: .semibold))

                            Text("Recommended")
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .strokeBorder(.secondary.opacity(0.5), lineWidth: 1)
                                )
                        }
                        Text("Automatically open all meetings in the browser when they start")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            } control: {
                Toggle("", isOn: $settings.autoJoinEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Spacer()

            versionLabel
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

    private var versionLabel: some View {
        HStack {
            Spacer()
            Text("version 1.0.0")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}
