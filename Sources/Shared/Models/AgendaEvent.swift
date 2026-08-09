import Foundation

enum RepeatRule: String, Codable, CaseIterable, Identifiable, Sendable {
    case none, daily, weekdays, weekly, biweekly, monthly, yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Une seule fois"
        case .daily: return "Tous les jours"
        case .weekdays: return "Du lundi au vendredi"
        case .weekly: return "Toutes les semaines"
        case .biweekly: return "Toutes les 2 semaines"
        case .monthly: return "Tous les mois"
        case .yearly: return "Tous les ans"
        }
    }

    var shortLabel: String {
        switch self {
        case .none: return ""
        case .daily: return "quotidien"
        case .weekdays: return "sem."
        case .weekly: return "hebdo"
        case .biweekly: return "2 sem."
        case .monthly: return "mensuel"
        case .yearly: return "annuel"
        }
    }
}

struct AgendaEvent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var start: Date = Date()
    /// En secondes. Ignoré si `isAllDay`.
    var duration: TimeInterval = 3600
    var isAllDay: Bool = false
    var repeatRule: RepeatRule = .none
    /// Rappels exprimés en minutes avant le début (0 = à l'heure pile).
    var reminders: [Int] = [15]
    var place: String = ""
    var colorIndex: Int = 0
    /// Sujet du rendez-vous — anniversaire, véhicule, santé… C'est par lui que
    /// l'agenda retrouve d'un geste tout ce qui touche à la même affaire.
    ///
    /// Optionnel à dessein : la clé manque dans les fichiers écrits par une
    /// version antérieure, et une chaîne sèche ferait échouer la relecture de
    /// tout l'agenda. Absent vaut « sans thème ».
    var theme: String? = nil
    var contactID: UUID? = nil
    /// Fiche dont ce rendez-vous est l'anniversaire. Renseigné uniquement pour
    /// les rendez-vous que l'annuaire tient à jour tout seul.
    var birthdayContactID: UUID? = nil
    /// Jours (minuit) où l'occurrence a été cochée — permet de valider une récurrence.
    var completedDays: Set<Date> = []

    var end: Date { start.addingTimeInterval(isAllDay ? 0 : duration) }

    var isBirthday: Bool { birthdayContactID != nil }

    /// Le thème tel qu'on l'affiche : vide quand le rendez-vous n'en porte pas.
    var themeName: String {
        theme?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var hasTheme: Bool { !themeName.isEmpty }

    /// Le rendez-vous relève-t-il de ce thème ? La comparaison passe par la
    /// clé : « Véhicule » et « vehicule » désignent le même sujet.
    func belongs(toTheme name: String) -> Bool {
        hasTheme && Self.themeKey(themeName) == Self.themeKey(name)
    }

    func isCompleted(on day: Date) -> Bool {
        completedDays.contains(Calendar.current.startOfDay(for: day))
    }

    /// Date de début de l'occurrence tombant le jour donné, s'il y en a une.
    func occurrence(on day: Date) -> Date? {
        let cal = Calendar.current
        let target = cal.startOfDay(for: day)
        let first = cal.startOfDay(for: start)
        guard target >= first else { return nil }

        let matches: Bool
        switch repeatRule {
        case .none:
            matches = target == first
        case .daily:
            matches = true
        case .weekdays:
            let wd = cal.component(.weekday, from: target)
            matches = wd != 1 && wd != 7
        case .weekly:
            matches = cal.component(.weekday, from: target) == cal.component(.weekday, from: first)
        case .biweekly:
            let days = cal.dateComponents([.day], from: first, to: target).day ?? 0
            matches = days % 14 == 0
        case .monthly:
            matches = cal.component(.day, from: target) == cal.component(.day, from: first)
        case .yearly:
            matches = cal.component(.day, from: target) == cal.component(.day, from: first)
                && cal.component(.month, from: target) == cal.component(.month, from: first)
        }
        guard matches else { return nil }

        let time = cal.dateComponents([.hour, .minute], from: start)
        return cal.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: target)
    }

    /// Le prochain jour où le rendez-vous tombe, à partir de `day` compris.
    /// `nil` s'il n'en reste aucun dans la fenêtre observée — un rendez-vous
    /// unique déjà passé, par exemple.
    ///
    /// La fenêtre couvre un peu plus d'un an : assez pour attraper la
    /// prochaine occurrence d'une récurrence annuelle, un anniversaire compris.
    func nextStart(from day: Date = Date(), within days: Int = 400) -> Date? {
        let cal = Calendar.current
        let first = cal.startOfDay(for: day)
        for offset in 0..<days {
            guard let d = cal.date(byAdding: .day, value: offset, to: first) else { continue }
            if let hit = occurrence(on: d) { return hit }
        }
        return nil
    }
}

