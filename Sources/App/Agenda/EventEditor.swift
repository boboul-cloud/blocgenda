import SwiftUI

/// Création et modification d'un rendez-vous.
struct EventEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AgendaEvent
    @State private var showDeleteConfirm = false

    init(event: AgendaEvent) {
        _draft = State(initialValue: event)
    }

    private let reminderChoices: [(Int, String)] = [
        (0, "À l’heure"), (5, "5 min avant"), (15, "15 min avant"),
        (30, "30 min avant"), (60, "1 h avant"), (1440, "La veille")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Intitulé", text: $draft.title)
                        .font(Type.ui(16, weight: .semibold))
                    TextField("Lieu", text: $draft.place)
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
                                Text(label).foregroundStyle(Ink.paper)
                                Spacer()
                                if draft.reminders.contains(minutes) {
                                    Image(systemName: "bell.fill").foregroundStyle(Ink.amber)
                                }
                            }
                        }
                    }
                }

                Section("Couleur") {
                    HStack(spacing: 12) {
                        ForEach(0..<Ink.palette.count, id: \.self) { i in
                            Circle()
                                .fill(Ink.label(i))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle().strokeBorder(Ink.paper,
                                                          lineWidth: draft.colorIndex == i ? 2 : 0)
                                )
                                .onTapGesture { draft.colorIndex = i }
                        }
                    }
                }

                Section("Personne") {
                    Picker("Contact", selection: $draft.contactID) {
                        Text("Aucun").tag(UUID?.none)
                        ForEach(store.contacts) { contact in
                            Text(contact.fullName).tag(UUID?.some(contact.id))
                        }
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
                }
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
        .preferredColorScheme(.dark)
    }
}
