import SwiftUI

struct ContactEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Contact
    @State private var hasBirthday: Bool
    @State private var birthday: Date
    @State private var showDeleteConfirm = false

    private let existing: Bool

    init(contact: Contact) {
        _draft = State(initialValue: contact)
        _hasBirthday = State(initialValue: contact.birthday != nil)
        _birthday = State(initialValue: contact.birthday ?? Date(timeIntervalSince1970: 0))
        existing = !contact.firstName.isEmpty || !contact.lastName.isEmpty || !contact.company.isEmpty
    }

    private var suggestedGroups: [String] {
        var names = Set(store.contacts.map(\.group))
        names.formUnion(["Général", "Famille", "Travail", "Santé", "Mer", "Maison", "Urgences"])
        return names.sorted()
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
                    Toggle("Favori", isOn: $draft.isFavorite)
                    HStack(spacing: 12) {
                        ForEach(0..<Ink.palette.count, id: \.self) { i in
                            Circle()
                                .fill(Ink.label(i))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Ink.paper,
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
                    Text("Les anniversaires apparaissent chaque jour dans l’éphéméride.")
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
        }
        .preferredColorScheme(.dark)
    }
}
