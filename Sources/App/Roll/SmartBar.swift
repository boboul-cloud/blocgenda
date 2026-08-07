import SwiftUI

/// La barre unique. Une seule zone de saisie pour tout : elle annonce en
/// direct ce qu'elle a compris avant même qu'on valide.
struct SmartBar: View {
    @Binding var text: String
    @Binding var showKeypad: Bool
    @FocusState.Binding var focused: Bool
    var onSubmit: () -> Void
    /// Texte d'invite : il rappelle où la ligne va atterrir.
    var placeholder: String = "Calcul, note, action, rendez-vous…"
    /// Le clavier de calculatrice n'a de sens que sur le rouleau.
    var showsKeypadToggle: Bool = true
    /// Jour de référence pour l'aperçu — celui que l'agenda a sélectionné.
    var reference: Date = Date()
    /// Étiquettes déjà employées, proposées dès qu'on écrit.
    var tagSuggestions: [String] = []

    private var preview: SmartInput.Parsed? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else { return nil }
        return SmartInput.parse(trimmed, reference: reference)
    }

    var body: some View {
        VStack(spacing: 0) {
            if focused {
                TagSuggestions(tags: tagSuggestions, onPick: insertTag)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if let preview {
                IntentPreview(parsed: preview)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 10) {
                if showsKeypadToggle {
                    Button {
                        withAnimation { showKeypad.toggle() }
                        if showKeypad { focused = false }
                    } label: {
                        Image(systemName: showKeypad ? "keyboard.chevron.compact.down" : "number.square")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(showKeypad ? Ink.amber : Ink.textFaint)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("barre.clavier")
                    .accessibilityLabel("Clavier de calculatrice")
                } else {
                    Spacer(minLength: 6)
                }

                TextField("", text: $text, axis: .vertical)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .font(Type.ui(14))
                            .foregroundStyle(Ink.textFaint)
                            .lineLimit(1)
                    }
                    .font(Type.tape(14))
                    .foregroundStyle(Ink.paper)
                    .lineLimit(1...4)
                    .focused($focused)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit(onSubmit)
                    .accessibilityIdentifier("barre.saisie")

                Button(action: onSubmit) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(text.isEmpty ? Ink.textFaint : Color.black.opacity(0.85))
                        .frame(width: 38, height: 38)
                        .background(
                            Circle().fill(text.isEmpty ? Ink.chassisLine : Ink.amber)
                        )
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
                .accessibilityIdentifier("barre.valider")
                .accessibilityLabel("Imprimer sur le rouleau")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Ink.chassisSoft)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1))
            )
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, showKeypad ? 8 : 10)
        }
        .background(Ink.chassis)
        .animation(.snappy(duration: 0.2), value: text.isEmpty)
        .animation(.snappy(duration: 0.2), value: focused)
    }

    /// Ajoute une étiquette en fin de ligne. Un nom vide insère juste le `#`,
    /// pour qui veut en inventer une nouvelle.
    private func insertTag(_ tag: String) {
        if !text.isEmpty && !text.hasSuffix(" ") { text += " " }
        text += tag.isEmpty ? "#" : "#\(tag) "
        focused = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

/// La rangée d'étiquettes sous la barre. Elle sert autant à réutiliser les
/// étiquettes existantes qu'à faire découvrir qu'elles existent : sans elle,
/// il fallait deviner qu'on pouvait taper « #bateau ».
struct TagSuggestions: View {
    let tags: [String]
    var onPick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button { onPick("") } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 10, weight: .bold))
                        if tags.isEmpty {
                            Text("étiqueter").font(Type.ui(11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.black.opacity(0.8))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Ink.amber))
                }
                .accessibilityIdentifier("barre.etiquette")
                .accessibilityLabel("Ajouter une étiquette")

                if tags.isEmpty {
                    Text("classez vos lignes : #bateau, #maison…")
                        .font(Type.ui(11))
                        .foregroundStyle(Ink.textFaint)
                } else {
                    ForEach(tags, id: \.self) { tag in
                        Button { onPick(tag) } label: {
                            Text("#\(tag)")
                                .font(Type.ui(11.5, weight: .medium))
                                .foregroundStyle(Ink.amberDeep)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Ink.amber.opacity(0.15)))
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
        .frame(height: 28)
    }
}

/// L'étiquette qui dit ce que la barre a compris : « calcul = 37,50 »,
/// « rendez-vous demain 14h30 »…
struct IntentPreview: View {
    let parsed: SmartInput.Parsed

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(label)
                .font(Type.ui(11, weight: .semibold))
            Spacer(minLength: 0)
            if !parsed.tags.isEmpty {
                Text(parsed.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(Type.ui(10, weight: .medium))
                    .foregroundStyle(Ink.amberDeep)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
    }

    private var icon: String {
        switch parsed.intent {
        case .calculation: return "equal.square.fill"
        case .task: return "checkmark.square.fill"
        case .event: return "calendar.badge.plus"
        case .note: return "text.alignleft"
        }
    }

    private var color: Color {
        switch parsed.intent {
        case .calculation: return Ink.amber
        case .task: return Ink.moss
        case .event: return Ink.sea
        case .note: return Ink.textFaint
        }
    }

    private var label: String {
        switch parsed.intent {
        case .calculation(_, let value):
            return "Calcul  =  \(NumberStyleFR.format(value))"
        case .task(_, let due):
            guard let due else { return "Action à cocher" }
            return "Action · \(Fmt.dayTitle(due)) \(Fmt.hm.string(from: due))"
        case .event(let title, let start, _, let allDay):
            let time = allDay ? "" : " \(Fmt.hm.string(from: start))"
            return "Rendez-vous · \(Fmt.dayTitle(start))\(time) · \(title)"
        case .note(_, let amount):
            guard let amount else { return "Note" }
            return "Note chiffrée · \(NumberStyleFR.money(amount))"
        }
    }
}

extension View {
    /// Un texte d'invite qui garde la police du champ (contrairement à `prompt`).
    func placeholder<P: View>(when show: Bool, @ViewBuilder placeholder: () -> P) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(show ? 1 : 0).allowsHitTesting(false)
            self
        }
    }
}
