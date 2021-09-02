import SwiftUI
import WeatherFeature
import WeatherClientLive
import PathMonitorClient

@main
struct DesigningDependenciesApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: AppViewModel(weatherClient: .live, pathMonitorClient: PathMonitorClient.live(queue: .main)))
    }
  }
}
