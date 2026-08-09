import Foundation

var failures = 0
func check(_ label: String, _ got: String, _ want: String) {
    let ok = got == want
    if !ok { failures += 1 }
    print("\(ok ? "✓" : "✗") \(label)  →  \(got)\(ok ? "" : "   (attendu : \(want))")")
}

print("── Calculatrice ──")
func calc(_ s: String) -> String {
    guard let r = Calculator.evaluate(s) else { return "nil" }
    return "\(r.pretty) = \(NumberStyleFR.format(r.value))"
}
check("12,50 × 3", calc("12,50 × 3"), "12,50 × 3 = 37,5")
check("200 + 10%", calc("200 + 10%"), "200 + 10 % = 220")
check("200 - 10%", calc("200 - 10%"), "200 - 10 % = 180")
check("20% de 80", calc("20% de 80"), "20 % × 80 = 16")
check("1 250 € - 199,99", calc("1 250 € - 199,99"), "1250 - 199,99 = 1 050,01")
check("(2+3)*4", calc("(2+3)*4"), "(2 + 3) × 4 = 20")
check("racine(16)", calc("racine(16)"), "racine(16) = 4")
check("1 250 × 1,20", calc("1 250 × 1,20"), "1250 × 1,20 = 1 500")
check("texte seul", calc("acheter du pain"), "nil")
check("nombre seul", calc("42"), "nil")
check("division par zéro", calc("5/0"), "nil")

print("\n── Barre intelligente ──")
let cal = Calendar.current
let ref = cal.date(from: DateComponents(year: 2026, month: 8, day: 7, hour: 9, minute: 0))!
let df: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
                          f.dateFormat = "dd/MM HH:mm"; return f }()

func intent(_ s: String) -> String {
    guard let p = SmartInput.parse(s, reference: ref) else { return "nil" }
    switch p.intent {
    case .calculation(_, let v): return "calcul \(NumberStyleFR.format(v))"
    case .task(let t, let d): return "action « \(t) »" + (d.map { " · \(df.string(from: $0))" } ?? "")
    case .event(let t, let s, let dur, let allDay):
        return "rdv « \(t) » \(df.string(from: s)) \(Int(dur/60))min\(allDay ? " journée" : "")"
    case .note(let t, let a): return "note « \(t) »" + (a.map { " · \(NumberStyleFR.format($0))" } ?? "")
    }
}
check("calcul", intent("12,50 × 3"), "calcul 37,5")
check("action", intent("- rappeler le garage"), "action « rappeler le garage »")
check("action datée", intent("- passer à la poste demain 10h"), "action « passer à la poste » · 08/08 10:00")
check("rdv demain", intent("demain 14h30 dentiste"), "rdv « Dentiste » 08/08 14:30 60min")
check("rdv durée", intent("réunion lundi 9h pendant 2h"), "rdv « Réunion » 10/08 09:00 120min")
check("rdv date", intent("12/09 8h contrôle technique"), "rdv « Contrôle technique » 12/09 08:00 60min")
check("rdv mois", intent("3 octobre anniversaire Léa"), "rdv « Anniversaire Léa » 03/10 00:00 60min journée")
check("heure passée", intent("8h café"), "rdv « Café » 08/08 08:00 60min")
check("note", intent("penser au bar de ligne au marché"), "note « penser au bar de ligne au marché »")
check("note chiffrée", intent("essence 62,30"), "note « essence » · 62,3")
let tagged = SmartInput.parse("courses 41,15 #maison", reference: ref)!
check("étiquettes", tagged.tags.joined(separator: ","), "maison")

print("\n── Anniversaires portés à l'agenda ──")

var lea = Contact(firstName: "Léa", lastName: "Kerdraon")
lea.birthday = cal.date(from: DateComponents(year: 1984, month: 10, day: 3))
let fete = AgendaEvent.birthday(for: lea)!

check("intitulé", fete.title, "Anniversaire de Léa Kerdraon")
check("toute la journée", "\(fete.isAllDay)", "true")
check("répétition", fete.repeatRule.label, "Tous les ans")
check("rappel la veille", fete.reminders.map(String.init).joined(), "1440")
check("personne concernée", "\(fete.contactID == lea.id)", "true")

// La répétition annuelle part de l'année de naissance : elle retombe sur le
// jour dit, toutes les années suivantes, et sur aucun autre jour.
func jourDeFete(_ y: Int, _ m: Int, _ d: Int) -> String {
    let day = cal.date(from: DateComponents(year: y, month: m, day: d))!
    return fete.occurrence(on: day).map { df.string(from: $0) } ?? "aucune"
}
check("occurrence 2026", jourDeFete(2026, 10, 3), "03/10 09:00")
check("occurrence 2031", jourDeFete(2031, 10, 3), "03/10 09:00")
check("la veille n'est pas le jour", jourDeFete(2026, 10, 2), "aucune")

