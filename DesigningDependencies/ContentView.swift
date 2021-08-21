import SwiftUI
import Combine
import CoreLocation

struct Location { }

protocol WeatherClientProtocol {
  func weather() -> AnyPublisher<WeatherResponse, Error>
  func searchLocations(coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}


struct WeatherClient {
  var weather: () -> AnyPublisher<WeatherResponse, Error>
  var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
}


extension WeatherClient {
  static let live = Self(weather: {
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/2459115")!)
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }, searchLocations:  { coordinates in
    fatalError()
  })
}


extension WeatherClient {
  static let empty = Self(weather: {
    Just(WeatherResponse(consolidatedWeather: []))
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }, searchLocations:  { coordinates in
    Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  })
  
  static let happyPath = Self(weather: {
    Just(
      WeatherResponse(
        consolidatedWeather: [
          .init(applicableDate: Date(), id: 1, maxTemp: 30, minTemp: 10, theTemp: 20),
          .init(applicableDate: Date().addingTimeInterval(86400), id: 2, maxTemp: -10, minTemp: -30, theTemp: -20)
        ]
      )
    )
    .setFailureType(to: Error.self)
    .eraseToAnyPublisher()
  }, searchLocations: { _ in
    Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  })
  
  static let failed = Self(weather: {
    Fail(error: NSError(domain: "", code: 1))
      .eraseToAnyPublisher()
  }, searchLocations: { _ in
    Just([])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  })
}

class AppViewModel: ObservableObject {
  var weatherClient: WeatherClient
  var weatherRequestCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  init(isConnected: Bool = true, weatherClient: WeatherClient = .live) {
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
    ContentView(viewModel: AppViewModel(weatherClient: .happyPath))
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
