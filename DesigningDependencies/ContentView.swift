import SwiftUI
import Combine

protocol WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error>
}

struct WeatherClient: WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error> {
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/2459115")!)
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

struct MockWeatherClient: WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error> {
    Just(WeatherResponse(consolidatedWeather: [
      .init(applicableDate: Date(), id: 1, maxTemp: 32, minTemp: 28, theTemp: 30),
      .init(applicableDate: Date().addingTimeInterval(86400), id: 2, maxTemp: -10, minTemp: -20, theTemp: -20)
    ]))
      .setFailureType(to: Error.self)
      .delay(for: 3, scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

class AppViewModel: ObservableObject {
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  var weatherRequestCancellable: AnyCancellable?
  var weatherClient: WeatherClientProtocol
  
  init(isConnected: Bool = true, weatherClient: WeatherClientProtocol = WeatherClient()) {
    self.isConnected = isConnected
    self.weatherClient = weatherClient
    
    weatherRequestCancellable = weatherClient
      .weather()
      .sink { _ in }
        receiveValue: { [weak self] in self?.weatherResults = $0.consolidatedWeather }
  }
}

struct ContentView: View {
  @ObservedObject var viewModel: AppViewModel
  
  var body: some View {
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
    ContentView(viewModel: AppViewModel(weatherClient: MockWeatherClient()))
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()


struct WeatherResponse: Decodable, Equatable {
  var consolidatedWeather: [ConsolidatedWeather]
  
  struct ConsolidatedWeather: Decodable, Equatable {
    var applicableDate: Date
    var id: Int
    var maxTemp: Double
    var minTemp: Double
    var theTemp: Double
  }
}

private let weatherJsonDecoder: JSONDecoder = {
  let jsonDecoder = JSONDecoder()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  jsonDecoder.dateDecodingStrategy = .formatted(formatter)
  jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
  return jsonDecoder
}()
