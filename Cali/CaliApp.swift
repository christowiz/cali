//
//  caliApp.swift
//  cali
//
//  Created by Christopher Gwizdala on 2/10/26.
//

import SwiftUI

@main
struct CaliApp: App {
    @State private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Label(viewModel.menuBarTitle, systemImage: "beach.umbrella.fill")
                .task { await viewModel.start() }
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .defaultSize(width: 600, height: 460)
        .windowResizability(.contentSize)
    }
}
