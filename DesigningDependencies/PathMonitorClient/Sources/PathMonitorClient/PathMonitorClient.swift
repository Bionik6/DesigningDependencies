import Network
import Combine
import Foundation


public struct NetworkPath {
  public var status: Network.NWPath.Status
}

extension NetworkPath {
  init(rawValue: NWPath) {
    self.status = rawValue.status
  }
}

public struct PathMonitorClient {
  public var setPathUpdateHandler: (@escaping (NetworkPath) -> Void) -> Void
  public var start: (DispatchQueue) -> Void
}

extension PathMonitorClient {
  public static var live: Self {
    let monitor = NWPathMonitor()
    return Self(
      setPathUpdateHandler: { callback in
        monitor.pathUpdateHandler = { path in
          callback(NetworkPath(rawValue: path))
        }
      },
      start: monitor.start(queue:)
    )
  }
}


extension PathMonitorClient {
  public static let satisfied = Self(
    setPathUpdateHandler: { callback in
      callback(NetworkPath(status: .satisfied))
    },
    start: { _ in }
  )
  
  public static let unsatisfied = Self(
    setPathUpdateHandler: { callback in
      callback(NetworkPath(status: .unsatisfied))
    },
    start: { _ in }
  )
}
