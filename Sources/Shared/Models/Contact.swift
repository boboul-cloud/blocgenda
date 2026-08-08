import Foundation

/// Fiche de l'annuaire. Volontairement autonome : on peut recopier une fois
/// pour toutes des fiches du carnet d'adresses du téléphone, mais rien n'est
/// tenu synchronisé — l'annuaire reste un module du bloc-notes.
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

    /// Année conventionnelle des dates de naissance dont on ignore l'année : le
    /// carnet d'adresses du téléphone en donne beaucoup (jour et mois seuls).
    /// L'anniversaire revient bien tous les ans, mais l'âge reste inconnu.
    static let unknownBirthYear = 1604

    /// Les tiroirs offerts d'office. L'utilisateur en ajoute librement
    /// d'autres — voir `Store.contactGroups`.
    static let defaultGroups = ["Général", "Famille", "Travail", "Santé", "Mer", "Maison", "Urgences"]

    var knowsBirthYear: Bool {
        guard let birthday else { return false }
        return Calendar.current.component(.year, from: birthday) != Self.unknownBirthYear
    }

    /// Clé de rapprochement, pour écarter les doublons à l'import : deux fiches
    /// qui partagent un numéro — à défaut un courriel, à défaut un nom —
    /// désignent la même personne. On ne garde que la fin du numéro, pour que
    /// « 06 12 34 56 78 » et « +33 6 12 34 56 78 » se reconnaissent.
    var matchKey: String {
        let digits = phone.filter(\.isNumber)
        if digits.count >= 6 { return "tel:\(String(digits.suffix(9)))" }
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !mail.isEmpty { return "mel:\(mail)" }
        return "nom:\(fullName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current))"
    }

    /// Âge atteint le jour de l'anniversaire de l'année en cours.
    func age(on day: Date = Date()) -> Int? {
        guard let birthday, knowsBirthYear else { return nil }
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
