import Foundation

/// Fiche de l'annuaire. Volontairement autonome (pas de dépendance au carnet
/// d'adresses système) pour que l'annuaire reste un module du bloc-notes.
struct Contact: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var company: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var note: String = ""
    var birthday: Date? = nil
    var isFavorite: Bool = false
    var group: String = "Général"
    var colorIndex: Int = 0

    var fullName: String {
        let n = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return n.isEmpty ? (company.isEmpty ? "Sans nom" : company) : n
    }

    var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var sortKey: String {
        (lastName.isEmpty ? fullName : lastName).folding(
            options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    /// Âge atteint le jour de l'anniversaire de l'année en cours.
    func age(on day: Date = Date()) -> Int? {
        guard let birthday else { return nil }
        let cal = Calendar.current
        guard let years = cal.dateComponents([.year], from: birthday, to: day).year else { return nil }
        return max(0, years)
    }

    func hasBirthday(on day: Date) -> Bool {
        guard let birthday else { return false }
        let cal = Calendar.current
        return cal.component(.day, from: birthday) == cal.component(.day, from: day)
            && cal.component(.month, from: birthday) == cal.component(.month, from: day)
    }
}
