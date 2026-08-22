import Foundation

/// Les souhaits du jour : qui, dans l'annuaire, fête quelque chose aujourd'hui,
/// et le message qu'on lui enverra.
///
/// Rien ne part d'ici. Blocgenda prépare les messages ; c'est un raccourci
/// d'iOS qui les envoie, parce qu'aucune application n'a le droit d'envoyer un
/// SMS sans que l'utilisateur ne touche l'écran. Voir `SalutationsDuJourIntent`.
///
/// Le tri se fait sur les **fiches de l'annuaire**, jamais sur le carnet
/// d'adresses du téléphone : on ne souhaite un anniversaire qu'aux personnes
/// qu'on a recopiées ici, et seulement dans les tiroirs cochés en réglages.

// MARK: - Occasion

enum Occasion: String, Codable, CaseIterable, Sendable {
    case birthday
    case nameDay
    case both

    var label: String {
        switch self {
        case .birthday: return "Anniversaire"
        case .nameDay: return "Fête"
        case .both: return "Anniversaire et fête"
        }
    }

    /// Titre court, pour une pastille ou un onglet.
    var short: String {
        switch self {
        case .birthday: return "Anniversaire"
        case .nameDay: return "Fête"
        case .both: return "Les deux"
        }
    }
}

// MARK: - Un souhait

/// Une personne à féliciter aujourd'hui, et le message tiré pour elle.
struct Greeting: Identifiable, Hashable, Sendable {
    var contactID: UUID
    var name: String
    var firstName: String
    var phone: String
    var occasion: Occasion
    var age: Int?
    var message: String

    var id: UUID { contactID }

    /// Sans numéro, le raccourci n'a personne à qui parler : la fiche est
    /// montrée en réglages, mais elle ne part pas.
    var canSend: Bool { !phone.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Ouvre Messages avec le destinataire et le texte déjà écrits. C'est le
    /// chemin manuel, celui qui reste quand on ne veut pas d'automatisation.
    var messagesURL: URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "sms"
        components.path = digits
        components.queryItems = [URLQueryItem(name: "body", value: message)]
        return components.url
    }
}

// MARK: - Fabrique

enum Greetings {

    // Les réserves d'origine. Une formule par ligne en réglages ; `{prenom}` et
    // `{age}` sont remplacés au tirage.
    static let birthdayDefaults: [String] = [
        "Joyeux anniversaire {prenom} ! Je te souhaite une très belle journée.",
        "Bon anniversaire {prenom} ✨ Profite bien de ta journée !",
        "Très bel anniversaire à toi {prenom}, plein de bonnes choses pour cette nouvelle année.",
        "{prenom}, joyeux anniversaire ! J’espère que la journée sera à la hauteur.",
        "Un très joyeux anniversaire {prenom} 🎂 Passe une journée formidable.",
        "Bon anniversaire {prenom} ! Que cette année t’apporte tout ce que tu espères.",
        "Joyeux anniversaire {prenom} 🎉 Je pense bien à toi aujourd’hui.",
        "Belle journée d’anniversaire {prenom} ! On se fait signe bientôt ?"
    ]

    static let nameDayDefaults: [String] = [
        "Bonne fête {prenom} !",
        "Bonne fête à toi {prenom}, passe une belle journée.",
        "{prenom}, c’est ta fête aujourd’hui — je te la souhaite bonne !",
        "Bonne fête {prenom} 🌸 Petite pensée pour toi.",
        "Joyeuse fête {prenom} ! J’espère que tout va bien de ton côté.",
        "Bonne fête {prenom}, profite bien de ta journée."
    ]

    static let bothDefaults: [String] = [
        "Joyeux anniversaire et bonne fête {prenom} ! Double raison de célébrer aujourd’hui 🎉",
        "{prenom}, anniversaire et fête le même jour : je te souhaite une journée doublement belle !",
        "Bon anniversaire et bonne fête {prenom} ✨ Profite de cette journée deux fois plus."
    ]

    static func defaults(for occasion: Occasion) -> [String] {
        switch occasion {
        case .birthday: return birthdayDefaults
        case .nameDay: return nameDayDefaults
        case .both: return bothDefaults
        }
    }

    /// Les formules en vigueur : celles écrites en réglages, à défaut celles
    /// d'origine. Une liste vidée à la main revient aux formules d'origine —
    /// sans quoi le raccourci enverrait des messages vides.
    static func formulas(for occasion: Occasion, settings: AppSettings) -> [String] {
        let custom = settings.greetingFormulas?[occasion.rawValue]?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        return custom.isEmpty ? defaults(for: occasion) : custom
    }

    // MARK: Qui féliciter

