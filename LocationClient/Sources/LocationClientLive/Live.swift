import Combine
import Foundation
import CoreLocation
import LocationClient

extension LocationClient {
  
  public static var live: Self {
    
    class Delegate: NSObject, CLLocationManagerDelegate {
      var subject: PassthroughSubject<DelegateEvent, Never>
      
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
