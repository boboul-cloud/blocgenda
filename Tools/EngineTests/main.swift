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
