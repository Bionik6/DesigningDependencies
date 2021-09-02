import Foundation
import WeatherClient

extension WeatherClient {
  public static let live = Self(weather: { id in 
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.metaweather.com/api/location/\(id)")!)
      .map { data, _ in data }
      .decode(type: WeatherResponse.self, decoder: weatherJsonDecoder)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }, searchLocations:  { coordinates in
    fatalError()
  })
}


private let weatherJsonDecoder: JSONDecoder = {
  let jsonDecoder = JSONDecoder()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  jsonDecoder.dateDecodingStrategy = .formatted(formatter)
  jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
  return jsonDecoder
}()


public let __tmp0 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp1 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp2 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp3 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp4 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp5 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp6 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp7 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp8 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp10 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp11 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp12 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp13 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp14 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp15 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp16 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp17 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp18 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp19 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp20 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp21 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp22 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp23 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp24 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp25 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp26 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp27 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp28 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp29 = 2 * 2 * 2 * 2.0 / 2 + 2
public let __tmp30 = 2 * 2 * 2 * 2.0 / 2 + 2
