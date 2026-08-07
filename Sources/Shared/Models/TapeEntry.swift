import Foundation

/// Nature d'une ligne imprimée sur le rouleau.
enum TapeKind: String, Codable, CaseIterable, Sendable {
    case note       // texte libre
    case calc       // opération + résultat
    case task       // action à cocher
    case subtotal   // trait de sous-total imprimé par la calculatrice
    case event      // renvoi vers un événement de l'agenda
    case memo       // mémoire calculatrice (M+ / M-)
}

/// Une ligne du rouleau de papier. Tout ce que fait l'utilisateur atterrit ici,
/// dans l'ordre chronologique, comme sur la bande d'une additionneuse.
struct TapeEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date = Date()
    var kind: TapeKind = .note
    /// Libellé lisible : le texte de la note, l'intitulé de la dépense, la tâche…
    var text: String = ""
    /// Expression saisie, telle que ré-imprimée sur la bande ("12,50 × 3").
    var expression: String? = nil
    /// Valeur numérique associée (résultat du calcul, montant de la dépense).
    var value: Double? = nil
    var done: Bool = false
    var tags: [String] = []
    var eventID: UUID? = nil
    var pinned: Bool = false
    /// Les lignes détachées restent en mémoire mais quittent la bande courante.
    var tornAt: Date? = nil

    var isOnRoll: Bool { tornAt == nil }

    var day: Date { Calendar.current.startOfDay(for: date) }

    /// Un montant "comptable" : positif ou négatif, utilisé pour les totaux.
    var amount: Double? {
        switch kind {
        case .calc, .memo: return value
        case .note, .task: return value
        case .subtotal, .event: return nil
        }
    }
}

/// Regroupement d'un jour de rouleau, utilisé par l'affichage.
struct TapeDay: Identifiable {
    var id: Date { day }
    let day: Date
    var entries: [TapeEntry]

    var total: Double {
        entries.compactMap(\.amount).reduce(0, +)
    }
    var taskCount: Int { entries.filter { $0.kind == .task }.count }
    var doneCount: Int { entries.filter { $0.kind == .task && $0.done }.count }
}
