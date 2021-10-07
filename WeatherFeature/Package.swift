// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "WeatherFeature",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "WeatherFeature", targets: ["WeatherFeature"]),
  ],
  dependencies: [
    .package(name: "WeatherClient", path: "WeatherClient"),
    .package(name: "PathMonitorClient", path: "PathMonitorClient"),
    .package(name: "LocationClient", path: "LocationClient"),
  ],
  targets: [
    .target(name: "WeatherFeature", dependencies: ["WeatherClient", "PathMonitorClient"]),
    .testTarget(name: "WeatherFeatureTests", dependencies: ["WeatherFeature", "LocationClient"]),
  ]
)
