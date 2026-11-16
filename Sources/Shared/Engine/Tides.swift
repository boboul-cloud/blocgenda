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
    /// Le point interrogé — pas toujours le lieu affiché en haut de l'écran :
    /// c'est celui du port de marée. Il dit si le coefficient a cours ici.
    /// Optionnels pour la même raison que ci-dessus.
    var latitude: Double? = nil
    var longitude: Double? = nil

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

    /// Les coefficients de la journée, un par pleine mer, comme dans un
    /// annuaire. Vide là où le coefficient n'a pas cours.
    func coefficients(on day: Date) -> [Int] {
        guard let latitude, let longitude,
              TideCoefficient.applies(latitude: latitude, longitude: longitude) else { return [] }
        return marks
            .filter { $0.isHigh && Calendar.current.isDate($0.date, inSameDayAs: day) }
            .map { TideCoefficient.value(at: $0.date) }
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
        day.latitude = place.latitude
        day.longitude = place.longitude
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

}

/// Le coefficient de marée, échelle française de 20 à 120.
///
/// Ce n'est pas une hauteur : c'est le marnage rapporté à celui d'une vive-eau
/// moyenne d'équinoxe, qui vaut 100 par définition. La même valeur vaut pour
/// toute la côte — le SHOM la calcule à Brest, les annuaires la reprennent
/// telle quelle de Dunkerque à Hendaye.
///
/// On la calcule ici sans réseau, à partir des positions du soleil et de la
/// lune. Le marnage suit l'amplitude de la marée d'équilibre semi-diurne :
/// chaque astre pèse comme le cube inverse de sa distance et le carré du
/// cosinus de sa déclinaison, et les deux se composent selon le double de leur
/// écart en ascension droite — en phase aux syzygies, opposés aux quadratures.
///
/// Deux constantes ne viennent pas de la théorie mais des faits :
///
/// - **l'âge de la marée**, un jour et demi : l'océan ne répond pas à l'instant
///   à ce que les astres lui demandent, et la plus forte marée suit la nouvelle
///   ou la pleine lune de deux jours environ ;
/// - **le poids du soleil**, 0,372 fois celui de la lune, quand la théorie de
///   l'équilibre dit 0,46 : c'est le rapport observé sur la façade atlantique.
///
/// Les deux ont été ajustés sur les coefficients officiels de 2015, 2024, 2025
/// et 2026 — mille quatre cent soixante et un jours. L'écart type tombe alors à
/// **1,5 point**, avec 96 % des journées à moins de trois points et jamais plus
/// de six. C'est une estimation ; pour naviguer, l'annuaire du SHOM fait foi.
enum TideCoefficient {

    /// Retard de l'océan sur les astres, en jours.
    static let ageOfTide = 1.566
    /// Force de la marée solaire, celle de la lune valant 1.
    static let solarWeight = 0.3716
    /// Ce qui porte la vive-eau moyenne d'équinoxe à 100.
    static let scale = 98.805

    static let bounds = 20...120

    /// Le coefficient à un instant donné — en pratique, l'heure d'une pleine mer.
    static func value(at date: Date) -> Int {
        // On interroge le ciel tel qu'il était un jour et demi plus tôt : c'est
        // à cette marée-là que la mer d'aujourd'hui répond.
        let d = Astro.toDays(date.addingTimeInterval(-ageOfTide * 86_400))
        let moon = Astro.moonCoordsFine(d)
        let sun = Astro.sunCoords(d)

        let lunar = pow(Astro.meanMoonDistance / moon.dist, 3) * pow(cos(moon.dec), 2)
        let solar = solarWeight * pow(1 / Astro.sunDistanceAU(d), 3) * pow(cos(sun.dec), 2)
        let phase = 2 * (moon.ra - sun.ra)
        let amplitude = (lunar * lunar + solar * solar
                         + 2 * lunar * solar * cos(phase)).squareRoot()

        let coefficient = scale * amplitude / (1 + solarWeight)
        return Int(coefficient.rounded().clamped(to: Double(bounds.lowerBound)...Double(bounds.upperBound)))
    }

    /// Ce que le chiffre veut dire, dans les termes des annuaires.
    static func label(for coefficient: Int) -> String {
        switch coefficient {
        case 95...: return "grande marée"
        case 70...: return "vive-eau"
        default: return "morte-eau"
        }
    }

    /// Le coefficient est une convention française : il n'a cours que sur la
    /// façade Manche–Atlantique, où il a été établi. En Méditerranée, où le
    /// marnage se compte en centimètres, et outre-mer, il ne veut rien dire —
    /// on n'en affiche donc aucun. La boîte va d'Hendaye à Dunkerque et laisse
    /// dehors le golfe du Lion, dont la côte commence au-delà de 3° est.
    static func applies(latitude: Double, longitude: Double) -> Bool {
        (43.2...51.2).contains(latitude) && (-6.0...2.7).contains(longitude)
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
