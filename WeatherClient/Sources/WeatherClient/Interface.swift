import Combine
import Foundation
import CoreLocation


// A client for accessing weather data for locations
public struct WeatherClient {
  public var weather: (Int) -> AnyPublisher<WeatherResponse, Error>
  public var searchLocations: (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
  
  public init(
    weather: @escaping (Int) -> AnyPublisher<WeatherResponse, Error>,
    searchLocations: @escaping (CLLocationCoordinate2D) -> AnyPublisher<[Location], Error>
  ) {
    self.weather = weather
    self.searchLocations = searchLocations
  }
}


public struct WeatherResponse: Decodable, Equatable {
  public var consolidatedWeather: [ConsolidatedWeather]
  
  public struct ConsolidatedWeather: Decodable, Equatable {
    public var applicableDate: Date
    public var id: Int
    public var maxTemp: Double
    public var minTemp: Double
    public var theTemp: Double
  }
}


public struct Location: Decodable, Equatable {
  public var title: String
  public  var woeid: Int
}