// Le rappel de la veille tombe au matin, pas à minuit.
let rappel = fete.occurrence(on: cal.date(from: DateComponents(year: 2026, month: 10, day: 3))!)!
    .addingTimeInterval(-Double(AgendaEvent.dayBeforeReminder) * 60)
check("heure du rappel", df.string(from: rappel), "02/10 09:00")

print("\n── Import de l'annuaire ──")

// Deux écritures du même numéro désignent la même personne : la fiche reprise
// du carnet du téléphone ne doit pas doubler celle déjà saisie à la main.
let saisi = Contact(firstName: "Marie", lastName: "Lambert", phone: "06 12 34 56 78")
let repris = Contact(firstName: "Marie", lastName: "Lambert", phone: "+33 6 12 34 56 78")
check("même numéro, même fiche", "\(saisi.matchKey == repris.matchKey)", "true")

let autre = Contact(firstName: "Yann", lastName: "Le Goff", phone: "06 98 76 54 32")
check("numéro différent, autre fiche", "\(saisi.matchKey == autre.matchKey)", "false")

// Sans numéro, on se rabat sur le courriel, puis sur le nom.
let parMel = Contact(firstName: "Anne", email: "Anne@Exemple.fr ")
check("courriel normalisé", parMel.matchKey, "mel:anne@exemple.fr")
check("à défaut, le nom", Contact(firstName: "Élodie", lastName: "Créac'h").matchKey,
      "nom:elodie creac'h")

// Beaucoup de dates de naissance n'ont pas d'année : l'anniversaire tombe
// quand même tous les ans, mais l'âge ne s'invente pas.
var sansAnnee = Contact(firstName: "Gwen")
sansAnnee.birthday = cal.date(from: DateComponents(year: Contact.unknownBirthYear,
                                                   month: 3, day: 12))
check("anniversaire reconnu",
      "\(sansAnnee.hasBirthday(on: cal.date(from: DateComponents(year: 2026, month: 3, day: 12))!))",
      "true")
check("âge inconnu", sansAnnee.age().map(String.init) ?? "—", "—")
check("âge connu quand l'année l'est",
      lea.age(on: cal.date(from: DateComponents(year: 2026, month: 10, day: 3))!).map(String.init) ?? "—",
      "42")

print("\n── Marées : détection des étales ──")

func series(_ heights: [Double]) -> [TideDay.TideSample] {
    let start = Date(timeIntervalSince1970: 0)
    return heights.enumerated().map {
        .init(date: start.addingTimeInterval(Double($0.offset) * 3600), height: $0.element)
    }
}
func describe(_ marks: [TideMark]) -> String {
    marks.map { "\($0.isHigh ? "PM" : "BM")@\(Int($0.date.timeIntervalSince1970) / 3600)h" }
        .joined(separator: " ")
}

// Une marée franche : une basse mer, une pleine mer.
check("étales simples",
      describe(TideService.extrema(from: series([1, 0, -1, -2, -1, 0, 1, 2, 1, 0]))),
      "BM@3h PM@7h")

// Étale « plate » : deux relevés horaires à la même hauteur. Sans
// dédoublonnage, la basse mer était détectée — et affichée — deux fois.
check("étale plate comptée une seule fois",
      describe(TideService.extrema(from: series([1, 0, -2, -2, 0, 1, 2, 1]))),
      "BM@2h PM@6h")

check("plateau au sommet",
      describe(TideService.extrema(from: series([0, 1, 2, 2, 1, 0]))),
      "PM@2h")

// Marnage : sur la journée affichée, pas sur toute la période récupérée.
var day = TideDay()
let midnight = Calendar.current.startOfDay(for: Date())
day.marks = [
    TideMark(date: midnight.addingTimeInterval(5 * 3600), height: -2.21, isHigh: false),
    TideMark(date: midnight.addingTimeInterval(11 * 3600), height: 1.24, isHigh: true),
    TideMark(date: midnight.addingTimeInterval(18 * 3600), height: -2.02, isHigh: false),
    // Le lendemain, plus creux : ne doit pas gonfler le marnage du jour.
    TideMark(date: midnight.addingTimeInterval(30 * 3600), height: -2.77, isHigh: false)
]
check("marnage du jour affiché",
      String(format: "%.2f", day.range(on: midnight) ?? 0), "3.45")

