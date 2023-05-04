import ComposableArchitecture
import Foundation

//IMPROVEMENT: consider seperating this into specialized services, for search, weather, and persistence.
protocol ClientProtocol {
    func search(input: String) async throws -> [Place]
    func fetchWeatherResponse(city: String) async throws -> WeatherResponse
    func fetchWeatherResponse(lat: Double, lon: Double) async throws -> WeatherResponse
    func saveWeatherResponse(response: WeatherResponse)
    func loadLastWeatherResponse() -> WeatherResponse?
}

//IMPROVEMENT: store the api key in a more secure way, perhaps in keyChain
let apiKey = "YOUR_API_KEY"

//IMPROVEMENT: consider using a different persistence for the data, like Core Data, Realm, or even directly on disk
let savedObjectKey = "com.weather.saved.weatherresponse"

public enum API {
    static var weather = "https://api.openweathermap.org/data/2.5/weather"
    static var search = "https://api.openweathermap.org/geo/1.0/direct"
    static var reverse = "https://api.openweathermap.org/geo/1.0/reverse"
    static var iconImage = "https://openweathermap.org/img/wn/"
}

class Client: ClientProtocol {
    func search(input: String) async throws -> [Place] {
        guard !input.isEmpty else { return [] }
        guard var components = URLComponents(string: API.search) else {
            assertionFailure("invalid path")
            return []
        }
        
        components.queryItems = [
            URLQueryItem(name: "q", value: input),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "appid", value: apiKey),
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([Place].self, from: data)
    }
    
    public func fetchWeatherResponse(city: String) async throws -> WeatherResponse {
        guard !city.isEmpty else { throw ClientError.emptyInput }
        guard var components = URLComponents(string: API.weather) else {
            assertionFailure("invalid path")
            throw ClientError.emptyInput
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "units", value: "imperial"),
            URLQueryItem(name: "appid", value: apiKey),
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
    
    public func fetchWeatherResponse(lat: Double, lon: Double) async throws -> WeatherResponse {
        guard var components = URLComponents(string: API.reverse) else {
            assertionFailure("invalid path")
            throw ClientError.emptyInput
        }

        components.queryItems = [
            URLQueryItem(name: "lat", value: lat.description),
            URLQueryItem(name: "lon", value: lon.description),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "appid", value: apiKey),
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        guard let place = try JSONDecoder().decode([Place].self, from: data).first else {
            throw ClientError.emptyInput
        }
        return try await fetchWeatherResponse(city: place.queryString)
    }
    
    public func saveWeatherResponse(response: WeatherResponse) {
        if let encoded = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(encoded, forKey: savedObjectKey)
        }
    }
    
    public func loadLastWeatherResponse() -> WeatherResponse? {
        guard
            let encoded = UserDefaults.standard.object(forKey: savedObjectKey) as? Data,
            let response = try? JSONDecoder().decode(WeatherResponse.self, from: encoded)
        else {
            return nil
        }
        return response
    }
}

enum ClientError: Error {
    case emptyInput
}

class MockClient: ClientProtocol {
    public var search: ((String) async throws -> [Place])?
    public var weatherResponse: (()-> WeatherResponse?)?
    
    public func search(input: String) async throws -> [Place] {
        try await search?(input) ?? []
    }
    
    public func fetchWeatherResponse(city: String) async throws -> WeatherResponse {
        Mock.weatherResponse()
    }
    
    public func fetchWeatherResponse(lat: Double, lon: Double) async throws -> WeatherResponse {
        Mock.weatherResponse()
    }
    
    public func saveWeatherResponse(response: WeatherResponse) {
        // stub
    }
    
    public func loadLastWeatherResponse() -> WeatherResponse? {
        weatherResponse?()
    }
}


extension Client {
    public static var live: ClientProtocol = Client()
    public static var mock: ClientProtocol = MockClient()
}

private enum SearchClientKey: DependencyKey {
    static let liveValue = Client.live
    static let previewValue = Client.mock
    static let testValue = Client.mock
}

extension DependencyValues {
  var searchClient: ClientProtocol {
      get { self[SearchClientKey.self] }
      set { self[SearchClientKey.self] = newValue }
  }
}
