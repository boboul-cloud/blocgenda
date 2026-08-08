import SwiftUI

/// L'annuaire : les fiches que l'on garde sous la main, groupées, avec les
/// gestes utiles (appeler, écrire, situer) à portée de pouce.
struct DirectoryView: View {
    @Environment(Store.self) private var store
    @Environment(Navigator.self) private var nav
    @State private var query = ""
    @State private var editing: Contact?
    @State private var showFavoritesOnly = false
    /// Tiroir affiché seul. `nil` : tout l'annuaire.
    @State private var groupFilter: String?
    @State private var groupToDelete: String?
    @State private var showNewGroup = false
    @State private var newGroup = ""
    @State private var importing = false
    /// Accusé de réception de l'import, effacé au bout de quelques secondes.
    @State private var importReport: String?
    /// Fiche montrée du doigt en arrivant d'un autre écran, le temps de l'œil.
    @State private var highlighted: UUID?

    private var filtered: [Contact] {
        let needle = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return store.contacts
            .filter { showFavoritesOnly ? $0.isFavorite : true }
            .filter { groupFilter == nil || $0.group == groupFilter }
            .filter { contact in
                guard !needle.isEmpty else { return true }
                let haystack = "\(contact.fullName) \(contact.company) \(contact.phone) \(contact.email) \(contact.group)"
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                return haystack.contains(needle)
            }
            .sorted { $0.sortKey < $1.sortKey }
    }

