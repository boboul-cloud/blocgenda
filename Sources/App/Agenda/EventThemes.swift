import SwiftUI

/// Les thèmes de l'agenda, gérés pour eux-mêmes. On en crée un sans avoir de
/// rendez-vous sous la main — il attend d'être employé — et on retire ceux
/// qu'on a nommés de travers. Les thèmes d'office ne se suppriment pas : ce
/// sont les cases du bloc-notes, pas des créations de l'utilisateur.
struct EventThemesView: View {
    @Environment(Store.self) private var store
    @State private var newTheme = ""
    @State private var themeToDelete: String?
    /// Nom refusé parce qu'il existe déjà, le temps de le dire.
    @State private var duplicate: String?

    private var trimmed: String {
        newTheme.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Nom du nouveau thème", text: $newTheme)
                        .submitLabel(.done)
                        .onSubmit(create)
                    Button("Ajouter", action: create)
                        .font(Type.ui(14, weight: .semibold))
                        .buttonStyle(.borderless)
                        .disabled(trimmed.isEmpty)
                }
            } header: {
                Text("Nouveau thème")
            } footer: {
                if let duplicate {
                    Text("« \(duplicate) » existe déjà.")
                        .foregroundStyle(Ink.rouge)
                } else {
                    Text("Véhicule, école, bateau, impôts… Le thème est aussitôt proposé à la fiche de chaque rendez-vous et à la recherche de l’agenda, même s’il ne sert encore à rien.")
                }
            }

            Section {
                ForEach(store.eventThemes, id: \.self) { name in
                    HStack {
                        Label(name, systemImage: store.isCustomEventTheme(name) ? "tag" : "tag.fill")
                            .foregroundStyle(Ink.text)
                        Spacer()
                        Text("\(count(of: name))")
                            .font(Type.tape(13))
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        if store.isCustomEventTheme(name) {
                            Button(role: .destructive) {
                                themeToDelete = name
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Thèmes")
            } footer: {
                Text("Glissez vers la gauche pour retirer un thème que vous avez créé. Les thèmes d’origine restent en place.")
            }
        }
        .navigationTitle("Thèmes de l’agenda")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Supprimer le thème « \(themeToDelete ?? "") » ?",
                            isPresented: Binding(get: { themeToDelete != nil },
                                                 set: { if !$0 { themeToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Supprimer le thème", role: .destructive) {
                if let name = themeToDelete { store.removeEventTheme(name) }
                themeToDelete = nil
            }
            Button("Annuler", role: .cancel) { themeToDelete = nil }
        } message: {
            let orphans = themeToDelete.map { count(of: $0) } ?? 0
            Text(orphans == 0
                 ? "Aucun rendez-vous ne le porte : rien d’autre ne change."
                 : "Le\(orphans > 1 ? "s" : "") \(orphans) rendez-vous qu’il range ne sont pas supprimés : ils se retrouvent simplement sans thème.")
        }
    }

    private func count(of theme: String) -> Int {
        store.events.count { $0.belongs(toTheme: theme) }
    }

    private func create() {
        let wanted = trimmed
        guard !wanted.isEmpty else { return }
        let known = store.eventThemes.contains {
            AgendaEvent.themeKey($0) == AgendaEvent.themeKey(wanted)
        }
        guard !known else {
            duplicate = wanted
            return
        }
        store.addEventTheme(wanted)
        newTheme = ""
        duplicate = nil
    }
}
