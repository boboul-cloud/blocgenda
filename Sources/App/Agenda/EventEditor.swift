import SwiftUI

/// Création et modification d'un rendez-vous.
struct EventEditor: View {
    @Environment(Store.self) private var store
    @Environment(Navigator.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AgendaEvent
    @State private var showDeleteConfirm = false
    @State private var showNewTheme = false
    @State private var newTheme = ""

    init(event: AgendaEvent) {
        _draft = State(initialValue: event)
    }

    /// Le thème choisi, ramené au nom tel que le menu l'écrit : un rendez-vous
    /// rangé sous « sante » désigne bien « Santé », et le menu doit s'ouvrir
    /// dessus plutôt que sur une ligne vide.
    private var themeChoice: Binding<String?> {
        Binding {
            guard draft.hasTheme else { return nil }
            return store.eventThemes.first { AgendaEvent.themeKey($0) == AgendaEvent.themeKey(draft.themeName) }
                ?? draft.themeName
        } set: { draft.theme = $0 }
    }

    /// La fiche dont ce rendez-vous est l'anniversaire, si elle est encore là.
    private var birthdayContact: Contact? {
        guard let id = draft.birthdayContactID else { return nil }
        return store.contacts.first { $0.id == id }
    }

    private let reminderChoices: [(Int, String)] = [
        (0, "À l’heure"), (5, "5 min avant"), (15, "15 min avant"),
        (30, "30 min avant"), (60, "1 h avant"),
        (AgendaEvent.dayBeforeReminder, "La veille")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Intitulé", text: $draft.title)
                        .font(Type.ui(16, weight: .semibold))
                        .accessibilityIdentifier("editeur.titre")
                    TextField("Lieu", text: $draft.place)
                        .accessibilityIdentifier("editeur.lieu")
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...5)
                }

                Section("Quand") {
                    Toggle("Toute la journée", isOn: $draft.isAllDay)
                    DatePicker("Début", selection: $draft.start,
                               displayedComponents: draft.isAllDay ? [.date] : [.date, .hourAndMinute])
                    if !draft.isAllDay {
                        Picker("Durée", selection: $draft.duration) {
                            ForEach([900.0, 1800.0, 2700.0, 3600.0, 5400.0, 7200.0, 10800.0, 14400.0, 28800.0], id: \.self) { d in
                                Text(Fmt.duration(d)).tag(d)
                            }
                        }
                    }
                    Picker("Répétition", selection: $draft.repeatRule) {
                        ForEach(RepeatRule.allCases) { rule in
                            Text(rule.label).tag(rule)
                        }
                    }
                }

                Section("Rappels") {
                    ForEach(reminderChoices, id: \.0) { minutes, label in
                        Button {
                            if let i = draft.reminders.firstIndex(of: minutes) {
                                draft.reminders.remove(at: i)
                            } else {
                                draft.reminders.append(minutes)
                                draft.reminders.sort()
                            }
                        } label: {
                            HStack {
                                Text(label).foregroundStyle(Ink.text)
                                Spacer()
                                if draft.reminders.contains(minutes) {
                                    Image(systemName: "bell.fill").foregroundStyle(Ink.amberDeep)
                                }
                            }
                        }
                    }
                }

                Section {
                    Picker("Thème", selection: themeChoice) {
                        Text("Aucun").tag(String?.none)
                        ForEach(store.eventThemes, id: \.self) { name in
                            Text(name).tag(String?.some(name))
                        }
                    }
                    .accessibilityIdentifier("editeur.theme")
                    Button {
                        newTheme = ""
                        showNewTheme = true
                    } label: {
                        Label("Nouveau thème…", systemImage: "tag")
                    }
                    .accessibilityIdentifier("editeur.nouveautheme")
                } header: {
                    Text("Thème")
                } footer: {
                    Text("Anniversaire, véhicule, santé… Le thème range le rendez-vous par sujet : l’agenda les retrouve tous d’un geste. Tout thème créé ici est aussitôt proposé aux suivants.")
                }

                Section("Couleur") {
                    HStack(spacing: 12) {
                        ForEach(0..<Ink.palette.count, id: \.self) { i in
                            Circle()
                                .fill(Ink.label(i))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle().strokeBorder(Ink.text,
                                                          lineWidth: draft.colorIndex == i ? 2 : 0)
                                )
                                .onTapGesture { draft.colorIndex = i }
                        }
                    }
                }

                Section {
                    Picker("Contact", selection: $draft.contactID) {
                        Text("Aucun").tag(UUID?.none)
                        ForEach(store.contacts) { contact in
                            Text(contact.fullName).tag(UUID?.some(contact.id))
                        }
                    }
                    if let contact = birthdayContact {
                        Button {
                            dismiss()
                            nav.reveal(contact: contact.id)
                        } label: {
                            HStack(spacing: 10) {
                                Avatar(contact: contact, size: 26)
                                Text("Voir \(contact.fullName) dans l’annuaire")
                                    .foregroundStyle(Ink.text)
                                Spacer(minLength: 4)
                                Image(systemName: "chevron.right")
                                    .font(Type.icon(11, weight: .bold))
                                    .foregroundStyle(Ink.textFaint)
                            }
                        }
                    }
                } header: {
                    Text("Personne")
                } footer: {
                    if draft.isBirthday {
                        Text("Anniversaire tenu par l’annuaire : l’intitulé et la date suivent la fiche.")
                    }
                }

                if store.events.contains(where: { $0.id == draft.id }) {
                    Section {
                        Button("Supprimer le rendez-vous", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(store.events.contains(where: { $0.id == draft.id }) ? "Rendez-vous" : "Nouveau rendez-vous")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
                            draft.title = "Rendez-vous"
                        }
                        store.save(event: draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("editeur.enregistrer")
                }
            }
            .alert("Nouveau thème", isPresented: $showNewTheme) {
                TextField("Nom du thème", text: $newTheme)
                    .accessibilityIdentifier("theme.nom")
                Button("Ajouter") {
                    guard let name = store.addEventTheme(newTheme) else { return }
                    draft.theme = name
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Véhicule, école, bateau, impôts… Le thème est aussitôt proposé à tous les rendez-vous, même si celui-ci est le premier à le porter.")
            }
            .confirmationDialog("Supprimer ce rendez-vous ?", isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    store.deleteEvent(id: draft.id)
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
        .paperSheet()
    }
}
