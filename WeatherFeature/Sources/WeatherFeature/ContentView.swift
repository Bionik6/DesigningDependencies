import SwiftUI
import Combine
import CoreLocation
import WeatherClient
import PathMonitorClient


public struct LocationClient {
  var requestLocation: () -> Void
  var requestWhenInUseAuthorization: () -> Void
  var authorizationStatus: () -> CLAuthorizationStatus
  var delegate: AnyPublisher<DelegateEvent, Never>
  
  enum DelegateEvent {
    case didChangeAuthorizationStatus(CLAuthorizationStatus)
    case didUpdateLocations([CLLocation])
    case didFailWithError(Error)
  }
}

extension LocationClient {
  
  public static var live: Self {
    
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

extension LocationClient {
  
  static var authorizedWhenInUse: Self {
    let subject = PassthroughSubject<DelegateEvent, Never>()
    return Self(
      requestLocation: { subject.send(.didUpdateLocations([CLLocation()])) },
      requestWhenInUseAuthorization: { },
      authorizationStatus: { .authorizedWhenInUse },
      delegate: subject.eraseToAnyPublisher()
    )
  }
  
  static var notDetermined: Self {
    var status = CLAuthorizationStatus.notDetermined
    let subject = PassthroughSubject<DelegateEvent, Never>()
    return Self(
      requestLocation: { subject.send(.didUpdateLocations([CLLocation()])) },
      requestWhenInUseAuthorization: {
        status = .authorizedWhenInUse
        subject.send(.didChangeAuthorizationStatus(status))
      },
      authorizationStatus: { status },
      delegate: subject.eraseToAnyPublisher()
    )
  }
  
  static var notDeterminedDenied: Self {
    var status = CLAuthorizationStatus.notDetermined
    let subject = PassthroughSubject<DelegateEvent, Never>()
    return Self(
      requestLocation: { subject.send(.didUpdateLocations([CLLocation()])) },
      requestWhenInUseAuthorization: {
        status = .denied
        subject.send(.didChangeAuthorizationStatus(status))
      },
      authorizationStatus: { status },
      delegate: subject.eraseToAnyPublisher()
    )
  }
  
}


public class AppViewModel: ObservableObject {
  private let weatherClient: WeatherClient
  private let locationClient: LocationClient
  private let pathMonitorClient: PathMonitorClient
  private var pathUpdateCancellable: AnyCancellable?
  private var weatherRequestCancellable: AnyCancellable?
  private var searchLocationsCancellable: AnyCancellable?
  private var locationDelegateCancellable: AnyCancellable?
  
  @Published var isConnected = true
  @Published var currentLocation: Location?
  @Published var weatherResults: [WeatherResponse.ConsolidatedWeather] = []
  
  public init(
    weatherClient: WeatherClient,
    pathMonitorClient: PathMonitorClient,
    locationClient: LocationClient
  ) {
    self.weatherClient = weatherClient
    self.pathMonitorClient = pathMonitorClient
    self.locationClient = locationClient
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
    
    
    locationDelegateCancellable = locationClient.delegate
      .sink { [weak self] event in
        switch event {
        case .didChangeAuthorizationStatus(let status):
          switch status {
          case .notDetermined: break
          case .restricted, .denied: break // TODO: show an alert
          case .authorizedAlways, .authorizedWhenInUse: locationClient.requestLocation()
          @unknown default: break
          }
        case .didUpdateLocations(let locations):
          guard let location = locations.first else { return }
          self?.searchLocationsCancellable = weatherClient
            .searchLocations(location.coordinate)
            .sink { _ in } receiveValue: { [weak self] locations in
              self?.currentLocation = locations.first
              self?.refreshWeather()
            }
        case .didFailWithError(_):
          break
        }
      }
    
    if self.locationClient.authorizationStatus() == .authorizedWhenInUse {
      self.locationClient.requestLocation()
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
    switch locationClient.authorizationStatus() {
    case .notDetermined:
      locationClient.requestWhenInUseAuthorization()
    case .restricted, .denied: break // TODO: show an alert
    case .authorizedAlways, .authorizedWhenInUse: locationClient.requestLocation()
    @unknown default: break
    }
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
                Text("Current temp: \(weather.theTemp, specifier: "%.1f")°C").bold()
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
    return ContentView(
      viewModel: AppViewModel(
        weatherClient: .happyPath,
        pathMonitorClient: .satisfied,
        locationClient: .notDeterminedDenied
      )
    )
  }
}

let dayOfWeekFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "EEEE"
  return formatter
}()
