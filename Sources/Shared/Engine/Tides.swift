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
    /// Correction de phase appliquée, en minutes, et station qui l'a fournie.
    /// Absent : aucune calibration ne couvre ce lieu, les heures sont celles du
    /// modèle, brutes. Optionnels à dessein — la clé manque dans les fichiers
    /// écrits par une version antérieure, et un champ sec ferait échouer toute
    /// la relecture.
    var phaseCorrectionMinutes: Int? = nil
    var phaseCorrectionStation: String? = nil

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

/// Recalage des heures de marée sur les annuaires officiels.
///
/// Les hauteurs viennent du modèle océanique global SMOC de Météo-France, servi
/// par Open-Meteo, dont la maille fait environ huit kilomètres. Ce modèle ne
/// résout pas le port : pour Brest, la maille interrogée tombe à une dizaine de
/// kilomètres au large, et Open-Meteo prévient que ces données ne conviennent
/// pas à la navigation côtière.
///
/// Il en résulte une **avance systématique** : la comparaison de la série du
/// modèle aux annuaires officiels, sur douze marées par port, donne une avance
/// médiane de vingt-neuf à cinquante-cinq minutes selon le port, très stable
/// d'une marée à l'autre. On la rattrape ici, comme un annuaire rattache un
/// port secondaire à un port de référence.
///
/// Ce que ce recalage ne fait pas : corriger les hauteurs, ni la dispersion
/// résiduelle — de deux à dix-huit minutes selon la station. Les heures
/// restent indicatives, et l'application le dit.
enum TidePhase {

    /// Station calibrée : le décalage mesuré et sa dispersion, en minutes.
    struct Station: Sendable {
        let name: String
        let latitude: Double
        let longitude: Double
        /// Minutes à ajouter aux heures du modèle.
        let minutes: Int
        /// Écart-type observé, pour dire honnêtement la précision atteinte.
        let spread: Int
    }

    /// Mesures du 8 août 2026, sur les marées du 8 au 11 août, référence
    /// tide-forecast.com. À refaire si les heures se remettent à dériver :
    /// voir `Tools/EngineTests` pour la marche à suivre.
    static let stations: [Station] = [
        Station(name: "Dunkerque",   latitude: 51.0350, longitude:  2.3770, minutes: 46, spread: 15),
        Station(name: "Dieppe",      latitude: 49.9260, longitude:  1.0780, minutes: 31, spread:  5),
        Station(name: "Cherbourg",   latitude: 49.6500, longitude: -1.6167, minutes: 46, spread:  7),
        Station(name: "Saint-Malo",  latitude: 48.6493, longitude: -2.0257, minutes: 47, spread: 10),
        Station(name: "Roscoff",     latitude: 48.7240, longitude: -3.9860, minutes: 55, spread:  4),
        Station(name: "Brest",       latitude: 48.3833, longitude: -4.4950, minutes: 52, spread:  4),
        Station(name: "Concarneau",  latitude: 47.8720, longitude: -3.9200, minutes: 29, spread:  2),
        Station(name: "Lorient",     latitude: 47.7280, longitude: -3.3670, minutes: 36, spread:  4),
        Station(name: "La Rochelle", latitude: 46.1590, longitude: -1.1510, minutes: 51, spread: 18),
    ]

    /// Au-delà de cette distance, on ne corrige rien : le décalage est propre à
    /// la façon dont le modèle représente une côte donnée, et rien ne dit qu'il
    /// vaille ailleurs. La Méditerranée, où le marnage se compte en centimètres,
    /// et l'outre-mer restent donc sur les heures brutes.
    static let maxDistanceKm = 200.0

    /// La station calibrée la plus proche, si elle est assez proche pour valoir.
    static func station(for latitude: Double, longitude: Double) -> Station? {
        let nearest = stations.min {
            distanceKm(latitude, longitude, $0.latitude, $0.longitude)
                < distanceKm(latitude, longitude, $1.latitude, $1.longitude)
        }
        guard let nearest,
              distanceKm(latitude, longitude, nearest.latitude, nearest.longitude) <= maxDistanceKm
        else { return nil }
        return nearest
    }

    static func distanceKm(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = (lat1 - lat2) * 111.0
        let dLon = (lon1 - lon2) * 111.0 * cos((lat1 + lat2) / 2 * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }
}

/// Récupération des marées via l'API Marine d'Open-Meteo (libre, sans clé).
/// La hauteur renvoyée est le niveau de la mer par rapport au niveau moyen.
enum TideService {

    enum TideError: LocalizedError {
        case network(String)
        case noCoverage
        /// Le rafraîchissement a été interrompu — on a quitté l'écran, ou le
        /// geste de tirer la liste a été relâché. Ce n'est pas une panne : il
        /// ne faut ni le dire ni jeter ce qui était déjà affiché.
        case cancelled

        var errorDescription: String? {
            switch self {
            case .network(let m): return m
            case .noCoverage:
                return "Pas de données de marée pour ce point. Choisissez un port de référence."
            case .cancelled:
                return "Relevé interrompu."
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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch let error as URLError where error.code == .cancelled {
            throw TideError.cancelled
        } catch is CancellationError {
            throw TideError.cancelled
        } catch {
            throw TideError.network("Marées : \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse else { throw TideError.network("Réponse invalide") }
        guard http.statusCode == 200 else {
            // Tout ce qui n'est pas 200 était rangé sous « hors couverture », ce
            // qui envoyait chercher un port de repli — et faisait un second appel
            // condamné — là où le réseau ou le service était simplement en
            // défaut. Open-Meteo dit la raison, on la reprend telle quelle.
            let reason = (try? JSONDecoder().decode(MarineError.self, from: data))?.reason
            throw TideError.network(reason.map { "Marées : \($0)" }
                                    ?? "Marées indisponibles (erreur \(http.statusCode)).")
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

        // Recalage sur les annuaires officiels. La courbe est décalée avec les
        // étales : sans cela, la hauteur lue à une heure donnée ne
        // correspondrait plus aux pleines et basses mers affichées juste à côté.
        let station = TidePhase.station(for: place.latitude, longitude: place.longitude)
        if let station {
            let shift = TimeInterval(station.minutes * 60)
            samples = samples.map { .init(date: $0.date.addingTimeInterval(shift), height: $0.height) }
        }

        var day = TideDay()
        day.samples = samples.sorted { $0.date < $1.date }
        day.marks = extrema(from: day.samples)
        day.portName = place.name
        day.phaseCorrectionMinutes = station?.minutes
        day.phaseCorrectionStation = station?.name
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

/// Le corps d'erreur d'Open-Meteo : `{"error":true,"reason":"…"}`.
private struct MarineError: Decodable {
    let reason: String
}

private struct MarineResponse: Decodable {
    let utc_offset_seconds: Int?
    let hourly: Hourly

    struct Hourly: Decodable {
        let time: [String]
        let sea_level_height_msl: [Double?]
    }
}
