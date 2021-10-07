// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "PathMonitorClient",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "PathMonitorClient", targets: ["PathMonitorClient"]),
    .library(name: "PathMonitorClientLive", targets: ["PathMonitorClientLive"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "PathMonitorClient", dependencies: []),
    .target(name: "PathMonitorClientLive", dependencies: ["PathMonitorClient"]),
    .testTarget(name: "PathMonitorClientTests", dependencies: ["PathMonitorClient"]),
  ]
)