    private var groups: [(name: String, contacts: [Contact])] {
        Dictionary(grouping: filtered, by: \.group)
            .map { (name: $0.key, contacts: $0.value) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Annuaire",
                         subtitle: "\(store.contacts.count) fiche\(store.contacts.count > 1 ? "s" : "")") {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.snappy) { showFavoritesOnly.toggle() }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .font(Type.icon(14, weight: .semibold))
                            .foregroundStyle(showFavoritesOnly ? Ink.amberDeep : Ink.textFaint)
                            .frame(width: Type.control(34), height: Type.control(34))
                            .background(Circle().fill(Ink.chassisSoft))
                    }
                    Button { importing = true } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(Type.icon(14, weight: .semibold))
                            .foregroundStyle(Ink.textFaint)
                            .frame(width: Type.control(34), height: Type.control(34))
                            .background(Circle().fill(Ink.chassisSoft))
                    }
                    .accessibilityLabel("Importer des contacts")
                    Button { editing = Contact() } label: {
                        Image(systemName: "person.badge.plus")
                            .font(Type.icon(14, weight: .bold))
                            .foregroundStyle(Ink.onAccent)
                            .frame(width: Type.control(34), height: Type.control(34))
                            .background(Circle().fill(Ink.amber))
                    }
                    .accessibilityLabel("Nouvelle fiche")
                }
                .buttonStyle(.plain)
            }

            SearchField(text: $query, prompt: "Nom, société, numéro, groupe…")
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            groupFilterBar
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            if let importReport {
                Text(importReport)
                    .font(Type.ui(12, weight: .medium))
                    .foregroundStyle(Ink.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                        if filtered.isEmpty {
                            EmptyDirectory(searching: !query.isEmpty || groupFilter != nil) {
                                importing = true
                            }
                        }
                        ForEach(groups, id: \.name) { group in
                            Section {
                                VStack(spacing: 8) {
                                    ForEach(group.contacts) { contact in
                                        ContactCard(contact: contact,
                                                    isHighlighted: highlighted == contact.id) {
                                            editing = contact
                                        }
                                        .id(contact.id)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group.name.uppercased())
                                        .font(Type.micro).tracking(1.5)
                                        .foregroundStyle(Ink.textFaint)
                                    Spacer()
                                    Text("\(group.contacts.count)")
                                        .font(Type.ui(10, weight: .semibold))
                                        .foregroundStyle(Ink.textFaint)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .background(Ink.chassis)
                            }
                        }
                        Color.clear.frame(height: Type.tabBarInset + 12)
                    }
                    .padding(.horizontal, 20)
                }
                .task(id: nav.contactToReveal) { await reveal(with: proxy) }
            }
        }
        .background(Ink.chassis)
        .sheet(item: $editing) { contact in
            ContactEditor(contact: contact).environment(store)
        }
        .sheet(isPresented: $importing) {
            ContactImportSheet { added in report(added) }
                .environment(store)
        }
        .alert("Nouveau groupe", isPresented: $showNewGroup) {
            TextField("Nom du groupe", text: $newGroup)
            Button("Ajouter") {
                guard let name = store.addContactGroup(newGroup) else { return }
                show("Groupe « \(name) » créé.")
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Voisins, Bateau, École… Le groupe est aussitôt proposé au classement des fiches, même s’il est encore vide.")
        }
        .confirmationDialog("Supprimer le groupe « \(groupToDelete ?? "") » ?",
                            isPresented: Binding(get: { groupToDelete != nil },
                                                 set: { if !$0 { groupToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Supprimer le groupe", role: .destructive) {
                if let name = groupToDelete {
                    store.removeContactGroup(name)
                    withAnimation(.snappy) { groupFilter = nil }
                }
                groupToDelete = nil
            }
            Button("Annuler", role: .cancel) { groupToDelete = nil }
        } message: {
            let orphans = groupToDelete.map { count(of: $0) } ?? 0
            Text(orphans == 0
                 ? "Le groupe est vide : rien d’autre ne change."
                 : "Les \(orphans) fiche\(orphans > 1 ? "s" : "") qu’il contient ne sont pas supprimées : elles retournent au groupe Général.")
        }
    }

    /// Le choix du tiroir. Les groupes vides y figurent aussi, avec leur
    /// compte : un tiroir qu'on vient de créer doit se voir, sinon on le croit
    /// perdu.
    private var groupFilterBar: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Groupe", selection: $groupFilter) {
                    Text("Tous les groupes (\(store.contacts.count))")
                        .tag(String?.none)
                    ForEach(store.contactGroups, id: \.self) { name in
                        Text("\(name) (\(count(of: name)))")
                            .tag(String?.some(name))
                    }
                }
                Divider()
                Button {
                    newGroup = ""
                    showNewGroup = true
                } label: {
                    Label("Nouveau groupe…", systemImage: "folder.badge.plus")
                }
                // Le retrait n'est offert que sur le tiroir affiché, et jamais
                // sur les groupes d'office.
                if let current = groupFilter, store.isCustomContactGroup(current) {
                    Button(role: .destructive) {
                        groupToDelete = current
                    } label: {
                        Label("Supprimer « \(current) »", systemImage: "trash")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: groupFilter == nil
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(Type.icon(12, weight: .semibold))
                    Text(groupFilter ?? "Tous les groupes")
                        .font(Type.ui(12, weight: .semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(Type.icon(9, weight: .semibold))
                }
                .foregroundStyle(groupFilter == nil ? Ink.textSoft : Ink.amberDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(groupFilter == nil ? Ink.chassisSoft : Ink.amber.opacity(0.16))
                        .overlay(Capsule().strokeBorder(
                            groupFilter == nil ? Ink.chassisLine : Ink.amber, lineWidth: 1))
                )
            }
            .accessibilityLabel("Filtrer par groupe")

            if groupFilter != nil {
                Button {
                    withAnimation(.snappy) { groupFilter = nil }
                } label: {
                    Text("Tout voir")
                        .font(Type.ui(12, weight: .semibold))
                        .foregroundStyle(Ink.textFaint)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    private func count(of group: String) -> Int {
        store.contacts.count { $0.group == group }
    }

    /// Amène à l'écran la fiche demandée par un autre onglet — l'anniversaire
    /// que l'agenda vient de montrer, par exemple. Une recherche en cours, le
    /// filtre des favoris ou celui des groupes la cacheraient : on les lève
    /// d'abord.
    private func reveal(with proxy: ScrollViewProxy) async {
        guard let id = nav.contactToReveal else { return }
        guard store.contacts.contains(where: { $0.id == id }) else {
            nav.contactToReveal = nil
            return
        }
        if !query.isEmpty { query = "" }
        if showFavoritesOnly { showFavoritesOnly = false }
        if groupFilter != nil { groupFilter = nil }
        // Le temps que la liste se remette en place avant de viser.
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }
        withAnimation(.snappy) {
            proxy.scrollTo(id, anchor: .center)
            highlighted = id
        }
        // L'extinction ne dépend plus de cette tâche-ci : la remise à zéro de
        // la demande, juste après, l'interromprait.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard highlighted == id else { return }
            withAnimation(.easeOut(duration: 0.4)) { highlighted = nil }
        }
        nav.contactToReveal = nil
    }

    /// Dit ce qui vient d'entrer dans l'annuaire, puis s'efface.
    private func report(_ added: Int) {
        switch added {
        case 0: show("Aucune fiche ajoutée : elles étaient déjà là.")
        case 1: show("1 fiche importée.")
        default: show("\(added) fiches importées.")
        }
    }

    /// Un mot en haut de l'annuaire, le temps d'être lu. Sert à l'import comme
    /// à la création d'un groupe : sans lui, nommer un tiroir encore vide ne
    /// donnerait aucun signe que quelque chose s'est passé.
    private func show(_ message: String) {
        withAnimation(.snappy) { importReport = message }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.snappy) { importReport = nil }
        }
    }
}

