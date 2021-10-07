// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "WeatherClient",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: "WeatherClient", targets: ["WeatherClient"]),
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
