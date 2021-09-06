// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "WeatherClient",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "WeatherClient",targets: ["WeatherClient"]),
    .library(name: "WeatherClientLive", targets: ["WeatherClientLive"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "WeatherClient", dependencies: []),
    .target(name: "WeatherClientLive", dependencies: ["WeatherClient"]),
    .testTarget(name: "WeatherClientTests", dependencies: ["WeatherClient"]),
  ]
)