// Recalage de phase. Le modèle qui fournit les hauteurs avance d'une petite
// heure près des côtes ; chaque port est rattaché à la station calibrée la
// plus proche. Mesures d'août 2026 — voir `TidePhase`.
func rattachement(_ lat: Double, _ lon: Double) -> String {
    guard let s = TidePhase.station(for: lat, longitude: lon) else { return "aucun" }
    return "\(s.name)+\(s.minutes)"
}
check("Brest se cale sur lui-même", rattachement(48.3833, -4.4950), "Brest+52")
// Portsall, Le Conquet et l'Aber-Wrac'h n'ont pas de mesure propre : ils
// prennent celle de la station voisine, comme un port rattaché d'annuaire.
check("Portsall se rattache à Brest", rattachement(48.5639, -4.7139), "Brest+52")
check("Le Conquet se rattache à Brest", rattachement(48.3600, -4.7700), "Brest+52")
check("Vannes se rattache à Lorient", rattachement(47.6350, -2.7600), "Lorient+36")
check("Les Sables se rattachent à La Rochelle", rattachement(46.4960, -1.7830), "La Rochelle+51")
// Hors de portée des stations mesurées, on ne corrige rien plutôt que de
// transposer un décalage dont rien ne dit qu'il vaille là-bas.
check("Marseille n'est pas recalée", rattachement(43.2965, 5.3698), "aucun")
check("Papeete n'est pas recalée", rattachement(-17.5350, -149.5700), "aucun")
check("Biarritz, trop loin, n'est pas recalée", rattachement(43.4830, -1.5586), "aucun")

// Le décalage s'applique à la courbe comme aux étales : une hauteur lue à une
// heure donnée doit rester cohérente avec les marées affichées à côté.
let brute = series([1, 0, -1, -2, -1, 0, 1, 2, 1, 0])
let recalee = brute.map { TideDay.TideSample(date: $0.date.addingTimeInterval(52 * 60),
                                             height: $0.height) }
check("les étales suivent le décalage",
      String(Int(TideService.extrema(from: recalee)[0].date
                 .timeIntervalSince(TideService.extrema(from: brute)[0].date) / 60)),
      "52")

print("\n── Astronomie (Brest, 7 août 2026) ──")
let sun = Astro.sunTimes(date: ref, lat: 48.3833, lon: -4.4950)
let hm: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
                          f.timeZone = TimeZone(identifier: "Europe/Paris")
                          f.dateFormat = "HH'h'mm"; return f }()
print("  lever   \(sun.sunrise.map { hm.string(from: $0) } ?? "—")   (attendu ≈ 06h55–07h05)")
print("  coucher \(sun.sunset.map { hm.string(from: $0) } ?? "—")   (attendu ≈ 21h45–21h55)")
let moon = Astro.moonIllumination(date: ref)
print("  lune    \(moon.name), \(Int(moon.fraction * 100)) % éclairée, âge \(String(format: "%.1f", moon.age)) j")

print("\n── Journal du jour ──")

func moment(_ hour: Int, _ minute: Int, _ text: String) -> JournalNote {
    JournalNote(date: cal.date(bySettingHour: hour, minute: minute, second: 0, of: ref)!,
                text: text)
}

let moments = [
    moment(7, 20, "réveil dans le brouillard"),
    moment(9, 5, "café sur le quai"),
    moment(14, 30, "le vent a tourné !"),
    moment(21, 10, "on a mangé dehors")
]

func mise(_ mood: JournalMood, _ notes: [JournalNote] = moments) -> String {
    var page = JournalPage(day: cal.startOfDay(for: ref), mood: mood)
    page.notes = notes
    return JournalLayout.compose(page).map { block in
        switch block {
        case .heading(let t): return "T(\(t))"
        case .paragraph(_, let t, _): return "P(\(t))"
        case .line(let n): return "L(\(n.trimmed))"
        case .pull(let n): return "E(\(n.trimmed))"
        case .rule: return "—"
        }
    }.joined(separator: " ")
}

check("humeur posée",
      mise(.posee),
      "T(Matin) P(Réveil dans le brouillard. Café sur le quai.) — T(Après-midi) "
      + "P(Le vent a tourné !) — T(Soir) P(On a mangé dehors.)")
check("humeur vive",
      mise(.vive),
      "T(Matin) L(réveil dans le brouillard) L(café sur le quai) — T(Après-midi) "
      + "E(le vent a tourné !) — T(Soir) L(on a mangé dehors)")
// À nombre de mots égal, c'est le moment le plus ancien qui monte en tête de
// page : la page doit se composer deux fois de suite de la même façon.
check("humeur songeuse",
      mise(.songeuse),
      "E(réveil dans le brouillard) — P(Café sur le quai. Le vent a tourné ! On a mangé dehors.)")
