import AppIntents
import Foundation

/// L'action « Salutations du jour », exposée à Raccourcis.
///
/// Blocgenda ne peut pas envoyer un SMS de lui-même : iOS ne l'autorise à
/// personne. L'application prépare donc la liste — un destinataire, un texte —
/// et c'est le raccourci « Envoyer un message » qui fait partir les envois,
/// depuis une automatisation quotidienne. Le mode d'emploi est en réglages.
///
/// L'intention lit les fichiers partagés plutôt que le `Store` : elle peut
/// s'exécuter sans que l'interface ne soit chargée.

// MARK: - Ce que Raccourcis reçoit

struct Salutation: AppEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Message à envoyer"
    static var defaultQuery = SalutationQuery()

    var id: String

    @Property(title: "Prénom")
    var prenom: String

    @Property(title: "Nom")
    var nom: String

    @Property(title: "Numéro")
    var numero: String

    @Property(title: "Message")
    var message: String

    @Property(title: "Occasion")
    var occasion: String

    init(greeting: Greeting) {
        self.id = greeting.contactID.uuidString
        self.prenom = greeting.firstName
        self.nom = greeting.name
        self.numero = greeting.phone
        self.message = greeting.message
        self.occasion = greeting.occasion.label
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(nom)", subtitle: "\(occasion)")
    }
}

struct SalutationQuery: EntityQuery {
    func entities(for identifiers: [Salutation.ID]) async throws -> [Salutation] {
        GreetingsPreparation.today(marking: false).filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [Salutation] {
        GreetingsPreparation.today(marking: false)
    }
}

// MARK: - Préparation

enum GreetingsPreparation {

    /// Les souhaits prêts à partir aujourd'hui.
    ///
    /// `marking` inscrit les envois au journal du jour : c'est ce qui empêche
    /// une automatisation déclenchée deux fois d'envoyer deux fois le message.
    static func today(marking: Bool, on day: Date = Date()) -> [Salutation] {
        let settings = SharedStorage.load(AppSettings.self, from: .settings) ?? AppSettings()
        // Le raccourci peut exister alors que l'envoi a été refermé en
        // réglages : il ne doit alors rien trouver à envoyer.
        guard settings.sendsGreetings else { return [] }

        let contacts = SharedStorage.load([Contact].self, from: .contacts) ?? []
        let greetings = Greetings
            .list(on: day, contacts: contacts, settings: settings, drawing: marking)
            .filter { $0.canSend && !GreetingLog.alreadySent($0.contactID, on: day) }

        if marking {
            GreetingLog.markSent(greetings.map(\.contactID), on: day)
        }
        return greetings.map(Salutation.init(greeting:))
    }
}

// MARK: - L'action

struct SalutationsDuJourIntent: AppIntent {

    static var title: LocalizedStringResource = "Salutations du jour"
    static var description = IntentDescription(
        "Renvoie les personnes de l’annuaire à féliciter aujourd’hui — anniversaire ou fête — avec leur numéro et un message prêt à envoyer.",
        categoryName: "Annuaire")
    static var openAppWhenRun = false

    @Parameter(title: "Ne pas renvoyer deux fois le même jour", default: true)
    var marquerEnvoyes: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<[Salutation]> {
        .result(value: GreetingsPreparation.today(marking: marquerEnvoyes))
    }
}

/// Le raccourci proposé d'office, et la phrase qui l'appelle à la voix.
struct BlocgendaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SalutationsDuJourIntent(),
            // Une seule phrase : les tournures interrogatives — « Qui féliciter
            // avec Blocgenda » — sont écartées en silence à l'extraction, et
            // une phrase qui ne part pas dans le paquet n'existe pas.
            phrases: ["Salutations du jour avec \(.applicationName)"],
            shortTitle: "Salutations du jour",
            systemImageName: "gift")
    }
}
