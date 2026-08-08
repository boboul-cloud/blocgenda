import Contacts
import ContactsUI
import SwiftUI

/// Reprise du carnet d'adresses du téléphone. On recopie, une fois pour toutes,
/// les fiches que l'on coche : rien n'est modifié dans les Contacts, et rien
/// n'est tenu synchronisé ensuite. L'annuaire reste le carnet du bloc-notes.
enum SystemContacts {
    static var status: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    /// Demande l'accès et renvoie le statut obtenu.
    static func requestAccess() async -> CNAuthorizationStatus {
        _ = try? await CNContactStore().requestAccess(for: .contacts)
        return status
    }

    /// Lit le carnet et le traduit en fiches d'annuaire. Le travail se fait
    /// hors de l'acteur principal : un gros carnet met un instant à se lire.
    static func fetch() async -> [Contact] {
        await Task.detached(priority: .userInitiated) {
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey,
                CNContactPhoneNumbersKey, CNContactEmailAddressesKey,
                CNContactPostalAddressesKey, CNContactBirthdayKey,
            ].map { $0 as NSString }

            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .familyName
            request.unifyResults = true

            var fiches: [Contact] = []
            do {
                try CNContactStore().enumerateContacts(with: request) { entry, _ in
                    if let fiche = make(from: entry) { fiches.append(fiche) }
                }
            } catch {
                return []
            }
            return fiches
        }.value
    }

    private static func make(from entry: CNContact) -> Contact? {
        var fiche = Contact()
        fiche.firstName = entry.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        fiche.lastName = entry.familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        fiche.company = entry.organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fiche.firstName.isEmpty || !fiche.lastName.isEmpty || !fiche.company.isEmpty
        else { return nil }

        fiche.phone = phone(of: entry)
        fiche.email = (entry.emailAddresses.first?.value as String?)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let postal = entry.postalAddresses.first?.value {
            fiche.address = CNPostalAddressFormatter
                .string(from: postal, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: ", ")
        }
        if let day = entry.birthday { fiche.birthday = birthday(from: day) }
        fiche.colorIndex = colorIndex(for: fiche.sortKey)
        return fiche
    }

    /// Le portable d'abord : c'est celui qu'on appelle.
    private static func phone(of entry: CNContact) -> String {
        let numbers = entry.phoneNumbers
        let mobile = numbers.first {
            $0.label == CNLabelPhoneNumberMobile || $0.label == CNLabelPhoneNumberiPhone
        }
        return (mobile ?? numbers.first)?.value.stringValue ?? ""
    }

    /// Beaucoup de dates de naissance n'ont ni année : on retient l'année
    /// conventionnelle, l'anniversaire tombe quand même tous les ans.
    private static func birthday(from components: DateComponents) -> Date? {
        guard let month = components.month, let day = components.day else { return nil }
        var wanted = DateComponents()
        wanted.year = components.year ?? Contact.unknownBirthYear
        wanted.month = month
        wanted.day = day
        wanted.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: wanted)
    }

    /// Couleur de pastille tirée du nom : stable, et variée d'une fiche à l'autre.
    private static func colorIndex(for key: String) -> Int {
        let sum = key.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 100_003 }
        return Ink.palette.isEmpty ? 0 : sum % Ink.palette.count
    }
}