struct ContactCard: View {
    let contact: Contact
    /// Fiche que l'on vient d'atteindre depuis un autre écran : elle s'annonce
    /// par un liseré, le temps qu'on la trouve des yeux.
    var isHighlighted: Bool = false
    var onTap: () -> Void
    @Environment(Store.self) private var store

    private var telURL: URL? {
        let digits = contact.phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel://\(digits)")
    }
    private var smsURL: URL? {
        let digits = contact.phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "sms://\(digits)")
    }
    private var mailURL: URL? {
        contact.email.isEmpty ? nil : URL(string: "mailto:\(contact.email)")
    }
    private var mapURL: URL? {
        guard !contact.address.isEmpty,
              let encoded = contact.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Avatar(contact: contact, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(contact.fullName)
                            .font(Type.ui(14, weight: .semibold))
                            .foregroundStyle(Ink.text)
                        if contact.isFavorite {
                            Image(systemName: "star.fill")
                                .font(Type.icon(9))
                                .foregroundStyle(Ink.amberDeep)
                        }
                    }
                    if !contact.company.isEmpty {
                        Text(contact.company)
                            .font(Type.ui(11))
                            .foregroundStyle(Ink.textFaint)
                    }
                    if !contact.phone.isEmpty {
                        Text(contact.phone)
                            .font(Type.tape(11))
                            .foregroundStyle(Ink.textSoft)
                    }
                }
                Spacer(minLength: 0)
                if contact.hasBirthday(on: Date()), let age = contact.age() {
                    Pill(text: "🎂 \(age) ans", color: Ink.rouge)
                }
            }

            HStack(spacing: 8) {
                actionButton("phone.fill", url: telURL, color: Ink.moss)
                actionButton("message.fill", url: smsURL, color: Ink.sea)
                actionButton("envelope.fill", url: mailURL, color: Ink.violet)
                actionButton("map.fill", url: mapURL, color: Ink.amberDeep)
                Spacer(minLength: 0)
                Button(action: onTap) {
                    Image(systemName: "pencil")
                        .font(Type.icon(12, weight: .semibold))
                        .foregroundStyle(Ink.textFaint)
                        .frame(width: Type.control(32), height: Type.control(30))
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Ink.sunken))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHighlighted ? Ink.amber.opacity(0.14) : Ink.chassisSoft)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isHighlighted ? Ink.amber : Ink.chassisLine,
                                  lineWidth: isHighlighted ? 2 : 1))
        )
        .contextMenu {
            Button {
                var copy = contact
                copy.isFavorite.toggle()
                store.save(contact: copy)
            } label: {
                Label(contact.isFavorite ? "Retirer des favoris" : "Mettre en favori",
                      systemImage: contact.isFavorite ? "star.slash" : "star")
            }
            Button { onTap() } label: { Label("Modifier", systemImage: "pencil") }
            Button(role: .destructive) {
                store.deleteContact(id: contact.id)
            } label: { Label("Supprimer", systemImage: "trash") }
        }
    }

    @ViewBuilder
    private func actionButton(_ symbol: String, url: URL?, color: Color) -> some View {
        if let url {
            Link(destination: url) {
                Image(systemName: symbol)
                    .font(Type.icon(12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: Type.control(38), height: Type.control(30))
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(color.opacity(0.14)))
            }
        }
    }
}

struct Avatar: View {
    let contact: Contact
    var size: CGFloat = 40

    var body: some View {
        Text(contact.initials)
            .font(Type.ui(size * 0.36, weight: .bold))
            .foregroundStyle(Ink.onAccent)
            .frame(width: Type.control(size), height: Type.control(size))
            .background(
                Circle().fill(
                    LinearGradient(colors: [Ink.label(contact.colorIndex),
                                            Ink.label(contact.colorIndex).opacity(0.65)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
}

struct EmptyDirectory: View {
    var searching: Bool
    var onImport: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: searching ? "person.fill.questionmark" : "person.crop.rectangle.stack")
                .font(Type.icon(26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text(searching ? "Aucune fiche trouvée." : "L’annuaire est vide.")
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            if !searching {
                Text("Ajoutez vos numéros utiles : famille,\nmédecin, capitainerie, garage…")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
                if let onImport {
                    Button(action: onImport) {
                        Label("Choisir dans mes contacts", systemImage: "square.and.arrow.down")
                            .font(Type.ui(13, weight: .semibold))
                            .foregroundStyle(Ink.onAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Ink.amber))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
