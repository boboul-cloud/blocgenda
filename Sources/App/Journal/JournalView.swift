import SwiftUI

/// « Journal du jour » : la page où l'on dépose les moments et les pensées de
/// la journée. On écrit au fil de l'eau, dans le désordre ; le moteur remet en
/// page selon l'humeur, sur une feuille de classeur.
struct JournalView: View {
    @Environment(Store.self) private var store
    @State private var day = Calendar.current.startOfDay(for: Date())
    @State private var draft = ""
    @State private var showNotes = false
    @State private var showRename = false
    @State private var titleDraft = ""
    /// Le tampon d'une page pas encore ouverte : la feuille montre déjà le
    /// temps du jour avant qu'on y ait écrit la première ligne. Retenu ici pour
    /// n'être calculé qu'au changement de jour.
    @State private var previewStamp: DayStamp?
    @FocusState private var inputFocused: Bool

    private var page: JournalPage {
        store.journalPage(on: day) ?? JournalPage(day: day, stamp: previewStamp)
    }

    private var blocks: [JournalLayout.Block] {
        JournalLayout.compose(page)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            MoodPicker(mood: page.mood) { store.setJournalMood($0, on: day) }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            sheet

            JournalBar(text: $draft, focused: $inputFocused, accent: page.mood.accent) { spoken in
                deposit(spoken: spoken)
            }
            Color.clear.frame(height: Type.tabBarInset) // place pour la barre d'onglets
        }
        .background(Ink.chassis)
        .animation(.snappy(duration: 0.25), value: page.mood)
        .task { stampPage() }
        .onChange(of: day) { _, _ in stampPage() }
        .onChange(of: store.dayData.computedFor) { _, _ in stampPage() }
        .onChange(of: store.dayData.weather) { _, _ in stampPage() }
        .sheet(isPresented: $showNotes) {
            JournalNotesSheet(day: day).environment(store)
        }
        .alert("Titre de la journée", isPresented: $showRename) {
            TextField("Une journée à …", text: $titleDraft)
            Button("Enregistrer") {
                store.openJournalPage(on: day)
                store.setJournalTitle(titleDraft, on: day)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Un titre s'inscrit en haut de la page, au-dessus de la date.")
        }
    }

    // MARK: - En-tête

    private var header: some View {
        ScreenHeader(title: "Journal du jour", subtitle: subtitle) {
            HStack(spacing: 6) {
                Button { turn(-1) } label: { pager("chevron.left") }
                    .accessibilityLabel("Page précédente")
                Button { turn(1) } label: { pager("chevron.right") }
                    .disabled(isToday)
                    .opacity(isToday ? 0.35 : 1)
                    .accessibilityLabel("Page suivante")
                Button { showNotes = true } label: { pager("list.bullet") }
                    .accessibilityLabel("Relire les moments")
                    .accessibilityIdentifier("journal.moments")
            }
            .buttonStyle(.plain)
        }
    }

    private func pager(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(Type.icon(14, weight: .semibold))
            .foregroundStyle(Ink.textFaint)
            .frame(width: Type.control(34), height: Type.control(34))
            .background(Circle().fill(Ink.chassisSoft))
    }

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private var subtitle: String {
        let title = Fmt.dayTitle(day)
        let count = page.ordered.count
        guard count > 0 else { return title }
        let words = page.wordCount
        return "\(title) · \(count) moment\(count > 1 ? "s" : "") · \(words) mot\(words > 1 ? "s" : "")"
    }

    // MARK: - La feuille

    private var sheet: some View {
        ScrollView {
            RuledSheet {
                JournalHeading(page: page) {
                    titleDraft = page.title
                    showRename = true
                }

                if blocks.isEmpty {
                    emptyPage
                } else {
                    ForEach(blocks) { block in
                        JournalBlockView(block: block, mood: page.mood)
                    }
                }

                if let stamp = page.stamp {
                    Color.clear.frame(height: Ruling.rule)
                    JournalStampView(stamp: stamp)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyPage: some View {
        VStack(alignment: .leading, spacing: Ruling.spacing) {
            Text("La page est blanche.")
                .font(Ruling.serif(Ruling.base, italic: true))
                .foregroundStyle(Ink.textSoft)
            Text("Écrivez ou dictez un moment, une pensée. Le journal les rassemblera à sa façon — celle de l'humeur choisie.")
                .font(Ruling.serif(Ruling.base))
                .foregroundStyle(Ink.textFaint)
                .lineSpacing(Ruling.spacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .snappedToRules()
    }

    // MARK: - Gestes

    private func deposit(spoken: Bool) {
        guard store.addJournalNote(draft, on: day, spoken: spoken) != nil else { return }
        draft = ""
        stampPage()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Tient le tampon à jour : celui de la page ouverte, ou celui que la
    /// feuille blanche affiche en attendant.
    private func stampPage() {
        if store.journalPage(on: day) != nil {
            store.refreshJournalStamp(on: day)
        } else {
            previewStamp = store.stamp(for: day)
        }
    }

    /// Tourner la page. On ne va pas au-delà d'aujourd'hui : le journal ne
    /// s'écrit pas d'avance.
    private func turn(_ direction: Int) {
        let cal = Calendar.current
        guard let target = cal.date(byAdding: .day, value: direction, to: day) else { return }
        guard target <= cal.startOfDay(for: Date()) else { return }
        withAnimation(.snappy(duration: 0.22)) { day = target }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - L'humeur

/// Les trois humeurs, en clair. Changer d'humeur ne touche pas à ce qu'on a
/// écrit : seule la mise en page change, et elle peut changer autant de fois
/// qu'on veut.
struct MoodPicker: View {
    let mood: JournalMood
    var onPick: (JournalMood) -> Void

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                ForEach(JournalMood.allCases) { candidate in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onPick(candidate)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: candidate.icon)
                                .font(Type.icon(11, weight: .bold))
                            Text(candidate.title)
                                .font(Type.ui(12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(candidate == mood ? Ink.paper : candidate.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(candidate == mood
                                      ? candidate.accent
                                      : candidate.accent.opacity(0.12))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("journal.humeur.\(candidate.rawValue)")
                    .accessibilityLabel("Humeur \(candidate.title)")
                    .accessibilityAddTraits(candidate == mood ? [.isSelected] : [])
                }
            }

            Text(mood.hint)
                .font(Type.ui(10.5))
                .foregroundStyle(Ink.textFaint)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
