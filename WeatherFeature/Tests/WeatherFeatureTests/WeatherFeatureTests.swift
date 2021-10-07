import XCTest
import Combine
import CoreLocation
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

extension WeatherClient {
  static let unimplemented = Self(
    weather: { _ in fatalError() },
    searchLocations: { _ in fatalError() }
  )

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
  
  func test_disconnected_state() {
    let viewModel = AppViewModel(
      weatherClient: .unimplemented,
      pathMonitorClient: .unsatisfied,
      locationClient: .authorizedWhenInUse
    )
    
    XCTAssertEqual(viewModel.currentLocation, nil)
    XCTAssertEqual(viewModel.isConnected, false)
    XCTAssertEqual(viewModel.weatherResults, [])
  }
  
  func test_path_updates() {
    let pathUpdateSubject = PassthroughSubject<NetworkPath, Never>()
    let viewModel = AppViewModel(
      weatherClient: WeatherClient(
        weather: { _ in .init(.moderateWeather) },
        searchLocations: { _ in .init([.brooklyn]) }
      ),
      pathMonitorClient: PathMonitorClient(networkPublisher: pathUpdateSubject.eraseToAnyPublisher()),
      locationClient: .authorizedWhenInUse
    )
    pathUpdateSubject.send(.init(status: .satisfied))
    
    XCTAssertEqual(viewModel.currentLocation, .brooklyn)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, WeatherResponse.moderateWeather.consolidatedWeather)
    
    pathUpdateSubject.send(.init(status: .unsatisfied))
    
    XCTAssertEqual(viewModel.currentLocation, .brooklyn)
    XCTAssertEqual(viewModel.isConnected, false)
    XCTAssertEqual(viewModel.weatherResults, [])
    
    pathUpdateSubject.send(.init(status: .satisfied))
    
    XCTAssertEqual(viewModel.currentLocation, .brooklyn)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, WeatherResponse.moderateWeather.consolidatedWeather)
  }
  
  func test_location_authorization() {
    var authorizationStatus = CLAuthorizationStatus.notDetermined
    let subject = PassthroughSubject<LocationClient.DelegateEvent, Never>()
    let viewModel = AppViewModel(
      weatherClient: WeatherClient(
        weather: { _ in .init(.moderateWeather) },
        searchLocations: { _ in .init([.brooklyn]) }
      ),
      pathMonitorClient: .satisfied,
      locationClient: LocationClient(
        requestLocation: { subject.send(.didUpdateLocations([CLLocation()])) },
        requestWhenInUseAuthorization: {
          authorizationStatus = .authorizedWhenInUse
          subject.send(.didChangeAuthorizationStatus(authorizationStatus))
        },
        authorizationStatus: { authorizationStatus },
        delegate: subject.eraseToAnyPublisher()
      )
    )
    
    XCTAssertEqual(viewModel.currentLocation, nil)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, [])
    
    viewModel.locationButtonTapped()
    
    XCTAssertEqual(viewModel.currentLocation, .brooklyn)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, WeatherResponse.moderateWeather.consolidatedWeather)
  }
  
  
  func test_location_authorization_denied() {
    var authorizationStatus = CLAuthorizationStatus.notDetermined
    let subject = PassthroughSubject<LocationClient.DelegateEvent, Never>()
    let viewModel = AppViewModel(
      weatherClient: WeatherClient(
        weather: { _ in .init(.moderateWeather) },
        searchLocations: { _ in .init([.brooklyn]) }
      ),
      pathMonitorClient: .satisfied,
      locationClient: LocationClient(
        requestLocation: { fatalError() },
        requestWhenInUseAuthorization: {
          authorizationStatus = .denied
          subject.send(.didChangeAuthorizationStatus(authorizationStatus))
        },
        authorizationStatus: { authorizationStatus },
        delegate: subject.eraseToAnyPublisher()
      )
    )
    
    XCTAssertEqual(viewModel.currentLocation, nil)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, [])
    // XCTAssertEqual(viewModel.authorizationAlert, nil)

    viewModel.locationButtonTapped()
    
    XCTAssertEqual(viewModel.currentLocation, nil)
    XCTAssertEqual(viewModel.isConnected, true)
    XCTAssertEqual(viewModel.weatherResults, [])
    // XCTAssertEqual(viewModel.authorizationAlert, "Please give us location access")
  }
}