/// La feuille d'import : on choisit les fiches à reprendre, une par une ou
/// toutes d'un coup, et on décide du groupe où elles atterrissent.
struct ContactImportSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Nombre de fiches ajoutées, renvoyé à l'annuaire pour l'accusé de réception.
    var onImported: (Int) -> Void

    private enum Phase: Equatable {
        case loading
        case denied
        case ready
    }

    @State private var phase: Phase = .loading
    @State private var candidates: [Contact] = []
    @State private var selection: Set<UUID> = []
    @State private var query = ""
    @State private var group = "Général"
    @State private var limited = false
    /// Refus venu d'une restriction du téléphone (Temps d'écran) plutôt que
    /// d'un choix : la marche à suivre n'est pas la même.
    @State private var restricted = false
    /// Feuille du système qui élargit la liste des fiches autorisées, quand
    /// l'accès au carnet est limité.
    @State private var widening = false
    @State private var showNewGroup = false
    @State private var newGroup = ""

    /// Les fiches déjà présentes dans l'annuaire, reconnues au numéro.
    private var alreadyHere: Set<String> {
        Set(store.contacts.map(\.matchKey))
    }

    /// Tout ce qui reste à reprendre, la recherche mise à part. C'est ce qui
    /// décide s'il y a encore quelque chose à faire dans cette feuille.
    private var newcomers: [Contact] {
        let here = alreadyHere
        return candidates.filter { !here.contains($0.matchKey) }
    }

    private var filtered: [Contact] {
        let needle = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !needle.isEmpty else { return candidates }
        return candidates.filter { contact in
            "\(contact.fullName) \(contact.company) \(contact.phone) \(contact.email)"
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .contains(needle)
        }
    }

    /// Ce que « tout sélectionner » peut atteindre : les fiches affichées qui
    /// ne sont pas déjà dans l'annuaire.
    private var selectable: [Contact] {
        let here = alreadyHere
        return filtered.filter { !here.contains($0.matchKey) }
    }

    private var groups: [String] {
        var names = store.contactGroups
        if !names.contains(group) { names.append(group) }
        return names
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .loading: loadingView
                case .denied: deniedView
                case .ready where candidates.isEmpty: emptyView
                case .ready where newcomers.isEmpty: allHereView
                case .ready: pickerView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Ink.chassis)
            .navigationTitle("Importer des contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if phase == .ready && !newcomers.isEmpty {
                        Button("Importer\(selection.isEmpty ? "" : " (\(selection.count))")") {
                            performImport()
                        }
                        .fontWeight(.semibold)
                        .disabled(selection.isEmpty)
                    }
                }
            }
            .contactAccessPicker(isPresented: $widening) { _ in
                Task { await refresh() }
            }
            .alert("Nouveau groupe", isPresented: $showNewGroup) {
                TextField("Nom du groupe", text: $newGroup)
                Button("Ajouter") {
                    if let name = store.addContactGroup(newGroup) { group = name }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Les fiches importées seront rangées dans ce groupe.")
            }
        }
        .paperSheet()
        .task { await load() }
    }

    // MARK: - Les états

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Lecture du carnet d’adresses…")
                .font(Type.ui(13))
                .foregroundStyle(Ink.textSoft)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(Type.icon(26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text("Blocgenda n’a pas accès aux contacts.")
                .font(Type.ui(15, weight: .medium))
                .foregroundStyle(Ink.text)
            if restricted {
                // Le bouton des Réglages n'y peut rien : c'est Temps d'écran
                // qui ferme l'accès, et il faut le code parental pour l'ouvrir.
                Text("L’accès aux contacts est bloqué par une restriction\ndu téléphone. Elle se lève dans :")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
                settingsPath("Réglages › Temps d’écran › Restrictions de contenu\net de confidentialité › Contacts")
            } else {
                Text("L’autorisation se donne dans :")
                    .font(Type.ui(12))
                    .foregroundStyle(Ink.textFaint)
                settingsPath("Réglages › Blocgenda › Contacts\n› Accès complet")
            }
            Button("Ouvrir les Réglages") {
                openSettings()
            }
            .font(Type.ui(14, weight: .semibold))
            .foregroundStyle(Ink.amberDeep)
            .padding(.top, 4)
        }
        .padding(30)
    }

    /// Le chemin à suivre dans les Réglages, écrit noir sur blanc. Le bouton
    /// « Ouvrir les Réglages » dépose sur la page de l'app, pas sur la ligne
    /// exacte : sans le chemin, on cherche encore.
    private func settingsPath(_ path: String) -> some View {
        Text(path)
            .font(Type.tape(12))
            .multilineTextAlignment(.center)
            .foregroundStyle(Ink.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Ink.sunken)
            )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(Type.icon(26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text(limited ? "Aucune fiche autorisée pour l’instant."
                         : "Aucun contact à reprendre.")
                .font(Type.ui(15, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            if limited { limitedHint }
        }
        .padding(30)
    }

    /// Tout ce que Blocgenda voit du carnet est déjà recopié. En accès limité,
    /// c'est le cas dès le deuxième passage : sans le bouton d'élargissement,
    /// l'annuaire resterait bloqué sur les quelques fiches du premier choix.
    private var allHereView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(Type.icon(26, weight: .light))
                .foregroundStyle(Ink.moss)
            Text(candidates.count > 1
                 ? "Ces \(candidates.count) fiches sont déjà dans l’annuaire."
                 : "Cette fiche est déjà dans l’annuaire.")
                .font(Type.ui(15, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.textSoft)
            if limited {
                limitedHint
            } else {
                Text("Rien de nouveau à reprendre dans le carnet\nd’adresses du téléphone.")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
            }
        }
        .padding(30)
    }

    /// L'explication et les deux sorties de l'accès limité. Le sélecteur du
    /// système ajoute des fiches une à une ; l'accès complet, lui, ne se donne
    /// que dans les Réglages — et rien ne l'indiquait, si bien qu'on pouvait
    /// croire l'import définitivement bridé.
    private var limitedHint: some View {
        VStack(spacing: 10) {
            Text("Blocgenda ne voit que les fiches que vous lui avez\ndésignées une à une : c’est l’accès limité.")
                .font(Type.ui(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.textFaint)
            wideningButton
            fullAccessHint
        }
        .padding(.top, 2)
    }

    /// L'autre sortie : l'accès complet, qui ne se donne que dans les Réglages.
    private var fullAccessHint: some View {
        VStack(spacing: 6) {
            Text("Pour voir tout le carnet d’un coup, passez à l’accès\ncomplet dans :")
                .font(Type.ui(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.textFaint)
            settingsPath("Réglages › Blocgenda › Contacts\n› Accès complet")
            Button("Ouvrir les Réglages") { openSettings() }
                .font(Type.ui(13, weight: .semibold))
                .foregroundStyle(Ink.amberDeep)
        }
        .padding(.top, 6)
    }

    private var wideningButton: some View {
        Button { widening = true } label: {
            Label("Choisir d’autres contacts…", systemImage: "person.crop.circle.badge.plus")
                .font(Type.ui(13, weight: .semibold))
                .foregroundStyle(Ink.onAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Ink.amber))
        }
        .buttonStyle(.plain)
    }

    private var pickerView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                SearchField(text: $query, prompt: "Nom, société, numéro…")

                HStack(spacing: 10) {
                    Button {
                        toggleAll()
                    } label: {
                        Label(allSelected ? "Tout décocher" : "Tout cocher",
                              systemImage: allSelected ? "square" : "checklist")
                            .font(Type.ui(12, weight: .semibold))
                            .foregroundStyle(Ink.amberDeep)
                    }
                    .disabled(selectable.isEmpty)

                    Spacer(minLength: 0)

                    Menu {
                        Picker("Groupe", selection: $group) {
                            ForEach(groups, id: \.self) { Text($0).tag($0) }
                        }
                        Divider()
                        Button {
                            newGroup = ""
                            showNewGroup = true
                        } label: {
                            Label("Nouveau groupe…", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Classer dans : \(group)")
                            Image(systemName: "chevron.up.chevron.down")
                                .font(Type.icon(9, weight: .semibold))
                        }
                        .font(Type.ui(12, weight: .medium))
                        .foregroundStyle(Ink.textSoft)
                    }
                }
                .buttonStyle(.plain)

                if limited {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Accès limité : seules les fiches que vous avez autorisées apparaissent ici.")
                            .font(Type.ui(11))
                            .foregroundStyle(Ink.textFaint)
                        Spacer(minLength: 0)
                        Menu {
                            Button {
                                widening = true
                            } label: {
                                Label("Choisir d’autres contacts…",
                                      systemImage: "person.crop.circle.badge.plus")
                            }
                            Button {
                                openSettings()
                            } label: {
                                Label("Tout autoriser dans les Réglages…", systemImage: "gear")
                            }
                        } label: {
                            Text("Élargir…")
                                .font(Type.ui(12, weight: .semibold))
                                .foregroundStyle(Ink.amberDeep)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            let here = alreadyHere
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filtered.isEmpty { noMatchView }
                    ForEach(filtered) { contact in
                        let known = here.contains(contact.matchKey)
                        ImportRow(contact: contact,
                                  known: known,
                                  selected: selection.contains(contact.id)) {
                            guard !known else { return }
                            if selection.contains(contact.id) {
                                selection.remove(contact.id)
                            } else {
                                selection.insert(contact.id)
                            }
                        }
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    /// La recherche ne trouve rien. En accès limité, c'est le cas le plus
    /// fréquent — le carnet visible tient en quelques fiches — et une liste
    /// vide sans un mot laisserait croire à une panne.
    private var noMatchView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.fill.questionmark")
                .font(Type.icon(24, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text("Aucune fiche ne porte ce nom.")
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            if limited {
                Text("Blocgenda ne cherche que parmi les \(candidates.count) fiche\(candidates.count > 1 ? "s" : "") que\nvous lui avez désignées.")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
                wideningButton.padding(.top, 4)
                fullAccessHint
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }

    private var allSelected: Bool {
        !selectable.isEmpty && selectable.allSatisfy { selection.contains($0.id) }
    }

    // MARK: - Les gestes

    private func load() async {
        var current = SystemContacts.status
        if current == .notDetermined { current = await SystemContacts.requestAccess() }
        switch current {
        case .authorized:
            limited = false
        case .limited:
            limited = true
        default:
            restricted = current == .restricted
            phase = .denied
            return
        }
        await refresh()
    }

    /// Relit le carnet : au premier affichage, puis après chaque élargissement
    /// de l'accès limité. Les fiches candidates reçoivent une identité neuve à
    /// chaque lecture, donc les cases cochées ne survivent pas — on les vide
    /// plutôt que de les laisser désigner des fiches disparues.
    private func refresh() async {
        candidates = await SystemContacts.fetch()
        selection = selection.intersection(candidates.map(\.id))
        phase = .ready
    }

    private func toggleAll() {
        let reachable = selectable.map(\.id)
        if allSelected {
            selection.subtract(reachable)
        } else {
            selection.formUnion(reachable)
        }
    }

    private func performImport() {
        let chosen = candidates
            .filter { selection.contains($0.id) }
            .map { contact -> Contact in
                var copy = contact
                copy.group = group
                return copy
            }
        let added = store.importContacts(chosen)
        onImported(added)
        dismiss()
    }
}

private struct ImportRow: View {
    let contact: Contact
    let known: Bool
    let selected: Bool
    var onTap: () -> Void

    private var detail: String {
        if !contact.phone.isEmpty { return contact.phone }
        if !contact.email.isEmpty { return contact.email }
        return contact.company
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Avatar(contact: contact, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.fullName)
                        .font(Type.ui(14, weight: .semibold))
                        .foregroundStyle(known ? Ink.textFaint : Ink.text)
                        .lineLimit(1)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(Type.tape(11))
                            .foregroundStyle(Ink.textFaint)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if known {
                    Pill(text: "Déjà là", color: Ink.moss)
                } else {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(Type.icon(19))
                        .foregroundStyle(selected ? Ink.amberDeep : Ink.chassisLine)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Ink.chassisSoft)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(selected ? Ink.amber : Ink.chassisLine,
                                      lineWidth: selected ? 1.5 : 1))
            )
            .opacity(known ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(known)
    }
}
