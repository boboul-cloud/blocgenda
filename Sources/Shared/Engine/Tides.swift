import Foundation

/// Une pleine mer ou une basse mer.
struct TideMark: Codable, Hashable, Identifiable, Sendable {
    var id: Date { date }
    var date: Date
    var height: Double     // en mètres au-dessus du niveau moyen
    var isHigh: Bool

    var label: String { isHigh ? "Pleine mer" : "Basse mer" }
    var symbol: String { isHigh ? "arrow.up.to.line" : "arrow.down.to.line" }
}

/// Courbe de marée d'une journée + extrêmes.
struct TideDay: Codable, Hashable, Sendable {
    var samples: [TideSample] = []
    var marks: [TideMark] = []
    var portName: String = ""
    var fetchedAt: Date = Date()

    struct TideSample: Codable, Hashable, Sendable {
        var date: Date
        var height: Double
    }

    var isEmpty: Bool { samples.isEmpty }

    /// Marnage : plus haute pleine mer − plus basse basse mer, sur l'ensemble
    /// de la période récupérée.
    var range: Double? { Self.range(of: marks) }

    /// Marnage d'une journée précise — celui qu'il faut afficher à côté des
    /// marées de cette journée, sous peine d'annoncer un chiffre qui ne
    /// correspond à aucune des heures listées.
    func range(on day: Date) -> Double? {
        Self.range(of: marks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) })
    }

    private static func range(of marks: [TideMark]) -> Double? {
        guard let hi = marks.filter({ $0.isHigh }).map(\.height).max(),
              let lo = marks.filter({ !$0.isHigh }).map(\.height).min() else { return nil }
        return hi - lo
    }

    func height(at date: Date) -> Double? {
        guard let first = samples.first, let last = samples.last,
              date >= first.date, date <= last.date else { return nil }
        for i in 0..<(samples.count - 1) {
            let a = samples[i], b = samples[i + 1]
            if date >= a.date && date <= b.date {
                let t = date.timeIntervalSince(a.date) / max(1, b.date.timeIntervalSince(a.date))
                return a.height + (b.height - a.height) * t
            }
        }
        return last.height
    }

    /// Sens de la marée à l'instant donné : montante ou descendante.
    func isRising(at date: Date) -> Bool? {
        guard let next = marks.first(where: { $0.date > date }) else { return nil }
        return next.isHigh
    }

    /// Règle des douzièmes : fraction du marnage écoulée depuis la dernière étale.
    func progress(at date: Date) -> Double? {
        guard let previous = marks.last(where: { $0.date <= date }),
              let next = marks.first(where: { $0.date > date }) else { return nil }
        let total = next.date.timeIntervalSince(previous.date)
        guard total > 0 else { return nil }
        return date.timeIntervalSince(previous.date) / total
    }
}

/// Récupération des marées via l'API Marine d'Open-Meteo (libre, sans clé).
/// La hauteur renvoyée est le niveau de la mer par rapport au niveau moyen.
enum TideService {

    enum TideError: LocalizedError {
        case network(String)
        case noCoverage

        var errorDescription: String? {
            switch self {
            case .network(let m): return m
            case .noCoverage:
                return "Pas de données de marée pour ce point. Choisissez un port de référence."
            }
        }
    }

    static func fetch(place: Place, days: Int = 3) async throws -> TideDay {
        var comps = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", place.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", place.longitude)),
            URLQueryItem(name: "hourly", value: "sea_level_height_msl"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(days)),
            URLQueryItem(name: "past_days", value: "1")
        ]
        guard let url = comps.url else { throw TideError.network("URL invalide") }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw TideError.network("Réponse invalide") }
        guard http.statusCode == 200 else {
            // Open-Meteo répond 400 hors couverture maritime.
            throw TideError.noCoverage
        }

        let decoded = try JSONDecoder().decode(MarineResponse.self, from: data)
        let offset = TimeInterval(decoded.utc_offset_seconds ?? 0)
        var samples: [TideDay.TideSample] = []
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]

        for (i, stamp) in decoded.hourly.time.enumerated() {
            guard i < decoded.hourly.sea_level_height_msl.count,
                  let h = decoded.hourly.sea_level_height_msl[i] else { continue }
            guard let date = parse(stamp, offset: offset) else { continue }
            samples.append(.init(date: date, height: h))
        }
        guard samples.count > 6 else { throw TideError.noCoverage }

        var day = TideDay()
        day.samples = samples.sorted { $0.date < $1.date }
        day.marks = extrema(from: day.samples)
        day.portName = place.name
        return day
    }

    private static func parse(_ stamp: String, offset: TimeInterval) -> Date? {
        // Open-Meteo renvoie "2026-08-07T14:00" en heure locale du lieu.
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.timeZone = TimeZone(secondsFromGMT: Int(offset))
        return f.date(from: stamp)
    }

    /// Détection des pleines et basses mers par interpolation parabolique
    /// autour des extrêmes locaux de la série horaire.
    static func extrema(from samples: [TideDay.TideSample]) -> [TideMark] {
        guard samples.count > 2 else { return [] }
        var marks: [TideMark] = []
        for i in 1..<(samples.count - 1) {
            let a = samples[i - 1].height, b = samples[i].height, c = samples[i + 1].height
            let isMax = b >= a && b >= c && (b > a || b > c)
            let isMin = b <= a && b <= c && (b < a || b < c)
            guard isMax || isMin else { continue }

            // Sommet de la parabole passant par les trois points.
            let denom = (a - 2 * b + c)
            let shift = abs(denom) < 1e-9 ? 0 : 0.5 * (a - c) / denom
            let peak = b - 0.25 * (a - c) * shift
            let interval = samples[i + 1].date.timeIntervalSince(samples[i].date)
            let date = samples[i].date.addingTimeInterval(shift * interval)
            marks.append(TideMark(date: date, height: peak, isHigh: isMax))
        }
        return deduplicated(marks)
    }

    /// Une étale qui s'étale sur deux relevés horaires de même hauteur est
    /// détectée deux fois. Or deux marées de même sens sont séparées d'environ
    /// douze heures : tout doublon à moins de trois heures est un artefact.
    /// On garde le plus marqué des deux.
    static func deduplicated(_ marks: [TideMark]) -> [TideMark] {
        var result: [TideMark] = []
        for mark in marks.sorted(by: { $0.date < $1.date }) {
            guard let last = result.last,
                  last.isHigh == mark.isHigh,
                  mark.date.timeIntervalSince(last.date) < 3 * 3600 else {
                result.append(mark)
                continue
            }
            let keepNew = mark.isHigh ? mark.height > last.height : mark.height < last.height
            if keepNew { result[result.count - 1] = mark }
        }
        return result
    }

    /// Coefficient de marée estimé (échelle française 20–120) à partir du
    /// marnage du jour rapporté au marnage maximal observé sur la période.
    /// Valeur indicative : les coefficients officiels sont ceux du SHOM.
    static func estimatedCoefficient(range: Double, referenceMax: Double) -> Int? {
        guard range > 0, referenceMax > 0 else { return nil }
        let ratio = range / referenceMax
        return Int((ratio * 105).rounded().clamped(to: 20...120))
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Décodage Open-Meteo

private struct MarineResponse: Decodable {
    let utc_offset_seconds: Int?
    let hourly: Hourly

    struct Hourly: Decodable {
        let time: [String]
        let sea_level_height_msl: [Double?]
    }
}
