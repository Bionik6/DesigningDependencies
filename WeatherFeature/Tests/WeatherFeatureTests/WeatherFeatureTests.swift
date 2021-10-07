import XCTest
import Combine
import LocationClient
import PathMonitorClient
@testable import WeatherClient
@testable import WeatherFeature

extension WeatherResponse {
  static let moderateWeather = WeatherResponse(
    consolidatedWeather: [
      .init(
        applicableDate: Date(timeIntervalSinceReferenceDate: 0),
        id: 1,
        maxTemp: 30,
        minTemp: 20,
        theTemp: 25
      ),
    ]
  )
}

extension AnyPublisher {
  init(_ value: Output) {
    self = Just(value)
      .setFailureType(to: Failure.self)
      .eraseToAnyPublisher()
  }
}

extension Location {
  static let brooklyn = Location(title: "Brooklyn", woeid: 1)
}


final class WeatherFeatureTests: XCTestCase {
  
  func testBasics() {
    let viewModel = AppViewModel(
      weatherClient: WeatherClient(
        weather: { _ in .init(.moderateWeather) },
        searchLocations: { _ in .init([.brooklyn]) }
      ),
      pathMonitorClient: .satisfied,
      locationClient: .authorizedWhenInUse
    )
    
    XCTAssertEqual(viewModel.currentLocation, .brooklyn)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, WeatherResponse.moderateWeather.consolidatedWeather)
  }
  
  
}
