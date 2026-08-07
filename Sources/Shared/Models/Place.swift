import Foundation

/// Le lieu de référence pour l'éphéméride : position GPS ou port choisi à la main.
struct Place: Codable, Hashable, Identifiable, Sendable {
    var id: String { "\(name)|\(latitude)|\(longitude)" }
    var name: String
    var latitude: Double
    var longitude: Double
    /// Vrai si la position vient du GPS (elle sera rafraîchie automatiquement).
    var isAutomatic: Bool = false

    static let paris = Place(name: "Paris", latitude: 48.8566, longitude: 2.3522)

    var shortCoordinates: String {
        let ns = latitude >= 0 ? "N" : "S"
        let ew = longitude >= 0 ? "E" : "O"
        return String(format: "%.2f° %@  %.2f° %@", abs(latitude), ns, abs(longitude), ew)
    }
}

/// Quelques ports de référence, pour les marées quand on n'est pas sur la côte
/// ou qu'on prépare un déplacement.
enum ReferencePorts {
    static let all: [Place] = [
        Place(name: "Brest", latitude: 48.3833, longitude: -4.4950),
        Place(name: "Portsall", latitude: 48.5639, longitude: -4.7139),
        Place(name: "Le Conquet", latitude: 48.3600, longitude: -4.7700),
        Place(name: "L’Aber-Wrac’h", latitude: 48.5970, longitude: -4.5620),
        Place(name: "Saint-Malo", latitude: 48.6493, longitude: -2.0257),
        Place(name: "Le Havre", latitude: 49.4830, longitude: 0.1050),
        Place(name: "Cherbourg", latitude: 49.6500, longitude: -1.6167),
        Place(name: "Roscoff", latitude: 48.7240, longitude: -3.9860),
        Place(name: "Concarneau", latitude: 47.8720, longitude: -3.9200),
        Place(name: "Lorient", latitude: 47.7280, longitude: -3.3670),
        Place(name: "Vannes", latitude: 47.6350, longitude: -2.7600),
        Place(name: "La Rochelle", latitude: 46.1590, longitude: -1.1510),
        Place(name: "Arcachon", latitude: 44.6600, longitude: -1.1700),
        Place(name: "Biarritz", latitude: 43.4830, longitude: -1.5586),
        Place(name: "Sète", latitude: 43.4030, longitude: 3.6970),
        Place(name: "Marseille", latitude: 43.2965, longitude: 5.3698),
        Place(name: "Nice", latitude: 43.7100, longitude: 7.2620),
        Place(name: "Ajaccio", latitude: 41.9260, longitude: 8.7370),
        Place(name: "Bastia", latitude: 42.7000, longitude: 9.4500),
        Place(name: "Dunkerque", latitude: 51.0350, longitude: 2.3770),
        Place(name: "Dieppe", latitude: 49.9260, longitude: 1.0780),
        Place(name: "Les Sables-d'Olonne", latitude: 46.4960, longitude: -1.7830),
        Place(name: "Royan", latitude: 45.6270, longitude: -1.0280),
        Place(name: "Fort-de-France", latitude: 14.6030, longitude: -61.0740),
        Place(name: "Pointe-à-Pitre", latitude: 16.2410, longitude: -61.5330),
        Place(name: "Saint-Denis (La Réunion)", latitude: -20.8790, longitude: 55.4480),
        Place(name: "Nouméa", latitude: -22.2760, longitude: 166.4570),
        Place(name: "Papeete", latitude: -17.5350, longitude: -149.5700)
    ]

    static func nearest(to place: Place) -> Place {
        all.min { a, b in
            distance(a, place) < distance(b, place)
        } ?? all[0]
    }

    private static func distance(_ a: Place, _ b: Place) -> Double {
        let dLat = a.latitude - b.latitude
        let dLon = (a.longitude - b.longitude) * cos(b.latitude * .pi / 180)
        return dLat * dLat + dLon * dLon
    }
}
