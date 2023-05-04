import Foundation

public enum Loadable<T: Equatable>: Equatable {
    case loading
    case value(T)
    case idle
    case error(String)
}

public struct Place: Equatable, Identifiable, Decodable {
    public var id: String {
        "\(lat)\(lon)"
    }
    public var queryString: String {
        "\(name), \(country)"
    }
    
    public var name: String
    public var country: String
    public var lat: Float
    public var lon: Float
}

public struct WeatherResponse: Codable, Equatable {
    public let coord: Coord
    public let weather: [Weather]
    public let main: Main
    public let name: String
}

public struct Coord: Codable, Equatable {
    public let lon: Double
    public let lat: Double
}

public struct Weather: Codable, Equatable, Identifiable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String
    
    public var iconURL: URL? {
        // handling different scales dynamically would be a nice improvement
        URL(string: "\(API.iconImage)\(icon)@2x.png")
    }
}

public struct Main: Codable, Equatable {
    public let temp: Double
    public let pressure: Int
    public let humidity: Int
    public let temp_min: Double
    public let temp_max: Double
}

public enum Mock {
    static func place(count: Int) -> [Place] {
        return (0..<count).map{ _ in Place.init(name: text(1), country: text(1), lat: coordinate, lon: coordinate) }
    }
    
    static func weatherResponse(
        coord: Coord = coord(),
        weather: [Weather] = [weather()],
        main: Main = main(),
        name: String = text(1)
    ) -> WeatherResponse {
        WeatherResponse(
            coord: coord,
            weather: weather,
            main: main,
            name: name
        )
    }
    
    static func coord(lon: Double = 123.0123, lat: Double = 123.3) -> Coord {
        Coord(lon: lon, lat: lat)
    }
    
    static func weather(
        id: Int = 1,
        main: String = text(1),
        description: String = text(1),
        icon: String = text(1)
    ) -> Weather {
        Weather(id: id, main: main, description: description, icon: icon)
    }
    
    static func main(temp: Double = 1, pressure: Int = 2, humidity: Int = 4, temp_min: Double = 5, temp_max: Double = 6) -> Main {
        Main(temp: temp, pressure: pressure, humidity: humidity, temp_min: temp_min, temp_max: temp_max)
    }
            
    static func text(_ count: Int) -> String {
        let max = Int(lorem.count)
        let wordCount = min(count, max)
        let string = lorem.prefix(Int(wordCount))
        return string.joined(separator: " ").capitalized
    }
    
    static var coordinate: Float {
        Float.random(in: -200.0..<200)
    }
}

let lorem = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
""".components(separatedBy: " ")

