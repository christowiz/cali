//
//  PermissionView.swift
//  cali
//

import SwiftUI

struct PermissionView: View {
    let onOpenSettings: () -> Void
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            VStack(spacing: 4) {
                Text("Calendar Access Required")
                    .font(.system(size: 14, weight: .semibold))

                Text("Cali needs access to your calendar\nto show upcoming meetings.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Button("Open System Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Retry") {
                    Task { await onRetry() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
    }
}
