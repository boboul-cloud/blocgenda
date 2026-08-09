import Foundation

/// Le moteur de mise en page du journal.
///
/// On dépose des bouts de journée dans le désordre — trois mots à midi, une
/// phrase le soir. Le moteur en fait une page : il regroupe, il coud, il
/// choisit la phrase à mettre en exergue. Trois recettes, une par humeur.
///
/// Il ne touche jamais au texte de l'utilisateur autrement qu'en le cousant :
/// rien n'est réécrit, rien n'est perdu.
enum JournalLayout {

    // MARK: - Les blocs rendus par le moteur

    /// Ce que la page a à dessiner, dans l'ordre.
    enum Block: Identifiable, Hashable, Sendable {
        /// Un titre de moment : « Matin », « Après-midi »…
        case heading(String)
        /// Plusieurs notes cousues en un seul paragraphe.
        case paragraph(id: UUID, text: String, spoken: Bool)
        /// Une note sur sa ligne, l'heure en marge.
        case line(JournalNote)
        /// La phrase du jour, tirée en gros hors du texte.
        case pull(JournalNote)
        /// Un blanc, pour respirer.
        case rule(Int)

        var id: String {
            switch self {
            case .heading(let t): return "h-\(t)"
            case .paragraph(let id, _, _): return "p-\(id.uuidString)"
            case .line(let n): return "l-\(n.id.uuidString)"
            case .pull(let n): return "e-\(n.id.uuidString)"
            case .rule(let i): return "r-\(i)"
            }
        }
    }

    /// Les quatre moments d'une journée. L'ordre est celui des heures.
    enum Moment: Int, CaseIterable, Sendable {
        case nuit, matin, apresMidi, soir

        var title: String {
            switch self {
            case .nuit: return "Nuit"
            case .matin: return "Matin"
            case .apresMidi: return "Après-midi"
            case .soir: return "Soir"
            }
        }

        static func of(_ date: Date, calendar: Calendar = .current) -> Moment {
            switch calendar.component(.hour, from: date) {
            case ..<6: return .nuit
            case ..<12: return .matin
            case ..<18: return .apresMidi
            default: return .soir
            }
        }
    }

    // MARK: - Composition

    static func compose(_ page: JournalPage, calendar: Calendar = .current) -> [Block] {
        let notes = page.ordered
        guard !notes.isEmpty else { return [] }

        switch page.mood {
        case .posee: return composePosee(notes, calendar: calendar)
        case .vive: return composeVive(notes, calendar: calendar)
        case .songeuse: return composeSongeuse(notes)
        }
    }

    /// Posée : la journée racontée. Un titre par moment traversé, et sous
    /// chacun un paragraphe où les notes sont cousues bout à bout.
    private static func composePosee(_ notes: [JournalNote], calendar: Calendar) -> [Block] {
        var blocks: [Block] = []
        for (index, group) in groups(of: notes, calendar: calendar).enumerated() {
            if index > 0 { blocks.append(.rule(index)) }
            blocks.append(.heading(group.moment.title))
            blocks.append(.paragraph(id: group.notes[0].id,
                                     text: sewn(group.notes),
                                     spoken: group.notes.allSatisfy(\.spoken)))
        }
        return blocks
    }

    /// Vive : rien n'est cousu, tout est jeté sur la page. Une ligne par note,
    /// l'heure en marge, et la phrase la plus forte tirée en gros là où elle
    /// est tombée.
    private static func composeVive(_ notes: [JournalNote], calendar: Calendar) -> [Block] {
        let exergue = notes.count >= 2 ? strongest(notes) : nil
        var blocks: [Block] = []
        var lastMoment: Moment?

        for note in notes {
            let moment = Moment.of(note.date, calendar: calendar)
            if moment != lastMoment {
                if lastMoment != nil { blocks.append(.rule(moment.rawValue)) }
                blocks.append(.heading(moment.title))
                lastMoment = moment
            }
            blocks.append(note.id == exergue?.id ? .pull(note) : .line(note))
        }
        return blocks
    }

    /// Songeuse : ni heure ni titre. Une pensée détachée en tête de page, puis
    /// tout le reste au fil de la plume, d'un seul tenant.
    private static func composeSongeuse(_ notes: [JournalNote]) -> [Block] {
        guard notes.count >= 2, let exergue = mostAphoristic(notes) else {
            return [.paragraph(id: notes[0].id, text: sewn(notes),
                               spoken: notes.allSatisfy(\.spoken))]
        }
        let rest = notes.filter { $0.id != exergue.id }
        var blocks: [Block] = [.pull(exergue), .rule(0)]
        if !rest.isEmpty {
            blocks.append(.paragraph(id: rest[0].id, text: sewn(rest),
                                     spoken: rest.allSatisfy(\.spoken)))
        }
        return blocks
    }

    // MARK: - Couture

    /// Coud des notes en un paragraphe : une majuscule au départ de chacune,
    /// un point à l'arrivée si l'auteur n'en a pas mis. C'est tout ce que le
    /// moteur se permet — le texte reste celui qu'on a écrit.
    static func sewn(_ notes: [JournalNote]) -> String {
        notes.map(\.trimmed)
            .filter { !$0.isEmpty }
            .map { sentence -> String in
                let opened = sentence.capitalizedFirst
                guard let last = opened.last, ".!?…:;»".contains(last) else { return opened + "." }
                return opened
            }
            .joined(separator: " ")
    }

    // MARK: - Choix de l'exergue

    /// La phrase qui a le plus de voix : celle qui s'exclame, sinon la plus longue.
    static func strongest(_ notes: [JournalNote]) -> JournalNote? {
        notes.max { a, b in
            let (ea, eb) = (a.trimmed.filter { $0 == "!" }.count, b.trimmed.filter { $0 == "!" }.count)
            if ea != eb { return ea < eb }
            if a.trimmed.count != b.trimmed.count { return a.trimmed.count < b.trimmed.count }
            return a.date < b.date
        }
    }

    /// La phrase qui sonne comme une maxime : assez de mots pour dire quelque
    /// chose, assez peu pour tenir en tête. À défaut, la plus courte.
    static func mostAphoristic(_ notes: [JournalNote]) -> JournalNote? {
        let counted = notes.map { (note: $0, words: $0.trimmed.split(whereSeparator: \.isWhitespace).count) }
        let eligible = counted.filter { $0.words >= 3 && $0.words <= 18 }
        let pool = eligible.isEmpty ? counted : eligible
        return pool.min { a, b in
            a.words != b.words ? a.words < b.words : a.note.date < b.note.date
        }?.note
    }

    // MARK: - Regroupement

    struct Group {
        var moment: Moment
        var notes: [JournalNote]
    }

    /// Les notes rangées par moment de la journée, dans l'ordre des heures.
    /// Un moment sans note ne crée pas de groupe : la page ne montre que les
    /// heures qu'on a réellement traversées.
    static func groups(of notes: [JournalNote], calendar: Calendar = .current) -> [Group] {
        var result: [Group] = []
        for note in notes.sorted(by: { $0.date < $1.date }) {
            let moment = Moment.of(note.date, calendar: calendar)
            if var last = result.last, last.moment == moment {
                last.notes.append(note)
                result[result.count - 1] = last
            } else {
                result.append(Group(moment: moment, notes: [note]))
            }
        }
        return result
    }
}
