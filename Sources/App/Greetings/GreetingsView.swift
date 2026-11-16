import MessageUI
import SwiftUI

/// Les souhaits du jour : ce que Blocgenda prépare pour les anniversaires et
/// les fêtes des fiches de l'annuaire.
///
/// L'application n'envoie rien elle-même — iOS ne le permet à personne. Elle
/// tient la liste, tire la formule, et laisse partir l'envoi soit à la main
/// (bouton *Envoyer*, qui ouvre Messages avec le texte écrit), soit par une
/// automatisation de Raccourcis, expliquée en bas de l'écran.
struct GreetingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var now = Date()
    @State private var forgotten = false
    /// Le souhait dont on est en train d'écrire le message.
    @State private var composing: Greeting?
    /// Ce qui vient de partir à la main, le temps de le montrer sur la ligne.
    @State private var justSent: Set<UUID> = []

    private var greetings: [Greeting] { store.greetings(on: now) }
    private var sendable: [Greeting] { greetings.filter(\.canSend) }
    private var withoutNumber: [Greeting] { greetings.filter { !$0.canSend } }

    /// Ce que l'annuaire donnerait sans le filtre des tiroirs : sert à dire
    /// pourquoi la liste du jour est vide alors qu'il y a bien un anniversaire.
    private var ignoredByGroups: Int {
        store.greetings(on: now, respectGroups: false).count - greetings.count
    }

    var body: some View {
        Form {
            Section {
                Toggle("Préparer les souhaits", isOn: flag(\.greetingsEnabled, default: false))
                    .accessibilityIdentifier("souhaits.interrupteur")
            } footer: {
                Text("Blocgenda repère les anniversaires et les fêtes de votre annuaire, et prépare un message pour chacun. Rien ne part sans vous : l’envoi se fait d’un bouton, ou par une automatisation que vous montez une fois pour toutes.")
            }

            if store.settings.sendsGreetings {
                occasions
                groups
                today
                formulas
                automation
            }
        }
        .navigationTitle("Souhaits")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { now = Date() }
        .sheet(item: $composing) { greeting in
            MessageComposer(recipients: [greeting.phone], body: greeting.message) { result in
                composing = nil
                guard result == .sent else { return }
                // Ce qui est parti à la main ne doit pas repartir le soir par
                // l'automatisation : le journal du jour ne fait pas la
                // différence entre les deux chemins, et c'est bien ainsi.
                GreetingLog.markSent([greeting.contactID], on: now)
                justSent.insert(greeting.contactID)
            }
        }
    }

    // MARK: Occasions

    @ViewBuilder
    private var occasions: some View {
        Section {
            Toggle("Anniversaires", isOn: flag(\.greetingsIncludeBirthdays, default: true))
            Toggle("Fêtes du prénom", isOn: flag(\.greetingsIncludeNameDays, default: true))
        } header: {
            Text("Occasions")
        } footer: {
            Text("L’anniversaire vient de la date de naissance de la fiche ; la fête, du prénom rapproché du calendrier des postes. Un prénom composé est fêté avec chacune de ses parties.")
        }
    }

    // MARK: Tiroirs

    @ViewBuilder
    private var groups: some View {
        Section {
            ForEach(store.contactGroups, id: \.self) { name in
                Button {
                    toggle(group: name)
                } label: {
                    HStack {
                        Label(name, systemImage: isGreeted(name) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isGreeted(name) ? Ink.text : Ink.textSoft)
                        Spacer()
                        Text("\(store.contacts.count { Contact.groupKey($0.group) == Contact.groupKey(name) })")
                            .font(Type.tape(13))
                            .foregroundStyle(.secondary)
                    }
                    // Sans cela, seul le libellé coche le tiroir : le vide
                    // entre le nom et le compte ne répond pas à l'appui.
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("souhaits.groupe.\(name)")
                .accessibilityAddTraits(isGreeted(name) ? [.isSelected] : [])
                // La pastille cochée est la seule chose qui distingue un
                // tiroir retenu d'un autre : sans cette valeur, la synthèse
                // vocale lit « Famille, 12 » sans dire si on le fête.
                .accessibilityValue(isGreeted(name) ? "Coché" : "Non coché")
            }
        } header: {
            Text("Groupes concernés")
        } footer: {
            Text(store.settings.greetedGroups.isEmpty
                 ? "Aucun groupe coché : rien ne sera préparé. Cochez les tiroirs dont vous voulez fêter les fiches — la famille et les amis, rarement le garagiste."
                 : "Seules les fiches rangées dans ces tiroirs sont fêtées. Une fiche déplacée d’un tiroir à l’autre change de camp aussitôt.")
        }
    }

    // MARK: Aujourd'hui

    @ViewBuilder
    private var today: some View {
        Section {
            if greetings.isEmpty {
                Text(emptyToday)
                    .font(Type.ui(13))
                    .foregroundStyle(.secondary)
            }
            ForEach(sendable) { greeting in
                GreetingRow(greeting: greeting, sent: justSent.contains(greeting.contactID)) {
                    send(greeting)
                }
            }
            ForEach(withoutNumber) { greeting in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting.name).font(Type.ui(14, weight: .semibold))
                        Text("Pas de numéro sur la fiche")
                            .font(Type.ui(11))
                            .foregroundStyle(Ink.rouge)
                    }
                    Spacer()
                    Pill(text: greeting.occasion.short, color: Ink.textFaint)
                }
            }
        } header: {
            Text("Aujourd’hui")
        } footer: {
            Text("Le bouton ouvre Messages avec le destinataire et le texte déjà écrits ; c’est vous qui appuyez sur envoyer. L’aperçu montre une formule au hasard de la réserve.")
        }
    }

    private var emptyToday: String {
        if store.contacts.isEmpty {
            return "L’annuaire est vide."
        }
        if ignoredByGroups > 0 {
            return "Personne à fêter dans les groupes cochés. \(ignoredByGroups) fiche\(ignoredByGroups > 1 ? "s le sont" : " l’est") aujourd’hui dans un autre tiroir."
        }
        return "Ni anniversaire ni fête aujourd’hui dans votre annuaire."
    }

    // MARK: Formules

    @ViewBuilder
    private var formulas: some View {
        Section {
            ForEach(Occasion.allCases, id: \.self) { occasion in
                NavigationLink {
                    GreetingFormulasView(occasion: occasion).environment(store)
                } label: {
                    HStack {
                        Text(occasion.label)
                        Spacer()
                        Text("\(Greetings.formulas(for: occasion, settings: store.settings).count)")
                            .font(Type.tape(13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Formules")
        } footer: {
            Text("Une formule est tirée au hasard, en évitant celle servie la fois précédente à la même personne. « Anniversaire et fête » sert aux rares fiches qui cumulent les deux le même jour.")
        }
    }

    // MARK: Automatisation

    @ViewBuilder
    private var automation: some View {
        Section {
            NavigationLink {
                GreetingsSetupView()
            } label: {
                Label("Envoyer sans y penser", systemImage: "wand.and.stars")
            }

            Button(forgotten ? "Journal du jour effacé" : "Oublier les envois du jour") {
                GreetingLog.forgetToday()
                forgotten = true
                now = Date()
            }
            .disabled(forgotten || GreetingLog.sentToday() == 0)
        } header: {
            Text("Automatisation")
        } footer: {
            Text(GreetingLog.sentToday() == 0
                 ? "Le mode d’emploi montre en images le raccourci à obtenir. Une personne n’est rendue qu’une fois par jour : rien n’est encore parti aujourd’hui."
                 : "\(GreetingLog.sentToday()) envoi\(GreetingLog.sentToday() > 1 ? "s" : "") déjà remis au raccourci aujourd’hui. Les oublier permet de relancer l’automatisation.")
        }
    }

    // MARK: Ficelles

    /// Les réglages nouveaux sont optionnels pour survivre à la relecture d'un
    /// fichier écrit par une version antérieure ; les interrupteurs, eux,
    /// veulent un booléen sec.
    private func flag(_ key: WritableKeyPath<AppSettings, Bool?>, default fallback: Bool) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: key] ?? fallback },
                set: { store.settings[keyPath: key] = $0; store.scheduleSave() })
    }

    /// Ouvre le composeur d'iOS ; à défaut — simulateur, appareil sans SMS —
    /// un lien `sms:`, qui au moins désigne le destinataire.
    private func send(_ greeting: Greeting) {
        if MessageComposer.isAvailable {
            composing = greeting
        } else if let url = greeting.messagesURL {
            openURL(url)
        }
    }

    private func isGreeted(_ name: String) -> Bool {
        store.settings.greetedGroups.contains { Contact.groupKey($0) == Contact.groupKey(name) }
    }

    private func toggle(group name: String) {
        var groups = store.settings.greetedGroups
        if let i = groups.firstIndex(where: { Contact.groupKey($0) == Contact.groupKey(name) }) {
            groups.remove(at: i)
        } else {
            groups.append(name)
        }
        store.settings.greetingGroups = groups
        store.scheduleSave()
    }
}

