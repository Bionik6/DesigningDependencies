import Network
import SwiftUI
import Combine
import CoreLocation
import WeatherClient


public class AppViewModel: ObservableObject {
  var weatherClient: WeatherClient
  var weatherRequestCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  public init(weatherClient: WeatherClient) {
    self.weatherClient = weatherClient
    
    let pathMonitor = NWPathMonitor()
    pathMonitor.pathUpdateHandler = { [weak self] path in
      guard let self = self else { return }
      self.isConnected = path.status == .satisfied
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
    ContentView(viewModel: AppViewModel(weatherClient: .happyPath))
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