    /// Les fiches à féliciter ce jour-là, avec leur occasion.
    ///
    /// `respectGroups` à `false` sert à l'aperçu de réglages, pour montrer qui
    /// serait concerné avant même d'avoir coché un tiroir.
    static func candidates(on day: Date,
                           contacts: [Contact],
                           settings: AppSettings,
                           respectGroups: Bool = true) -> [(contact: Contact, occasion: Occasion)] {
        let groups = Set(settings.greetedGroups.map(Contact.groupKey))
        var result: [(Contact, Occasion)] = []

        for contact in contacts {
            if respectGroups, !groups.contains(Contact.groupKey(contact.group)) { continue }

            let birthday = settings.greetsBirthdays && contact.hasBirthday(on: day)
            let nameDay = settings.greetsNameDays
                && !contact.firstName.isEmpty
                && NameDays.celebrates(firstName: contact.firstName, on: day)
            guard birthday || nameDay else { continue }

            let occasion: Occasion = birthday && nameDay ? .both : (birthday ? .birthday : .nameDay)
            result.append((contact, occasion))
        }

        return result.sorted {
            $0.0.fullName.localizedCaseInsensitiveCompare($1.0.fullName) == .orderedAscending
        }
    }

    /// Les souhaits du jour, message compris.
    ///
    /// `drawing` retient la formule tirée pour ne pas resservir la même à la
    /// même personne l'année suivante ; l'aperçu, lui, ne retient rien.
    static func list(on day: Date = Date(),
                     contacts: [Contact],
                     settings: AppSettings,
                     drawing: Bool,
                     respectGroups: Bool = true) -> [Greeting] {
        candidates(on: day, contacts: contacts, settings: settings, respectGroups: respectGroups)
            .map { contact, occasion in
                Greeting(contactID: contact.id,
                         name: contact.fullName,
                         firstName: contact.firstName.isEmpty ? contact.fullName : contact.firstName,
                         phone: contact.phone,
                         occasion: occasion,
                         age: contact.age(on: day),
                         message: message(for: contact, occasion: occasion,
                                          settings: settings, on: day, drawing: drawing))
            }
    }

    /// Tire une formule, en évitant celle servie la fois précédente à cette
    /// personne : la même phrase deux anniversaires de suite se remarque.
    static func message(for contact: Contact,
                        occasion: Occasion,
                        settings: AppSettings,
                        on day: Date = Date(),
                        drawing: Bool) -> String {
        let pool = formulas(for: occasion, settings: settings)
        guard !pool.isEmpty else { return "Bonne journée \(contact.firstName) !" }

        var index: Int
        if drawing {
            index = Int.random(in: 0..<pool.count)
            if pool.count > 1, index == GreetingLog.lastFormula(for: contact.id, occasion: occasion) {
                index = (index + 1) % pool.count
            }
            GreetingLog.remember(index, for: contact.id, occasion: occasion)
        } else {
            // L'aperçu doit être stable : il se redessine à chaque frappe en
            // réglages, et une phrase qui change sous les yeux est illisible.
            index = Int(UInt(bitPattern: contact.id.hashValue) % UInt(pool.count))
        }

        return fill(pool[index], for: contact, on: day)
    }

    static func fill(_ template: String, for contact: Contact, on day: Date = Date()) -> String {
        let firstName = contact.firstName.isEmpty ? contact.fullName : contact.firstName
        return template
            .replacingOccurrences(of: "{prenom}", with: firstName)
            .replacingOccurrences(of: "{age}", with: contact.age(on: day).map(String.init) ?? "")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Ce qui est déjà parti

/// Mémoire de service des souhaits : la dernière formule servie à chacun, et
/// les envois du jour.
///
/// À part des réglages, et dans les préférences partagées plutôt que dans un
/// fichier : c'est le raccourci qui écrit ici, parfois pendant que
/// l'application dort, et il ne doit pas réécrire par-dessus `settings.json`.
enum GreetingLog {
    private static let formulaPrefix = "salutation.formule."
    private static let sentKey = "salutation.envois"

    private static var defaults: UserDefaults { SharedStorage.defaults }

    private static func dayKey(_ day: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: day)
    }

    static func lastFormula(for contactID: UUID, occasion: Occasion) -> Int? {
        defaults.object(forKey: "\(formulaPrefix)\(contactID.uuidString).\(occasion.rawValue)") as? Int
    }

    static func remember(_ index: Int, for contactID: UUID, occasion: Occasion) {
        defaults.set(index, forKey: "\(formulaPrefix)\(contactID.uuidString).\(occasion.rawValue)")
    }

    private static var sent: [String: [String]] {
        get { defaults.dictionary(forKey: sentKey) as? [String: [String]] ?? [:] }
        set { defaults.set(newValue, forKey: sentKey) }
    }

    static func alreadySent(_ contactID: UUID, on day: Date = Date()) -> Bool {
        sent[dayKey(day)]?.contains(contactID.uuidString) ?? false
    }

    static func markSent(_ ids: [UUID], on day: Date = Date()) {
        guard !ids.isEmpty else { return }
        var log = sent
        log[dayKey(day), default: []].append(contentsOf: ids.map(\.uuidString))
        // Une semaine de mémoire suffit à empêcher un doublon ; au-delà, ce
        // n'est plus qu'un journal que personne ne lit.
        let recent = Set(log.keys.sorted().suffix(7))
        sent = log.filter { recent.contains($0.key) }
    }

    /// Oublie les envois du jour : le raccourci peut alors être relancé.
    static func forgetToday(_ day: Date = Date()) {
        var log = sent
        log.removeValue(forKey: dayKey(day))
        sent = log
    }

    static func sentToday(on day: Date = Date()) -> Int {
        sent[dayKey(day)]?.count ?? 0
    }
}
