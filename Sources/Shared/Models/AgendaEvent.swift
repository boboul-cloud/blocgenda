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
    var contactID: UUID? = nil
    /// Fiche dont ce rendez-vous est l'anniversaire. Renseigné uniquement pour
    /// les rendez-vous que l'annuaire tient à jour tout seul.
    var birthdayContactID: UUID? = nil
    /// Jours (minuit) où l'occurrence a été cochée — permet de valider une récurrence.
    var completedDays: Set<Date> = []

    var end: Date { start.addingTimeInterval(isAllDay ? 0 : duration) }

    var isBirthday: Bool { birthdayContactID != nil }

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