// MARK: - Thèmes

extension AgendaEvent {
    /// Les thèmes offerts d'office. Ce sont les affaires que l'on suit d'une
    /// année sur l'autre : on les trouve déjà là plutôt que d'avoir à les
    /// nommer soi-même avant de s'en servir.
    static let defaultThemes = ["Anniversaire", "Véhicule", "Santé", "Maison",
                                "Travail", "Famille", "Loisirs", "Papiers"]

    /// Le thème donné aux anniversaires venus de l'annuaire.
    static let birthdayTheme = "Anniversaire"

    /// Clé de rapprochement des thèmes : deux noms qui ne diffèrent que par la
    /// casse, les accents ou les espaces de bordure désignent le même thème.
    /// Tout ce qui range ou retrouve un rendez-vous suit cette règle, sans quoi
    /// un rendez-vous se classerait sous un thème que le filtre n'atteint plus.
    static func themeKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

// MARK: - Anniversaires venus de l'annuaire

extension AgendaEvent {
    /// Rappel « la veille », en minutes avant le début.
    static let dayBeforeReminder = 24 * 60

    /// Le rendez-vous couvre la journée entière : cette heure ne s'affiche
    /// nulle part, elle sert au rappel, pour qu'il tombe la veille au matin
    /// plutôt qu'à minuit.
    static let birthdayHour = 9

    static func birthdayTitle(for contact: Contact) -> String {
        "Anniversaire de \(contact.fullName)"
    }

    /// Le rendez-vous annuel correspondant à la date de naissance d'une fiche,
    /// ou `nil` si la fiche n'en porte pas.
    static func birthday(for contact: Contact, calendar: Calendar = .current) -> AgendaEvent? {
        guard let day = contact.birthday else { return nil }
        var event = AgendaEvent()
        event.reminders = [dayBeforeReminder]
        event.colorIndex = contact.colorIndex
        event.applyBirthday(of: contact, on: day, calendar: calendar)
        return event
    }

    /// Reporte sur le rendez-vous ce qui vient de la fiche — et rien d'autre :
    /// les rappels, la couleur ou les notes ajoutés depuis l'agenda survivent à
    /// une modification de l'annuaire.
    ///
    /// Le début garde l'année de naissance : la répétition annuelle part de là,
    /// et l'âge reste calculable.
    mutating func applyBirthday(of contact: Contact, on day: Date, calendar: Calendar = .current) {
        birthdayContactID = contact.id
        contactID = contact.id
        title = Self.birthdayTitle(for: contact)
        start = calendar.date(bySettingHour: Self.birthdayHour, minute: 0, second: 0, of: day) ?? day
        isAllDay = true
        repeatRule = .yearly
        adoptBirthdayTheme()
    }

    /// Un anniversaire de l'annuaire relève du thème « Anniversaire », sans
    /// qu'on ait à le dire : c'est le seul rendez-vous que l'application écrit
    /// elle-même, elle le range elle-même.
    ///
    /// Un thème choisi à la main depuis l'agenda fait exception et reste en
    /// place : on peut vouloir suivre l'anniversaire d'un enfant sous « Famille ».
    /// Renvoie `true` si le thème vient d'être posé.
    @discardableResult
    mutating func adoptBirthdayTheme() -> Bool {
        guard isBirthday, !hasTheme else { return false }
        theme = Self.birthdayTheme
        return true
    }
}

/// Une occurrence concrète d'un événement, à une date donnée.
struct EventOccurrence: Identifiable, Hashable, Sendable {
    let event: AgendaEvent
    let start: Date

    var id: String { "\(event.id.uuidString)-\(start.timeIntervalSince1970)" }
    var end: Date { start.addingTimeInterval(event.isAllDay ? 0 : event.duration) }
    var isCompleted: Bool { event.isCompleted(on: start) }
}
