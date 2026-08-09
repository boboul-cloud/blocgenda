import Foundation

/// L'humeur du moment. Elle ne décrit pas ce qu'on écrit — elle décide de la
/// façon dont la page le remet en forme : trois mises en page, trois allures.
enum JournalMood: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Le récit posé : les moments cousus en paragraphes, matin, après-midi, soir.
    case posee
    /// L'élan : une ligne par moment, l'heure en marge, la phrase forte en exergue.
    case vive
    /// La rêverie : pas d'heures, pas de titres, une pensée détachée en tête de page.
    case songeuse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posee: return "Posée"
        case .vive: return "Vive"
        case .songeuse: return "Songeuse"
        }
    }

    /// Ce que l'humeur fait à la page, dit en clair sous le sélecteur.
    var hint: String {
        switch self {
        case .posee: return "en paragraphes, du matin au soir"
        case .vive: return "une ligne par moment, l'heure en marge"
        case .songeuse: return "au fil de la plume, sans horaires"
        }
    }

    var icon: String {
        switch self {
        case .posee: return "text.alignleft"
        case .vive: return "bolt.fill"
        case .songeuse: return "cloud.fill"
        }
    }
}

/// Un moment, une pensée. La plus petite chose qu'on dépose dans la journée,
/// écrite au clavier ou dictée.
struct JournalNote: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var text: String = ""
    /// Vrai si la ligne est venue du micro. La page le rappelle discrètement :
    /// une phrase dictée ne se relit pas comme une phrase écrite.
    var spoken: Bool = false

    var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// Ce que la journée avait d'objectif au moment où la page s'est ouverte : le
/// temps qu'il faisait, le ciel, l'éphéméride. Recopié une fois pour toutes
/// dans la page — dans dix ans, la météo du jour ne se retrouve plus.
///
/// Tout est facultatif : une page peut naître hors réseau, ou dans une version
/// antérieure de l'application, sans que sa relecture échoue.
struct DayStamp: Codable, Hashable, Sendable {
    var capturedAt: Date = Date()
    var placeName: String? = nil

    // Le temps qu'il fait
    var temperature: Double? = nil
    var minTemperature: Double? = nil
    var maxTemperature: Double? = nil
    var weatherLabel: String? = nil
    var weatherSymbol: String? = nil
    var windCardinal: String? = nil
    var beaufort: Int? = nil

    // Le ciel
    var sunrise: Date? = nil
    var sunset: Date? = nil
    var moonName: String? = nil
    var moonSymbol: String? = nil

    // Les curiosités du jour
    var saint: String? = nil
    var dicton: String? = nil
    var historicalEvent: String? = nil
    var holidayName: String? = nil
    var dayOfYear: Int? = nil
    var daysRemaining: Int? = nil
    var weekNumber: Int? = nil

    // Le bord de mer, s'il y en a un
    var tidePort: String? = nil
    var nextHighTide: Date? = nil

    var birthdays: [String]? = nil

    /// Vrai dès que la page a de quoi remplir son cartouche.
    var hasWeather: Bool { temperature != nil || weatherLabel != nil }

    /// La longueur du jour, qu'on ne pense jamais à noter. Brute : c'est la
    /// page qui la met en toutes lettres.
    var daylight: TimeInterval? {
        guard let sunrise, let sunset, sunset > sunrise else { return nil }
        return sunset.timeIntervalSince(sunrise)
    }

    var temperatureText: String? {
        temperature.map { "\(Int($0.rounded())) °C" }
    }
}

/// Une page du journal : un jour, une humeur, ce qu'on y a déposé, et le
/// tampon de la journée.
struct JournalPage: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    /// Toujours un début de journée : c'est la clé de la page.
    var day: Date = Calendar.current.startOfDay(for: Date())
    var mood: JournalMood = .posee
    /// Titre donné à la main. Vide, la page prend la date pour titre.
    var title: String = ""
    var notes: [JournalNote] = []
    var stamp: DayStamp? = nil

    var isEmpty: Bool { notes.allSatisfy { $0.trimmed.isEmpty } }

    /// Les notes dans l'ordre où elles sont venues, les vides écartées.
    var ordered: [JournalNote] {
        notes.filter { !$0.trimmed.isEmpty }.sorted { $0.date < $1.date }
    }

    var wordCount: Int {
        ordered.reduce(0) { $0 + $1.trimmed.split(whereSeparator: \.isWhitespace).count }
    }
}
