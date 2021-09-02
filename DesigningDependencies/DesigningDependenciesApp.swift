import SwiftUI
import WeatherFeature
import WeatherClientLive
import PathMonitorClientLive

@main
struct DesigningDependenciesApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: AppViewModel(weatherClient: .live, pathMonitorClient: .live(queue: .main)))
    }
  }
}
