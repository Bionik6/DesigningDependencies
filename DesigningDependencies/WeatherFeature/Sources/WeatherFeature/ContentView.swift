import SwiftUI
import Combine
import CoreLocation
import WeatherClient
import PathMonitorClient


struct LocationClient {
  var requestLocation: () -> Void
  var requestWhenInUseAuthorization: () -> Void
  var authorizationStatus: () -> CLAuthorizationStatus
  // var setDelegate: (CLLocationManagerDelegate) -> ()
  var delegate: AnyPublisher<DelegateEvent, Never>
  
  enum DelegateEvent {
    case didChangeAuthorizationStatus(CLAuthorizationStatus)
    case didUpdateLocations([CLLocation])
    case didFailWithError(Error)
  }
}

extension LocationClient {
  
  static var live: Self {
    
    class Delegate: NSObject, CLLocationManagerDelegate {
      var subject = PassthroughSubject<DelegateEvent, Never>()
    
      init(subject: PassthroughSubject<DelegateEvent, Never>) {
        self.subject = subject
      }
      
      func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        subject.send(.didChangeAuthorizationStatus(manager.authorizationStatus))
      }
      
      func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        subject.send(.didUpdateLocations(locations))
      }
      
      func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        subject.send(.didFailWithError(error))
      }
    }
    
    let locationManager = CLLocationManager()
    let subject = PassthroughSubject<DelegateEvent, Never>()
    var delegate: Delegate? = Delegate(subject: subject)
    locationManager.delegate = delegate
    
    return Self(
      requestLocation: locationManager.requestLocation,
      requestWhenInUseAuthorization: locationManager.requestWhenInUseAuthorization,
      authorizationStatus: { locationManager.authorizationStatus },
      delegate: subject
        .handleEvents(receiveCancel: { delegate = nil })
        .eraseToAnyPublisher()
    )
  }
  
}

public class AppViewModel: NSObject, ObservableObject {
  private let weatherClient: WeatherClient
  private let locationManager: CLLocationManager
  private let pathMonitorClient: PathMonitorClient
  private var pathUpdateCancellable: AnyCancellable?
  private var weatherRequestCancellable: AnyCancellable?
  private var searchLocationsCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var currentLocation: Location?
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  public init(
    weatherClient: WeatherClient,
    pathMonitorClient: PathMonitorClient,
    locationManager: CLLocationManager
  ) {
    self.weatherClient = weatherClient
    self.pathMonitorClient = pathMonitorClient
    self.locationManager = locationManager
    super.init()
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
    guard let location = self.currentLocation else { return }
    weatherResults = []
    weatherRequestCancellable = weatherClient
      .weather(location.woeid)
      .sink { _ in }
        receiveValue: { [weak self] in self?.weatherResults = $0.consolidatedWeather }
  }
  
  func locationButtonTapped() {
    locationManager.delegate = self
    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .restricted, .denied: break // TODO: show an alert
    case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation()
    @unknown default: break
    }
  }
}

extension AppViewModel: CLLocationManagerDelegate {
  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .notDetermined: break
    case .restricted, .denied: break // TODO: show an alert
    case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation()
    @unknown default: break
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else { return }
    searchLocationsCancellable = weatherClient
      .searchLocations(location.coordinate)
      .sink { _ in } receiveValue: { [weak self] locations in
        self?.currentLocation = locations.first
        self?.refreshWeather()
      }
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
            action: { self.viewModel.locationButtonTapped() }
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
      .navigationBarTitle(viewModel.currentLocation?.title ?? "Weather")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    return ContentView(viewModel: AppViewModel(weatherClient: .happyPath, pathMonitorClient: .satisfied, locationManager: CLLocationManager()))
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
