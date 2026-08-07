import SwiftUI

/// L'annuaire : les fiches que l'on garde sous la main, groupées, avec les
/// gestes utiles (appeler, écrire, situer) à portée de pouce.
struct DirectoryView: View {
    @Environment(Store.self) private var store
    @State private var query = ""
    @State private var editing: Contact?
    @State private var showFavoritesOnly = false

    private var filtered: [Contact] {
        let needle = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return store.contacts
            .filter { showFavoritesOnly ? $0.isFavorite : true }
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(showFavoritesOnly ? Ink.amber : Ink.textFaint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Ink.chassisSoft))
                    }
                    Button { editing = Contact() } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Ink.amber))
                    }
                }
                .buttonStyle(.plain)
            }

            SearchField(text: $query, prompt: "Nom, société, numéro, groupe…")
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                    if filtered.isEmpty {
                        EmptyDirectory(searching: !query.isEmpty)
                    }
                    ForEach(groups, id: \.name) { group in
                        Section {
                            VStack(spacing: 8) {
                                ForEach(group.contacts) { contact in
                                    ContactCard(contact: contact) { editing = contact }
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
                    Color.clear.frame(height: 70)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Ink.chassis)
        .sheet(item: $editing) { contact in
            ContactEditor(contact: contact).environment(store)
        }
    }
}

struct ContactCard: View {
    let contact: Contact
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
                            .foregroundStyle(Ink.paper)
                        if contact.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Ink.amber)
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
                actionButton("map.fill", url: mapURL, color: Ink.amber)
                Spacer(minLength: 0)
                Button(action: onTap) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Ink.textFaint)
                        .frame(width: 32, height: 30)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.black.opacity(0.22)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Ink.chassisLine, lineWidth: 1))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 38, height: 30)
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
            .foregroundStyle(.black.opacity(0.8))
            .frame(width: size, height: size)
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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: searching ? "person.fill.questionmark" : "person.crop.rectangle.stack")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text(searching ? "Aucune fiche trouvée." : "L’annuaire est vide.")
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            if !searching {
                Text("Ajoutez vos numéros utiles : famille,\nmédecin, capitainerie, garage…")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
