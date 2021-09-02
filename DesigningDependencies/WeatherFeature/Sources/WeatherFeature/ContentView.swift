import SwiftUI
import Combine
import CoreLocation
import WeatherClient
import PathMonitorClient

public class AppViewModel: ObservableObject {
  private var weatherClient: WeatherClient
  private var pathMonitorClient: PathMonitorClient
  private var pathUpdateCancellable: AnyCancellable?
  private var weatherRequestCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  public init(
    weatherClient: WeatherClient,
    pathMonitorClient: PathMonitorClient
  ) {
    self.weatherClient = weatherClient
    self.pathMonitorClient = pathMonitorClient
    pathUpdateCancellable = self.pathMonitorClient.networkPublisher
      .map { $0.status == .satisfied }
      .removeDuplicates()
      .sink { [weak self] isConnected in
        guard let self = self else { return }
        self.isConnected = isConnected
        if self.isConnected == true {
          self.refreshWeather()
        } else {
          self.weatherResults = []
        }
      }
  }
  
  private func refreshWeather() {
    weatherResults = []
    weatherRequestCancellable = weatherClient
      .weather(10)
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
    return ContentView(viewModel: AppViewModel(weatherClient: .happyPath, pathMonitorClient: .unsatisfied))
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