// MARK: - Une ligne de souhait

private struct GreetingRow: View {
    let greeting: Greeting
    /// Déjà parti à la main : le bouton se retire, il n'y a plus rien à faire.
    var sent: Bool = false
    let send: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(greeting.name)
                        .font(Type.ui(14, weight: .semibold))
                        .foregroundStyle(Ink.text)
                    if let age = greeting.age {
                        Text("\(age) ans")
                            .font(Type.ui(11))
                            .foregroundStyle(Ink.textFaint)
                    }
                }
                Text(greeting.message)
                    .font(Type.ui(12))
                    .italic()
                    .foregroundStyle(Ink.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Pill(text: greeting.occasion.short,
                     color: greeting.occasion == .nameDay ? Ink.sea : Ink.rouge)
            }
            Spacer(minLength: 4)
            if sent {
                Image(systemName: "checkmark.circle.fill")
                    .font(Type.icon(13, weight: .semibold))
                    .foregroundStyle(Ink.moss)
                    .frame(width: Type.control(34), height: Type.control(34))
                    .accessibilityLabel("Message envoyé à \(greeting.name)")
            } else {
                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(Type.icon(13, weight: .semibold))
                        .foregroundStyle(Ink.moss)
                        .frame(width: Type.control(34), height: Type.control(34))
                        .background(Circle().fill(Ink.moss.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Envoyer un message à \(greeting.name)")
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Les formules d'une occasion

struct GreetingFormulasView: View {
    @Environment(Store.self) private var store
    let occasion: Occasion

    @State private var text = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .font(Type.ui(14))
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, _ in save() }
            } header: {
                Text("Une formule par ligne")
            } footer: {
                Text("{prenom} et {age} sont remplacés à l’envoi. {age} reste vide quand la fiche ne donne pas l’année de naissance : évitez-le dans une phrase où il manquerait.")
            }

            Section {
                Button("Rétablir les formules d’origine") {
                    var all = store.settings.greetingFormulas ?? [:]
                    all.removeValue(forKey: occasion.rawValue)
                    store.settings.greetingFormulas = all
                    store.scheduleSave()
                    text = Greetings.defaults(for: occasion).joined(separator: "\n")
                }
            }
        }
        .navigationTitle(occasion.label)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded else { return }
            text = Greetings.formulas(for: occasion, settings: store.settings).joined(separator: "\n")
            loaded = true
        }
    }

    private func save() {
        var all = store.settings.greetingFormulas ?? [:]
        all[occasion.rawValue] = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        store.settings.greetingFormulas = all
        store.scheduleSave()
    }
}
