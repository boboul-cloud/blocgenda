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

print("\n── Astronomie (Brest, 7 août 2026) ──")
let sun = Astro.sunTimes(date: ref, lat: 48.3833, lon: -4.4950)
let hm: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
                          f.timeZone = TimeZone(identifier: "Europe/Paris")
                          f.dateFormat = "HH'h'mm"; return f }()
print("  lever   \(sun.sunrise.map { hm.string(from: $0) } ?? "—")   (attendu ≈ 06h55–07h05)")
print("  coucher \(sun.sunset.map { hm.string(from: $0) } ?? "—")   (attendu ≈ 21h45–21h55)")
let moon = Astro.moonIllumination(date: ref)
print("  lune    \(moon.name), \(Int(moon.fraction * 100)) % éclairée, âge \(String(format: "%.1f", moon.age)) j")

print("\n\(failures == 0 ? "Tout est vert." : "\(failures) échec(s).")")
exit(failures == 0 ? 0 : 1)
