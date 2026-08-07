import Foundation

/// Météo instantanée du lieu (Open-Meteo, libre et sans clé).
struct WeatherNow: Codable, Hashable, Sendable {
    var temperature: Double
    var apparentTemperature: Double
    var windSpeed: Double
    var windDirection: Double
    var precipitation: Double
    var code: Int
    var minTemperature: Double?
    var maxTemperature: Double?

    var symbolName: String { WeatherCode.symbol(code) }
    var label: String { WeatherCode.label(code) }

    /// Direction du vent en rose des vents.
    var windCardinal: String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let index = Int((windDirection / 22.5).rounded()) % 16
        return points[(index + 16) % 16]
    }

    /// Force du vent sur l'échelle de Beaufort.
    var beaufort: Int {
        let knots = windSpeed / 1.852
        let limits: [Double] = [1, 3, 6, 10, 16, 21, 27, 33, 40, 47, 55, 63]
        for (i, limit) in limits.enumerated() where knots < limit { return i }
        return 12
    }
}

enum WeatherCode {
    static func label(_ code: Int) -> String {
        switch code {
        case 0: return "Ciel dégagé"
        case 1: return "Peu nuageux"
        case 2: return "Partiellement nuageux"
        case 3: return "Couvert"
        case 45, 48: return "Brouillard"
        case 51, 53, 55: return "Bruine"
        case 56, 57: return "Bruine verglaçante"
        case 61: return "Pluie faible"
        case 63: return "Pluie"
        case 65: return "Forte pluie"
        case 66, 67: return "Pluie verglaçante"
        case 71: return "Neige faible"
        case 73: return "Neige"
        case 75: return "Forte neige"
        case 77: return "Grains de neige"
        case 80, 81: return "Averses"
        case 82: return "Fortes averses"
        case 85, 86: return "Averses de neige"
        case 95: return "Orage"
        case 96, 99: return "Orage et grêle"
        default: return "—"
        }
    }

    static func symbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.min.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
}

enum WeatherService {
    static func fetch(place: Place) async throws -> WeatherNow {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", place.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", place.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m"),
            URLQueryItem(name: "daily", value: "temperature_2m_min,temperature_2m_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]
        guard let url = comps.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return WeatherNow(
            temperature: decoded.current.temperature_2m,
            apparentTemperature: decoded.current.apparent_temperature,
            windSpeed: decoded.current.wind_speed_10m,
            windDirection: decoded.current.wind_direction_10m,
            precipitation: decoded.current.precipitation,
            code: decoded.current.weather_code,
            minTemperature: decoded.daily?.temperature_2m_min.first ?? nil,
            maxTemperature: decoded.daily?.temperature_2m_max.first ?? nil)
    }
}

private struct ForecastResponse: Decodable {
    let current: Current
    let daily: Daily?

    struct Current: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let precipitation: Double
        let weather_code: Int
        let wind_speed_10m: Double
        let wind_direction_10m: Double
    }
    struct Daily: Decodable {
        let temperature_2m_min: [Double?]
        let temperature_2m_max: [Double?]
    }
}
