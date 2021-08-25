import Network
import SwiftUI
import Combine
import CoreLocation
import WeatherClient

public struct PathMonitorClient {
  public var setPathUpdateHandler: (@escaping (NWPath) -> Void) -> Void
  public var start: (DispatchQueue) -> Void
}

extension PathMonitorClient {
  
  public static var live: Self {
    let monitor = NWPathMonitor()
    return Self(setPathUpdateHandler: { monitor.pathUpdateHandler = $0 }, start: monitor.start(queue:))
  }
  
}


public class AppViewModel: ObservableObject {
  var weatherClient: WeatherClient
  var pathMonitorClient: PathMonitorClient
  var weatherRequestCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  public init(
    weatherClient: WeatherClient,
    pathMonitorClient: PathMonitorClient
  ) {
    self.weatherClient = weatherClient
    self.pathMonitorClient = pathMonitorClient
    
    self.pathMonitorClient.setPathUpdateHandler = { [weak self] path in
      guard let self = self else { return }
      // self.isConnected = path.status == .satisfied
      if self.isConnected == true {
        self.refreshWeather()
      } else {
        self.weatherResults = []
      }
    }
    
    pathMonitorClient.start(.main)
    self.refreshWeather()
  }
  
  private func refreshWeather() {
    weatherResults = []
    weatherRequestCancellable = weatherClient
      .weather()
      .sink { _ in }
        receiveValue: { [weak self] in self?.weatherResults = $0.consolidatedWeather }
  }
  
}

public struct ContentView: View {
  @ObservedObject var viewModel: AppViewModel
  
  public init(viewModel: AppViewModel) {
    self.viewModel = viewModel
  }
  
  public var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .bottomTrailing) {
          List {
            ForEach(self.viewModel.weatherResults, id: \.id) { weather in
              VStack(alignment: .leading) {
                Text(dayOfWeekFormatter.string(from: weather.applicableDate).capitalized)
                  .font(.title)
                Text("Current temp: \(weather.theTemp, specifier: "%.1f")°C")
                Text("Max temp: \(weather.maxTemp, specifier: "%.1f")°C")
                Text("Min temp: \(weather.minTemp, specifier: "%.1f")°C")
              }
            }
          }
          
          Button(
            action: {  }
          ) {
            Image(systemName: "location.fill")
              .foregroundColor(.white)
              .frame(width: 60, height: 60)
          }
          .background(Color.black)
          .clipShape(Circle())
          .padding()
        }
        
        if !self.viewModel.isConnected {
          HStack {
            Image(systemName: "exclamationmark.octagon.fill")
            Text("Not connected to internet")
          }
          .foregroundColor(.white)
          .padding()
          .background(Color.red)
        }
      }
      .navigationBarTitle("Weather")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    return ContentView(viewModel: AppViewModel(weatherClient: .happyPath, pathMonitorClient: .live))
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
