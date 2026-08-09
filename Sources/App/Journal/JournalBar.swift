import SwiftUI

/// La barre du journal. Elle ne cherche rien à comprendre — pas de calcul, pas
/// de rendez-vous : ce qu'on écrit ici reste tel quel. On peut la remplir au
/// clavier ou à la voix, et rien ne se dépose sans qu'on le valide.
struct JournalBar: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool
    var accent: Color
    /// Reçoit le texte et dit s'il est venu du micro.
    var onSubmit: (Bool) -> Void

    @State private var dictation = Dictation()
    /// Vrai dès que le micro a écrit dans la barre, jusqu'à la validation.
    @State private var dictated = false

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let message = dictation.message {
                DictationNotice(message: message) { dictation.openSettings() }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }

            if dictation.isRecording {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(Type.icon(10, weight: .bold))
                        .symbolEffect(.variableColor.iterative, isActive: true)
                    Text("Je vous écoute…")
                        .font(Type.ui(11, weight: .semibold))
                }
                .foregroundStyle(Ink.rouge)
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("", text: $text, axis: .vertical)
                    .placeholder(when: text.isEmpty) {
                        Text("Un moment, une pensée…")
                            .font(Ruling.serif(13.5))
                            .foregroundStyle(Ink.textFaint)
                            .lineLimit(1)
                    }
                    .font(Ruling.serif(13.5))
                    .foregroundStyle(Ink.text)
                    .lineLimit(1...6)
                    .focused($focused)
                    .accessibilityIdentifier("journal.saisie")

                if dictation.isAvailable {
                    Button(action: dictate) {
                        Image(systemName: dictation.isRecording ? "stop.fill" : "mic.fill")
                            .font(Type.icon(15, weight: .bold))
                            .symbolEffect(.pulse, isActive: dictation.isRecording)
                            .foregroundStyle(dictation.isRecording ? Ink.paper : Ink.textFaint)
                            .frame(width: Type.control(34), height: Type.control(34))
                            .background(Circle().fill(dictation.isRecording ? Ink.rouge : Ink.chassis))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("journal.dictee")
                    .accessibilityLabel(dictation.isRecording ? "Arrêter la dictée" : "Dicter")
                }

                Button(action: deposit) {
                    Image(systemName: "square.and.pencil")
                        .font(Type.icon(15, weight: .bold))
                        .foregroundStyle(isEmpty ? Ink.textFaint : Ink.paper)
                        .frame(width: Type.control(38), height: Type.control(38))
                        .background(Circle().fill(isEmpty ? Ink.chassisLine : accent))
                }
                .buttonStyle(.plain)
                .disabled(isEmpty)
                .accessibilityIdentifier("journal.deposer")
                .accessibilityLabel("Déposer sur la page")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Ink.chassisSoft)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1))
            )
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .background(Ink.chassis)
        .animation(.snappy(duration: 0.2), value: isEmpty)
        .animation(.snappy(duration: 0.2), value: dictation.isRecording)
        .onChange(of: focused) { _, isFocused in
            if isFocused { dictation.stop() }
        }
        .onDisappear { dictation.stop() }
    }

    /// Le micro écrit à la suite de ce qui est déjà là : on peut commencer au
    /// doigt et finir à la voix.
    private func dictate() {
        guard !dictation.isRecording else { dictation.stop(); return }
        focused = false
        let base = text.isEmpty || text.hasSuffix(" ") ? text : text + " "
        dictated = true
        dictation.start { heard in text = base + heard }
    }

    private func deposit() {
        dictation.stop()
        guard !isEmpty else { return }
        onSubmit(dictated)
        dictated = false
    }
}

// MARK: - Relecture des moments

/// La liste des moments tels qu'ils ont été déposés, avant que le moteur ne
/// les mette en page. C'est là qu'on corrige un mot mal entendu, ou qu'on
/// retire une ligne.
struct JournalNotesSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let day: Date

    private var notes: [JournalNote] {
        store.journalPage(on: day)?.ordered ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                if notes.isEmpty {
                    Text("Rien n'a encore été déposé sur cette page.")
                        .font(Type.ui(13))
                        .foregroundStyle(Ink.textSoft)
                }
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(Fmt.hm.string(from: note.date))
                                .font(Type.tape(10.5, weight: .medium))
                                .foregroundStyle(Ink.amberDeep)
                            if note.spoken {
                                Image(systemName: "mic.fill")
                                    .font(Type.icon(9))
                                    .foregroundStyle(Ink.textFaint)
                            }
                        }
                        TextField("Moment", text: binding(for: note), axis: .vertical)
                            .font(Ruling.serif(14))
                            .foregroundStyle(Ink.text)
                    }
                    .padding(.vertical, 2)
                    .swipeActions {
                        Button("Effacer", role: .destructive) {
                            store.deleteJournalNote(id: note.id, on: day)
                        }
                    }
                }
            }
            .navigationTitle("Les moments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .paperSheet()
    }

    private func binding(for note: JournalNote) -> Binding<String> {
        Binding {
            store.journalPage(on: day)?.notes.first { $0.id == note.id }?.text ?? note.text
        } set: { newValue in
            var edited = note
            edited.text = newValue
            store.updateJournalNote(edited, on: day)
        }
    }
}