check("la maxime préférée à la tartine",
      mise(.songeuse, [moment(8, 0, "il a plu toute la nuit sur le toit de la véranda, et je n'ai pas fermé l'œil"),
                       moment(9, 0, "rien ne presse")]),
      "E(rien ne presse) — P(Il a plu toute la nuit sur le toit de la véranda, et je n'ai pas fermé l'œil.)")

check("les moments se rangent par demi-journée",
      JournalLayout.groups(of: moments).map { "\($0.moment.title)×\($0.notes.count)" }
          .joined(separator: ","),
      "Matin×2,Après-midi×1,Soir×1")
check("la couture ne double pas la ponctuation",
      JournalLayout.sewn([moment(8, 0, "il pleut."), moment(9, 0, "et alors ?")]),
      "Il pleut. Et alors ?")
check("une page vide ne compose rien",
      "\(JournalLayout.compose(JournalPage(day: ref)).count)", "0")
check("un seul moment n'est pas mis en exergue",
      mise(.vive, [moment(8, 0, "seul au monde")]), "T(Matin) L(seul au monde)")

print("\n── Thèmes de l'agenda ──")

func theme(_ name: String) -> AgendaEvent {
    var event = AgendaEvent()
    event.title = "Contrôle technique"
    event.theme = name
    event.start = ref
    return event
}

check("le thème se compare sans casse ni accent",
      "\(theme("Véhicule").belongs(toTheme: "vehicule"))", "true")
check("deux thèmes voisins ne se confondent pas",
      "\(theme("Véhicule").belongs(toTheme: "Santé"))", "false")
check("les espaces de bordure ne font pas un thème neuf",
      AgendaEvent.themeKey("  Santé "), AgendaEvent.themeKey("sante"))
check("un rendez-vous sans thème n'appartient à aucun",
      "\(AgendaEvent().hasTheme) \(AgendaEvent().belongs(toTheme: "Santé"))", "false false")
check("un thème réduit à des espaces vaut absent",
      "\(theme("   ").hasTheme)", "false")
let marie = Contact(firstName: "Marie", lastName: "Lambert", birthday: ref)
check("l'anniversaire venu de l'annuaire porte son thème",
      AgendaEvent.birthday(for: marie)?.themeName ?? "—", "Anniversaire")

// Un anniversaire inscrit avant que les thèmes n'existent se range tout seul,
// mais celui qu'on a déplacé à la main sous un autre sujet ne bouge plus.
var ancien = AgendaEvent()
ancien.applyBirthday(of: marie, on: ref)
ancien.theme = nil
check("un anniversaire sans thème en adopte un",
      "\(ancien.adoptBirthdayTheme()) \(ancien.themeName)", "true Anniversaire")
check("et ne le reprend pas deux fois",
      "\(ancien.adoptBirthdayTheme())", "false")
var range = ancien
range.theme = "Famille"
check("un anniversaire rangé à la main n'est pas déplacé",
      "\(range.adoptBirthdayTheme()) \(range.themeName)", "false Famille")
range.applyBirthday(of: marie, on: ref)
check("et l'annuaire ne l'écrase pas en se mettant à jour",
      range.themeName, "Famille")
var ordinaire = AgendaEvent()
ordinaire.title = "Contrôle technique"
check("un rendez-vous ordinaire ne devient pas un anniversaire",
      "\(ordinaire.adoptBirthdayTheme()) \(ordinaire.hasTheme)", "false false")

// La recherche par thème n'affiche qu'une échéance par rendez-vous : c'est
// celle-là qu'il faut trouver, même lorsqu'elle est loin devant.
let jourRef = cal.startOfDay(for: ref)
var annuel = theme("Véhicule")
annuel.repeatRule = .yearly
check("la prochaine échéance d'un rendez-vous annuel",
      annuel.nextStart(from: cal.date(byAdding: .day, value: 1, to: jourRef)!)
          .map { df.string(from: $0) } ?? "nil",
      "07/08 09:00")   // celle de l'an prochain, à l'heure d'origine
check("un rendez-vous unique déjà passé n'a plus d'échéance",
      theme("Véhicule").nextStart(from: cal.date(byAdding: .day, value: 1, to: jourRef)!)
          .map { df.string(from: $0) } ?? "nil",
      "nil")
check("le jour même compte pour une échéance",
      theme("Véhicule").nextStart(from: jourRef).map { df.string(from: $0) } ?? "nil",
      "07/08 09:00")

print("\n\(failures == 0 ? "Tout est vert." : "\(failures) échec(s).")")
exit(failures == 0 ? 0 : 1)
