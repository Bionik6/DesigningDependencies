import Combine
import Foundation
import CoreLocation

extension LocationClient {
  
  public static var authorizedWhenInUse: Self {
    let subject = PassthroughSubject<DelegateEvent, Never>()
    return Self(
      requestLocation: { subject.send(.didUpdateLocations([CLLocation()])) },
      requestWhenInUseAuthorization: { },
      authorizationStatus: { .authorizedWhenInUse },
      delegate: subject.eraseToAnyPublisher()
    )
  }
  
  public static var notDetermined: Self {
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
  
  public static var notDeterminedDenied: Self {
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
