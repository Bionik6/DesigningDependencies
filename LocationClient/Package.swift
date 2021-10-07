// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "LocationClient",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "LocationClient", targets: ["LocationClient"]),
    .library(name: "LocationClientLive", targets: ["LocationClientLive"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "LocationClient", dependencies: []),
    .target(name: "LocationClientLive", dependencies: ["LocationClient"]),
    .testTarget(name: "LocationClientTests", dependencies: ["LocationClient"]),
  ]
)
