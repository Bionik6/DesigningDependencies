import Combine
import Foundation
import CoreLocation

public struct LocationClient {
  public var requestLocation: () -> Void
  public var requestWhenInUseAuthorization: () -> Void
  public var authorizationStatus: () -> CLAuthorizationStatus
  public var delegate: AnyPublisher<DelegateEvent, Never>
  
  public init(
    requestLocation: @escaping () -> Void,
    requestWhenInUseAuthorization: @escaping () -> Void,
    authorizationStatus: @escaping () -> CLAuthorizationStatus,
    delegate: AnyPublisher<DelegateEvent, Never>
  ) {
    self.requestLocation = requestLocation
    self.requestWhenInUseAuthorization = requestWhenInUseAuthorization
    self.authorizationStatus = authorizationStatus
    self.delegate = delegate
  }
  
  public enum DelegateEvent {
    case didChangeAuthorizationStatus(CLAuthorizationStatus)
    case didUpdateLocations([CLLocation])
    case didFailWithError(Error)
  }
}
