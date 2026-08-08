import SwiftUI

struct ContactEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Contact
    @State private var hasBirthday: Bool
    @State private var birthday: Date
    @State private var showDeleteConfirm = false
    @State private var showNewGroup = false
    @State private var newGroup = ""

    private let existing: Bool

    init(contact: Contact) {
        _draft = State(initialValue: contact)
        _hasBirthday = State(initialValue: contact.birthday != nil)
        _birthday = State(initialValue: contact.birthday ?? Date(timeIntervalSince1970: 0))
        existing = !contact.firstName.isEmpty || !contact.lastName.isEmpty || !contact.company.isEmpty
    }

    /// Les fiches reprises du carnet du téléphone n'ont souvent que le jour et
    /// le mois : la date porte alors l'année conventionnelle.
    private var knowsBirthYear: Bool {
        Calendar.current.component(.year, from: birthday) != Contact.unknownBirthYear
    }

    /// Le groupe de la fiche en fait partie même s'il vient d'être créé : sans
    /// cela, le Picker n'aurait rien à sélectionner et s'afficherait vide.
    private var suggestedGroups: [String] {
        var names = store.contactGroups
        if !names.contains(draft.group) { names.append(draft.group) }
        return names
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Avatar(contact: draft, size: 52)
                        VStack(spacing: 6) {
                            TextField("Prénom", text: $draft.firstName)
                            TextField("Nom", text: $draft.lastName)
                        }
                    }
                    TextField("Société", text: $draft.company)
                }

                Section("Coordonnées") {
                    TextField("Téléphone", text: $draft.phone)
                        .keyboardType(.phonePad)
                    TextField("Courriel", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Adresse", text: $draft.address, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Classement") {
                    Picker("Groupe", selection: $draft.group) {
                        ForEach(suggestedGroups, id: \.self) { Text($0).tag($0) }
                    }
                    Button("Nouveau groupe…") {
                        newGroup = ""
                        showNewGroup = true
                    }
                    Toggle("Favori", isOn: $draft.isFavorite)
                    HStack(spacing: 12) {
                        ForEach(0..<Ink.palette.count, id: \.self) { i in
                            Circle()
                                .fill(Ink.label(i))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Ink.text,
                                                               lineWidth: draft.colorIndex == i ? 2 : 0))
                                .onTapGesture { draft.colorIndex = i }
                        }
                    }
                }

                Section {
                    Toggle("Anniversaire", isOn: $hasBirthday)
                    if hasBirthday {
                        DatePicker("Date", selection: $birthday, displayedComponents: [.date])
                    }
                } footer: {
                    if hasBirthday && !knowsBirthYear {
                        Text("Année de naissance inconnue : l’anniversaire revient tous les ans, mais l’âge n’est pas affiché tant que l’année n’est pas corrigée.")
                    } else {
                        Text("Les anniversaires apparaissent dans l’éphéméride, et s’inscrivent à l’agenda : toute la journée, tous les ans, rappelés la veille.")
                    }
                }

                Section("Note") {
                    TextField("Remarque", text: $draft.note, axis: .vertical)
                        .lineLimit(1...5)
                }

                if store.contacts.contains(where: { $0.id == draft.id }) {
                    Section {
                        Button("Supprimer la fiche", role: .destructive) { showDeleteConfirm = true }
                    }
                }
            }
            .navigationTitle(existing ? "Fiche" : "Nouvelle fiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        draft.birthday = hasBirthday ? birthday : nil
                        store.save(contact: draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Supprimer cette fiche ?", isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    store.deleteContact(id: draft.id)
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
            .alert("Nouveau groupe", isPresented: $showNewGroup) {
                TextField("Nom du groupe", text: $newGroup)
                Button("Ajouter") {
                    // Un nom déjà pris renvoie le tiroir existant : on s'y
                    // range plutôt que d'en créer un jumeau.
                    if let name = store.addContactGroup(newGroup) { draft.group = name }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Voisins, Bateau, École… Le groupe apparaîtra dans le classement et dans le filtre de l’annuaire.")
            }
        }
        .paperSheet()
    }
}
