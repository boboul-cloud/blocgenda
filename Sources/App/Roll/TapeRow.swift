import SwiftUI

/// Une ligne imprimée. L'heure occupe la gouttière de gauche, comme sur un
/// ticket de caisse ; le montant, quand il y en a un, est aligné à droite.
struct TapeRow: View {
    let entry: TapeEntry
    let currency: String
    @Environment(Store.self) private var store
    @State private var editing = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(Fmt.hmShort.string(from: entry.date))
                .font(Type.tape(9.5))
                .foregroundStyle(Ink.textFaint)
                .frame(width: 34, alignment: .leading)
                .padding(.top, 2)

            content

            Spacer(minLength: 0)

            if let value = entry.value, entry.kind != .subtotal {
                Text(NumberStyleFR.money(value, symbol: entry.kind == .calc ? "" : currency))
                    .font(Type.tape(13, weight: .semibold))
                    .foregroundStyle(value < 0 ? Ink.rouge : Ink.text)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 5)
        .background(entry.pinned ? Ink.amber.opacity(0.08) : .clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if entry.kind == .task {
                withAnimation(.snappy) { store.toggleDone(entryID: entry.id) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                editing = true
            }
        }
        .contextMenu {
            Button {
                var copy = entry
                copy.pinned.toggle()
                store.update(copy)
            } label: {
                Label(entry.pinned ? "Ne plus épingler" : "Épingler",
                      systemImage: entry.pinned ? "pin.slash" : "pin")
            }
            if entry.kind != .subtotal {
                Button { editing = true } label: { Label("Modifier", systemImage: "pencil") }
            }
            Button {
                UIPasteboard.general.string = plainText
            } label: { Label("Copier", systemImage: "doc.on.doc") }
            Button(role: .destructive) {
                withAnimation { store.delete(entryID: entry.id) }
            } label: { Label("Supprimer", systemImage: "trash") }
        }
        .sheet(isPresented: $editing) {
            EntryEditor(entry: entry).environment(store)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.kind {
        case .calc:
            HStack(spacing: 6) {
                Text(entry.expression ?? "")
                    .font(Type.tape(13))
                    .foregroundStyle(Ink.text)
                Text("=")
                    .font(Type.tape(12))
                    .foregroundStyle(Ink.textFaint)
            }

        case .task:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: entry.done ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(entry.done ? Ink.moss : Ink.textSoft)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.text)
                        .font(Type.tape(13))
                        .strikethrough(entry.done, color: Ink.textFaint)
                        .foregroundStyle(entry.done ? Ink.textFaint : Ink.text)
                    tagRow
                }
            }

        case .subtotal:
            VStack(alignment: .leading, spacing: 3) {
                Rectangle().fill(Ink.text.opacity(0.7)).frame(height: 1)
                HStack {
                    Text(entry.text.uppercased())
                        .font(Type.tape(11, weight: .bold))
                        .tracking(1.2)
                    Spacer()
                    Text(NumberStyleFR.money(entry.value ?? 0, symbol: currency))
                        .font(Type.tape(14, weight: .bold))
                }
                .foregroundStyle(Ink.text)
                Rectangle().fill(Ink.text.opacity(0.7)).frame(height: 1)
            }
            .padding(.trailing, 2)

        case .event:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Ink.sea)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.text)
                        .font(Type.tape(13))
                        .foregroundStyle(Ink.text)
                    if let event = store.events.first(where: { $0.id == entry.eventID }) {
                        Text(eventSubtitle(event))
                            .font(Type.tape(10))
                            .foregroundStyle(Ink.sea)
                    }
                    tagRow
                }
            }

        case .note, .memo:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(Type.tape(13))
                    .foregroundStyle(Ink.text)
                    .fixedSize(horizontal: false, vertical: true)
                tagRow
            }
        }
    }

    @ViewBuilder
    private var tagRow: some View {
        if !entry.tags.isEmpty {
            HStack(spacing: 5) {
                ForEach(entry.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(Type.tape(9.5, weight: .medium))
                        .foregroundStyle(Ink.amberDeep)
                }
            }
        }
    }

    private func eventSubtitle(_ event: AgendaEvent) -> String {
        var pieces: [String] = [Fmt.dayTitle(event.start)]
        if !event.isAllDay { pieces.append(Fmt.hm.string(from: event.start)) }
        if !event.place.isEmpty { pieces.append(event.place) }
        return pieces.joined(separator: " · ")
    }

    private var plainText: String {
        switch entry.kind {
        case .calc: return "\(entry.expression ?? "") = \(NumberStyleFR.format(entry.value ?? 0))"
        case .subtotal: return "\(entry.text) \(NumberStyleFR.money(entry.value ?? 0, symbol: currency))"
        default:
            guard let value = entry.value else { return entry.text }
            return "\(entry.text) \(NumberStyleFR.money(value, symbol: currency))"
        }
    }
}

/// Retouche d'une ligne : texte, montant, nature.
struct EntryEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TapeEntry
    @State private var amountText: String

    init(entry: TapeEntry) {
        _draft = State(initialValue: entry)
        _amountText = State(initialValue: entry.value.map { NumberStyleFR.format($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Texte") {
                    TextField("Libellé", text: $draft.text, axis: .vertical)
                        .lineLimit(1...6)
                }
                Section("Montant") {
                    TextField("0,00", text: $amountText)
                        .keyboardType(.numbersAndPunctuation)
                }
                Section("Nature") {
                    Picker("Nature", selection: $draft.kind) {
                        Text("Note").tag(TapeKind.note)
                        Text("Action").tag(TapeKind.task)
                        Text("Calcul").tag(TapeKind.calc)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    DatePicker("Horodatage", selection: $draft.date)
                    Toggle("Épingler sur le rouleau", isOn: $draft.pinned)
                }
            }
            .navigationTitle("Modifier la ligne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        draft.value = Calculator.evaluateLoose(amountText)
                        store.update(draft)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
