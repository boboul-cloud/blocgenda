import Foundation

/// La barre unique du rouleau : une seule ligne de saisie, l'app devine ce que
/// c'est. C'est le principe du bloc-notes — on écrit, on ne classe pas.
///
///     "12,50 × 3"                  → un calcul imprimé sur la bande
///     "- rappeler le garage"       → une action à cocher
///     "demain 14h30 dentiste"      → un rendez-vous dans l'agenda
///     "courses 42,50 #maison"      → une note chiffrée qui entre dans le total
///     "réunion lundi 9h pendant 2h"→ un rendez-vous de 2 heures
enum SmartInput {

    enum Intent {
        case calculation(expression: String, value: Double)
        case task(text: String, due: Date?)
        case event(title: String, start: Date, duration: TimeInterval, allDay: Bool)
        case note(text: String, amount: Double?)
    }

    struct Parsed {
        var intent: Intent
        var tags: [String]
        var mentions: [String]
    }

    static func parse(_ raw: String, reference: Date = Date()) -> Parsed? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tags = extractTokens(prefix: "#", from: trimmed)
        let mentions = extractTokens(prefix: "@", from: trimmed)
        var body = strip(prefixes: ["#", "@"], from: trimmed)

        // 1. Action explicite : « - texte », « [] texte », « todo texte »
        if let taskBody = taskBody(of: body) {
            let dated = DateParserFR.extract(from: taskBody, reference: reference)
            return Parsed(intent: .task(text: dated.remainder.isEmpty ? taskBody : dated.remainder,
                                        due: dated.date),
                          tags: tags, mentions: mentions)
        }

        // 2. Calcul pur (« 12+3 », « 20% de 80 », terminé ou non par « = »)
        if body.hasSuffix("=") { body = String(body.dropLast()).trimmingCharacters(in: .whitespaces) }
        if let result = Calculator.evaluate(body) {
            return Parsed(intent: .calculation(expression: result.pretty, value: result.value),
                          tags: tags, mentions: mentions)
        }

        // 3. Rendez-vous : une date ou une heure explicite dans le texte
        let dated = DateParserFR.extract(from: body, reference: reference)
        if let date = dated.date, dated.hasExplicitMarker {
            let title = dated.remainder.isEmpty ? "Rendez-vous" : dated.remainder
            return Parsed(intent: .event(title: title.capitalizedFirst,
                                         start: date,
                                         duration: dated.duration ?? 3600,
                                         allDay: !dated.hasTime),
                          tags: tags, mentions: mentions)
        }

