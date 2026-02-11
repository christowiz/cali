//
//  EmptyStateView.swift
//  cali
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No upcoming events")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Enjoy your free time!")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
