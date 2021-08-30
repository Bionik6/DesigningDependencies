// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "WeatherFeature",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "WeatherFeature", targets: ["WeatherFeature"]),
  ],
  dependencies: [
    .package(name: "WeatherClient", path: "WeatherClient"),
    .package(name: "PathMonitorClient", path: "PathMonitorClient"),
  ],
  targets: [
    .target(name: "WeatherFeature", dependencies: ["WeatherClient", "PathMonitorClient"]),
    .testTarget(name: "WeatherFeatureTests", dependencies: ["WeatherFeature"]),
  ]
)
