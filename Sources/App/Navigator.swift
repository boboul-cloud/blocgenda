import Observation
import SwiftUI

/// Où l'on est dans l'application, et où l'on demande à aller. Un écran peut
/// ainsi renvoyer vers un autre onglet — l'agenda vers la fiche d'annuaire d'un
/// anniversaire, par exemple — sans que les vues se connaissent entre elles.
@Observable
@MainActor
final class Navigator {
    var tab: Tab = .roll

    /// Fiche que l'annuaire doit montrer dès qu'il s'ouvre. Remise à `nil` une
    /// fois la fiche atteinte.
    var contactToReveal: UUID?

    /// Ouvre l'annuaire sur une fiche précise.
    func reveal(contact id: UUID) {
        contactToReveal = id
        tab = .directory
    }
}
