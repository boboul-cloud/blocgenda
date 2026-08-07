import SwiftUI

/// Le rouleau : une bande de papier qui sort de la machine et sur laquelle
/// tout s'imprime dans l'ordre — calculs, notes, actions, rendez-vous.
struct RollView: View {
    @Environment(Store.self) private var store
    @State private var draft = ""
    @State private var showKeypad = false
    @State private var search = ""
    @State private var showSearch = false
    @State private var tearImage: UIImage?
    @State private var showTearConfirm = false
    @State private var lastPrintedID: UUID?
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            paperRoll
            SmartBar(text: $draft,
                     showKeypad: $showKeypad,
                     focused: $inputFocused,
                     onSubmit: print,
                     tagSuggestions: store.frequentTags())
            if showKeypad {
                Keypad(text: $draft,
                       onEqual: print,
                       onTotal: { store.printSubtotal() })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Color.clear.frame(height: 62) // place pour la barre d'onglets
        }
        .background(Ink.chassis)
        .animation(.snappy(duration: 0.25), value: showKeypad)
        .sheet(item: Binding(get: { tearImage.map(ShareableImage.init) },
                             set: { _ in tearImage = nil })) { item in
            ShareSheet(items: [item.image])
        }
        .confirmationDialog("Déchirer la bande ?", isPresented: $showTearConfirm, titleVisibility: .visible) {
            Button("Déchirer et archiver") { tear() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les lignes terminées sont archivées. Les actions non faites et les lignes épinglées restent sur le rouleau.")
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Rouleau",
                         subtitle: Fmt.dayFull.string(from: Date()).capitalizedFirst) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation { showSearch.toggle() }
                        if !showSearch { search = "" }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Ink.textFaint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Ink.chassisSoft))
                    }
                    Button { showTearConfirm = true } label: {
                        Image(systemName: "scissors")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Ink.textFaint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Ink.chassisSoft))
                    }
                }
                .buttonStyle(.plain)
            }

            TotalDisplay(total: store.runningTotal,
                         symbol: store.settings.currencySymbol,
                         lineCount: store.rollEntries.count)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            if showSearch {
                SearchField(text: $search, prompt: "Chercher sur le rouleau, #étiquette…")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - La bande

    private var visibleDays: [TapeDay] {
        let days = store.rollDays
        guard !search.isEmpty else { return days }
        let needle = search.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return days.compactMap { day in
            let matches = day.entries.filter { entry in
                let haystack = "\(entry.text) \(entry.expression ?? "") \(entry.tags.joined(separator: " "))"
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                return haystack.contains(needle)
            }
            return matches.isEmpty ? nil : TapeDay(day: day.day, entries: matches)
        }
    }

    private var paperRoll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    RollHead()
                    if visibleDays.isEmpty {
                        EmptyRoll(searching: !search.isEmpty)
                    }
                    ForEach(visibleDays) { day in
                        DayStrip(day: day,
                                 currency: store.settings.currencySymbol,
                                 onTagTap: filter(by:))
                            .id(day.day)
                    }
                    Color.clear.frame(height: 26).id("bottom")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // Le papier tapisse toute la fenêtre, même quand la bande est courte.
            .background(
                ZStack {
                    PaperBackground()
                    HStack {
                        SprocketHoles().frame(width: 14)
                        Spacer()
                        SprocketHoles().frame(width: 14)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .mask(
                // Le papier disparaît sous le capot de la machine, en haut.
                LinearGradient(stops: [.init(color: .black.opacity(0.15), location: 0),
                                       .init(color: .black, location: 0.055),
                                       .init(color: .black, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            )
            .onChange(of: store.rollEntries.count) { _, _ in
                withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }

    // MARK: - Actions

    private func print() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if let entry = store.submit(text) {
            lastPrintedID = entry.id
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        draft = ""
    }

    /// Toucher une étiquette ouvre la loupe et n'affiche plus qu'elle.
    private func filter(by tag: String) {
        withAnimation(.snappy) {
            search = tag
            showSearch = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func tear() {
        let entries = store.rollEntries
        guard !entries.isEmpty else { return }
        let receipt = TearReceipt(entries: entries,
                                  total: store.runningTotal,
                                  currency: store.settings.currencySymbol,
                                  place: store.settings.place.name)
        let renderer = ImageRenderer(content: receipt)
        renderer.scale = 3
        tearImage = renderer.uiImage
        _ = store.tearOff()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Afficheur du total

/// Le petit écran de la machine : total courant et nombre de lignes.
struct TotalDisplay: View {
    var total: Double
    var symbol: String
    var lineCount: Int

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("TOTAL EN COURS")
                .font(Type.micro)
                .tracking(1.6)
                .foregroundStyle(Ink.textFaint)
            Spacer()
            Text(NumberStyleFR.money(total, symbol: symbol))
                .font(Type.tape(21, weight: .semibold))
                .foregroundStyle(total < 0 ? Ink.rouge : Ink.amber)
                .contentTransition(.numericText())
                .animation(.snappy, value: total)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1)
                )
        )
        .overlay(alignment: .bottomTrailing) {
            Text("\(lineCount) ligne\(lineCount > 1 ? "s" : "")")
                .font(Type.ui(9))
                .foregroundStyle(Ink.textFaint.opacity(0.7))
                .padding(.trailing, 14)
                .offset(y: 9)
        }
    }
}

// MARK: - Éléments de la bande

/// Le haut de la bande, là où elle sort du rouleau.
struct RollHead: View {
    var body: some View {
        VStack(spacing: 0) {
            TornEdge(seed: 3, atBottom: false)
                .fill(Ink.paper)
                .frame(height: 10)
            HStack {
                Text("BLOCGENDA")
                    .font(Type.tape(9, weight: .bold))
                    .tracking(3)
                Spacer()
                Text(Date(), format: .dateTime.year())
                    .font(Type.tape(9))
            }
            .foregroundStyle(Ink.textFaint)
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }
}

/// Une journée de bande : son en-tête, ses lignes, son total.
struct DayStrip: View {
    let day: TapeDay
    let currency: String
    var onTagTap: ((String) -> Void)? = nil
    @Environment(Store.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                DottedRule().frame(width: 26)
                Text(Fmt.dayTitle(day.day).uppercased())
                    .font(Type.tape(9.5, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Ink.textSoft)
                DottedRule()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)

            ForEach(day.entries) { entry in
                TapeRow(entry: entry, currency: currency, onTagTap: onTagTap)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity))
            }

            if day.taskCount > 0 || abs(day.total) > 0.001 {
                DayFooter(day: day, currency: currency)
            }
        }
        .animation(.snappy(duration: 0.3), value: day.entries.count)
    }
}

struct DayFooter: View {
    let day: TapeDay
    let currency: String

    var body: some View {
        HStack(spacing: 10) {
            if day.taskCount > 0 {
                Label("\(day.doneCount)/\(day.taskCount)", systemImage: "checkmark.square")
                    .font(Type.tape(10))
                    .foregroundStyle(day.doneCount == day.taskCount ? Ink.moss : Ink.textSoft)
            }
            Spacer()
            if abs(day.total) > 0.001 {
                Text("sous-total  \(NumberStyleFR.money(day.total, symbol: currency))")
                    .font(Type.tape(10, weight: .semibold))
                    .foregroundStyle(Ink.textSoft)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
        .padding(.top, 2)
    }
}

struct EmptyRoll: View {
    var searching: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: searching ? "text.magnifyingglass" : "pencil.line")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text(searching ? "Rien de trouvé sur la bande." : "La bande est vierge.")
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            if !searching {
                Text("Écrivez « 12,50 × 3 », « - passer à la poste »\nou « demain 14h dentiste ».")
                    .font(Type.ui(12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ink.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Partage

struct ShareableImage: Identifiable {
    let image: UIImage
    var id: String { String(describing: image.hashValue) }
    init(_ image: UIImage) { self.image = image }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct SearchField: View {
    @Binding var text: String
    var prompt: String = "Chercher…"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Ink.textFaint)
            TextField(prompt, text: $text)
                .font(Type.ui(14))
                .foregroundStyle(Ink.paper)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Ink.chassisLine, lineWidth: 1))
        )
    }
}
