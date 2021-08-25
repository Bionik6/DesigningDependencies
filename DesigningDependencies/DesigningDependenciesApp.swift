import SwiftUI
import WeatherFeature
import WeatherClientLive

@main
struct DesigningDependenciesApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: AppViewModel(weatherClient: .live))
    }
  }
}