        // 4. Note, éventuellement chiffrée (« essence 62,30 »)
        let amount = trailingAmount(in: body)
        return Parsed(intent: .note(text: amount.text.isEmpty ? body : amount.text,
                                    amount: amount.value),
                      tags: tags, mentions: mentions)
    }

    // MARK: - Détails

    private static func taskBody(of text: String) -> String? {
        let lower = text.lowercased()
        for marker in ["- ", "– ", "* ", "[] ", "[ ] ", "todo ", "tâche ", "tache ", "à faire ", "penser à "] {
            if lower.hasPrefix(marker) {
                return String(text.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    static func extractTokens(prefix: String, from text: String) -> [String] {
        let pattern = "\\\(prefix)([\\p{L}0-9_\\-]{1,30})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap {
            $0.numberOfRanges > 1 ? ns.substring(with: $0.range(at: 1)) : nil
        }
    }

    private static func strip(prefixes: [String], from text: String) -> String {
        var s = text
        for p in prefixes {
            s = s.replacingOccurrences(of: "\\\(p)[\\p{L}0-9_\\-]{1,30}", with: "", options: .regularExpression)
        }
        return s.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// Repère un montant en fin de ligne : « restaurant 42,50 ».
    static func trailingAmount(in text: String) -> (text: String, value: Double?) {
        let pattern = #"^(.*?)[\s:]*(-?\d{1,3}(?:[  ]\d{3})*(?:[.,]\d{1,2})?|-?\d+(?:[.,]\d{1,2})?)\s*(?:€|eur|euros?)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (text, nil)
        }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges == 3 else { return (text, nil) }
        let label = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
        // Un nombre seul reste une note, pas un montant étiqueté.
        guard !label.isEmpty else { return (text, nil) }
        let number = ns.substring(with: m.range(at: 2))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return (label, Double(number))
    }
}

/// Analyse des dates et heures écrites en français dans une phrase.
enum DateParserFR {

    struct Extraction {
        var date: Date?
        var duration: TimeInterval?
        var remainder: String
        var hasTime: Bool
        var hasExplicitMarker: Bool
    }

    private static let weekdays: [(String, Int)] = [
        ("dimanche", 1), ("lundi", 2), ("mardi", 3), ("mercredi", 4),
        ("jeudi", 5), ("vendredi", 6), ("samedi", 7)
    ]

    private static let months: [(String, Int)] = [
        ("janvier", 1), ("fevrier", 2), ("mars", 3), ("avril", 4), ("mai", 5), ("juin", 6),
        ("juillet", 7), ("aout", 8), ("septembre", 9), ("octobre", 10), ("novembre", 11), ("decembre", 12)
    ]

    static func extract(from text: String, reference: Date = Date()) -> Extraction {
        let cal = Calendar.current
        var day: Date? = nil
        var hour: Int? = nil
        var minute: Int = 0
        var duration: TimeInterval? = nil
        var explicit = false

        // Le repliage diacritique conserve le nombre de caractères pour le
        // français : on peut donc repérer sur `folded` et découper sur `text`.
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                  locale: Locale(identifier: "fr_FR"))

        // Les morceaux reconnus sont retirés en une seule fois à la fin, pour
        // que les positions repérées restent valides tout au long de l'analyse.
        var consumed: [NSRange] = []
        func consume(_ range: Range<String.Index>) {
            consumed.append(NSRange(range, in: folded))
        }
        func alreadyConsumed(_ range: Range<String.Index>) -> Bool {
            let ns = NSRange(range, in: folded)
            return consumed.contains { NSIntersectionRange($0, ns).length > 0 }
        }

        // --- Jour relatif
        let relatives: [(String, Int)] = [
            ("apres-demain", 2), ("apres demain", 2), ("demain", 1), ("aujourd'hui", 0),
            ("aujourdhui", 0), ("ce soir", 0), ("ce matin", 0), ("cet apres-midi", 0), ("cet aprem", 0)
        ]
        for (word, offset) in relatives {
            if let r = folded.range(of: word) {
                day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: reference))
                explicit = true
                consume(r)
                if word == "ce soir" { hour = 19 }
                if word == "ce matin" { hour = 9 }
                if word.contains("aprem") || word.contains("apres-midi") { hour = 14 }
                break
            }
        }

        // --- Jour de la semaine (prochaine occurrence)
        if day == nil {
            for (name, weekday) in weekdays {
                guard let r = folded.range(of: name) else { continue }
                var candidate = cal.startOfDay(for: reference)
                for _ in 0..<8 {
                    if cal.component(.weekday, from: candidate) == weekday, candidate > cal.startOfDay(for: reference) || cal.isDate(candidate, inSameDayAs: reference) {
                        break
                    }
                    candidate = cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
                }
                if cal.isDate(candidate, inSameDayAs: reference), folded.contains("prochain") {
                    candidate = cal.date(byAdding: .day, value: 7, to: candidate) ?? candidate
                }
                day = candidate
                explicit = true
                consume(r)
                break
            }
        }

        // --- « dans 3 jours », « dans 2 semaines »
        if day == nil, let m = firstMatch(#"dans (\d{1,3}) (jours?|semaines?|mois)"#, in: folded) {
            let n = Int(m.groups[0]) ?? 0
            let unit = m.groups[1]
            let component: Calendar.Component = unit.hasPrefix("sem") ? .weekOfYear : (unit.hasPrefix("mois") ? .month : .day)
            day = cal.date(byAdding: component, value: n, to: cal.startOfDay(for: reference))
            explicit = true
            consume(m.range)
        }

        // --- Date numérique « 12/09 », « 12/09/2026 », « 12-09 »
        if day == nil, let m = firstMatch(#"\b(\d{1,2})[/\.\-](\d{1,2})(?:[/\.\-](\d{2,4}))?\b"#, in: folded) {
            var comps = DateComponents()
            comps.day = Int(m.groups[0])
            comps.month = Int(m.groups[1])
            let hasYear = m.groups.count > 2 && !m.groups[2].isEmpty
            if hasYear, let y = Int(m.groups[2]) {
                comps.year = y < 100 ? 2000 + y : y
            } else {
                comps.year = cal.component(.year, from: reference)
            }
            if let d = cal.date(from: comps) {
                // Sans année explicite, une date passée désigne l'an prochain.
                day = (!hasYear && d < cal.startOfDay(for: reference))
                    ? cal.date(byAdding: .year, value: 1, to: d)
                    : d
                explicit = true
                consume(m.range)
            }
        }

        // --- « 12 septembre »
        if day == nil, let m = firstMatch(#"\b(\d{1,2})(?:er)? (janvier|fevrier|mars|avril|mai|juin|juillet|aout|septembre|octobre|novembre|decembre)\b"#, in: folded) {
            var comps = DateComponents()
            comps.day = Int(m.groups[0])
            comps.month = months.first { $0.0 == m.groups[1] }?.1
            comps.year = cal.component(.year, from: reference)
            if let d = cal.date(from: comps) {
                day = d < cal.startOfDay(for: reference) ? cal.date(byAdding: .year, value: 1, to: d) : d
                explicit = true
                consume(m.range)
            }
        }

        // --- Durée « pendant 2h », « pendant 1h30 »
        // Repérée avant l'heure, sinon « pendant 1h30 » serait pris pour un horaire.
        if let m = firstMatch(#"pendant (\d{1,2})\s*h\s*(\d{2})?"#, in: folded) {
            let h = Double(m.groups[0]) ?? 1
            let mi = m.groups.count > 1 ? (Double(m.groups[1]) ?? 0) : 0
            duration = h * 3600 + mi * 60
            consume(m.range)
        }

        // --- Heure « 14h30 », « 14h », « 14:30 », « à 9 h »
        if let m = firstMatch(#"\b(?:a |à )?(\d{1,2})\s*(?:h|:)\s*(\d{2})?\b"#, in: folded),
           !alreadyConsumed(m.range) {
            hour = Int(m.groups[0])
            if m.groups.count > 1, let mm = Int(m.groups[1]) { minute = mm }
            explicit = true
            consume(m.range)
        }

        // Retrait des morceaux reconnus, du dernier au premier.
        var remainder = text
        for range in consumed.sorted(by: { $0.location > $1.location }) {
            guard let r = Range(range, in: remainder) else { continue }
            remainder.removeSubrange(r)
        }

        guard explicit else {
            return Extraction(date: nil, duration: nil, remainder: cleanup(text),
                              hasTime: false, hasExplicitMarker: false)
        }

        let base = day ?? cal.startOfDay(for: reference)
        var final = base
        if let h = hour {
            final = cal.date(bySettingHour: min(h, 23), minute: min(minute, 59), second: 0, of: base) ?? base
            // Une heure déjà passée aujourd'hui bascule au lendemain.
            if day == nil && final < reference {
                final = cal.date(byAdding: .day, value: 1, to: final) ?? final
            }
        }

        return Extraction(date: final, duration: duration, remainder: cleanup(remainder),
                          hasTime: hour != nil, hasExplicitMarker: true)
    }

    private static func cleanup(_ s: String) -> String {
        var out = s
        for filler in [" a ", " à ", " le ", " de ", " du ", " vers "] {
            if out.hasPrefix(filler.trimmingCharacters(in: .whitespaces) + " ") {
                out = String(out.dropFirst(filler.trimmingCharacters(in: .whitespaces).count + 1))
            }
        }
        out = out.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        out = out.trimmingCharacters(in: CharacterSet(charactersIn: " ,;:-–"))
        return out
    }

    struct Match {
        let range: Range<String.Index>
        let groups: [String]
    }

    static func firstMatch(_ pattern: String, in text: String) -> Match? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              let range = Range(m.range, in: text) else { return nil }
        var groups: [String] = []
        for i in 1..<m.numberOfRanges {
            let r = m.range(at: i)
            groups.append(r.location == NSNotFound ? "" : ns.substring(with: r))
        }
        return Match(range: range, groups: groups)
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first = self.first else { return self }
        return first.uppercased() + dropFirst()
    }
}
