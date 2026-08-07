import Foundation

/// Accès disque partagé entre l'app et le widget.
///
/// Tout passe par le conteneur App Group. Si celui-ci n'est pas disponible
/// (projet non signé, simulateur sans profil), on retombe proprement sur le
/// dossier Application Support pour que rien ne casse.
enum SharedStorage {
    static let appGroup = "group.com.oulhen.blocgenda"

    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return url
        }
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Blocgenda", isDirectory: true)
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    // MARK: - Fichiers

    enum File: String {
        case tape = "tape.json"
        case events = "events.json"
        case contacts = "contacts.json"
        case snapshot = "snapshot.json"
        case settings = "settings.json"
    }

    static func url(_ file: File) -> URL {
        containerURL.appendingPathComponent(file.rawValue)
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load<T: Decodable>(_ type: T.Type, from file: File) -> T? {
        guard let data = try? Data(contentsOf: url(file)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to file: File) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(file), options: .atomic)
    }
}

/// Réglages de l'application, partagés avec le widget.
struct AppSettings: Codable, Hashable, Sendable {
    var place: Place = .paris
    var followLocation: Bool = true
    /// Port utilisé pour les marées quand la position n'est pas côtière.
    var tidePort: Place? = nil
    var morningBriefingEnabled: Bool = true
    var morningBriefingHour: Int = 7
    var morningBriefingMinute: Int = 30
    var eveningReviewEnabled: Bool = true
    var eveningReviewHour: Int = 21
    var eveningReviewMinute: Int = 0
    var goldenHourAlert: Bool = false
    var tideAlert: Bool = false
    var currencySymbol: String = "€"
    var vatRate: Double = 20
    var paperTint: Int = 0
    var hasSeededSample: Bool = false

    /// Lieu réellement utilisé pour les marées.
    var tideReference: Place { tidePort ?? place }
}
