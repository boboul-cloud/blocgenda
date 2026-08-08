import SwiftUI

/// Les tiroirs de l'annuaire, gérés pour eux-mêmes. On y crée un groupe sans
/// avoir de fiche sous la main — il attend d'être rempli — et on retire ceux
/// qu'on a nommés de travers. Les sept groupes d'office ne se suppriment pas :
/// ce sont les cases du bloc-notes, pas des créations de l'utilisateur.
struct ContactGroupsView: View {
    @Environment(Store.self) private var store
    @State private var newGroup = ""
    @State private var groupToDelete: String?
    /// Nom refusé parce qu'il existe déjà, le temps de le dire.
    @State private var duplicate: String?

    private var trimmed: String {
        newGroup.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Nom du nouveau groupe", text: $newGroup)
                        .submitLabel(.done)
                        .onSubmit(create)
                    Button("Ajouter", action: create)
                        .font(Type.ui(14, weight: .semibold))
                        .buttonStyle(.borderless)
                        .disabled(trimmed.isEmpty)
                }
            } header: {
                Text("Nouveau groupe")
            } footer: {
                if let duplicate {
                    Text("« \(duplicate) » existe déjà.")
                        .foregroundStyle(Ink.rouge)
                } else {
                    Text("Voisins, Bateau, École, Copropriété… Le groupe est aussitôt proposé au classement des fiches et au filtre de l’annuaire, même s’il est encore vide.")
                }
            }

            Section {
                ForEach(store.contactGroups, id: \.self) { name in
                    HStack {
                        Label(name, systemImage: store.isCustomContactGroup(name)
                              ? "folder" : "folder.fill")
                            .foregroundStyle(Ink.text)
                        Spacer()
                        Text("\(count(of: name))")
                            .font(Type.tape(13))
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        if store.isCustomContactGroup(name) {
                            Button(role: .destructive) {
                                groupToDelete = name
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Groupes")
            } footer: {
                Text("Glissez vers la gauche pour retirer un groupe que vous avez créé. Les sept groupes d’origine restent en place.")
            }
        }
        .navigationTitle("Groupes de l’annuaire")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Supprimer le groupe « \(groupToDelete ?? "") » ?",
                            isPresented: Binding(get: { groupToDelete != nil },
                                                 set: { if !$0 { groupToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Supprimer le groupe", role: .destructive) {
                if let name = groupToDelete { store.removeContactGroup(name) }
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

    private func count(of group: String) -> Int {
        store.contacts.count { $0.group == group }
    }

    private func create() {
        let wanted = trimmed
        guard !wanted.isEmpty else { return }
        let known = store.contactGroups.contains { existing in
            let fold = { (s: String) in
                s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            }
            return fold(existing) == fold(wanted)
        }
        guard !known else {
            duplicate = wanted
            return
        }
        store.addContactGroup(wanted)
        newGroup = ""
        duplicate = nil
    }
}
