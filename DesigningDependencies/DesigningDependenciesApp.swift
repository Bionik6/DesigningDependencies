//
//  DesigningDependenciesApp.swift
//  DesigningDependencies
//
//  Created by Ibrahima Ciss on 20/08/2021.
//

import SwiftUI
import WeatherClientLive

@main
struct DesigningDependenciesApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView(viewModel: AppViewModel(weatherClient: .live))
        }
    }
}
