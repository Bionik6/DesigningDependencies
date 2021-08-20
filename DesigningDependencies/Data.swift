import Foundation

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
