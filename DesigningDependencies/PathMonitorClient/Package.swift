// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PathMonitorClient",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "PathMonitorClient", targets: ["PathMonitorClient"]),
  ],
  dependencies: [
    
  ],
  targets: [
    .target(name: "PathMonitorClient", dependencies: []),
    .testTarget(name: "PathMonitorClientTests", dependencies: ["PathMonitorClient"]),
  ]
)
