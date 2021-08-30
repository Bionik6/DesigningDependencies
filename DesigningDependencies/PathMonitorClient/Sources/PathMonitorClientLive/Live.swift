import Network
import Combine
import PathMonitorClient


extension PathMonitorClient {
  
  public static func live(queue: DispatchQueue) -> Self {
    let monitor = NWPathMonitor()
    let subject = PassthroughSubject<NWPath, Never>()
    monitor.pathUpdateHandler = subject.send
    monitor.start(queue: queue)
    
    return Self(
     networkPublisher: subject
      .handleEvents(receiveSubscription: { _ in monitor.start(queue: queue) }, receiveCancel: monitor.cancel)
      .map(NetworkPath.init(rawValue:))
      .eraseToAnyPublisher()
    )
  }
  
}
