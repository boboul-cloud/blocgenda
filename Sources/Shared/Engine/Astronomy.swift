import Foundation

/// Éphémérides solaires et lunaires calculées localement (algorithmes de Meeus,
/// tels qu'implémentés par la bibliothèque de référence SunCalc).
/// Aucune connexion réseau n'est nécessaire : l'app reste utilisable hors ligne.
enum Astro {

    // MARK: - Bases

    static let rad = Double.pi / 180
    static let dayMs: Double = 86_400
    static let J1970: Double = 2_440_588
    static let J2000: Double = 2_451_545
    static let e = 23.4397 * (Double.pi / 180) // obliquité de l'écliptique

    static func toJulian(_ date: Date) -> Double {
        date.timeIntervalSince1970 / dayMs - 0.5 + J1970
    }
    static func fromJulian(_ j: Double) -> Date? {
        guard j.isFinite else { return nil }
        return Date(timeIntervalSince1970: (j + 0.5 - J1970) * dayMs)
    }
    static func toDays(_ date: Date) -> Double { toJulian(date) - J2000 }

    static func rightAscension(_ l: Double, _ b: Double) -> Double {
        atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
    }
    static func declination(_ l: Double, _ b: Double) -> Double {
        asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))
    }
    static func azimuth(_ H: Double, _ phi: Double, _ dec: Double) -> Double {
        atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi))
    }
    static func altitude(_ H: Double, _ phi: Double, _ dec: Double) -> Double {
        asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H))
    }
    static func siderealTime(_ d: Double, _ lw: Double) -> Double {
        rad * (280.16 + 360.9856235 * d) - lw
    }
    static func astroRefraction(_ h0: Double) -> Double {
        let h = max(h0, 0)
        return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179))
    }

    // MARK: - Soleil

    static func solarMeanAnomaly(_ d: Double) -> Double { rad * (357.5291 + 0.98560028 * d) }

    static func eclipticLongitude(_ M: Double) -> Double {
        let C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M))
        let P = rad * 102.9372
        return M + C + P + .pi
    }

    static func sunCoords(_ d: Double) -> (dec: Double, ra: Double) {
        let M = solarMeanAnomaly(d)
        let L = eclipticLongitude(M)
        return (declination(L, 0), rightAscension(L, 0))
    }

    /// Distance Terre–Soleil en unités astronomiques. La marée solaire varie
    /// comme le cube de son inverse : d'où le renflement des marées d'hiver,
    /// quand la Terre passe au plus près du soleil.
    static func sunDistanceAU(_ d: Double) -> Double {
        let M = solarMeanAnomaly(d)
        return 1.00014 - 0.01671 * cos(M) - 0.00014 * cos(2 * M)
    }

    /// Position apparente du soleil : azimut (0 = sud, sens horaire) et hauteur.
    static func sunPosition(date: Date, lat: Double, lon: Double) -> (azimuth: Double, altitude: Double) {
        let lw = rad * -lon
        let phi = rad * lat
        let d = toDays(date)
        let c = sunCoords(d)
        let H = siderealTime(d, lw) - c.ra
        return (azimuth(H, phi, c.dec), altitude(H, phi, c.dec))
    }

    private static let J0 = 0.0009

    private static func julianCycle(_ d: Double, _ lw: Double) -> Double {
        (d - J0 - lw / (2 * .pi)).rounded()
    }
    private static func approxTransit(_ Ht: Double, _ lw: Double, _ n: Double) -> Double {
        J0 + (Ht + lw) / (2 * .pi) + n
    }
    private static func solarTransitJ(_ ds: Double, _ M: Double, _ L: Double) -> Double {
        J2000 + ds + 0.0053 * sin(M) - 0.0069 * sin(2 * L)
    }
    private static func hourAngle(_ h: Double, _ phi: Double, _ d: Double) -> Double {
        acos((sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d)))
    }

    /// Instants remarquables de la course du soleil pour un jour et un lieu.
    struct SunTimes: Hashable, Sendable {
        var nightEnd: Date?        // fin de la nuit astronomique
        var dawn: Date?            // aube civile
        var sunrise: Date?
        var sunriseEnd: Date?
        var goldenHourEnd: Date?   // fin de l'heure dorée du matin
        var solarNoon: Date?
        var goldenHour: Date?      // début de l'heure dorée du soir
        var sunsetStart: Date?
        var sunset: Date?
        var dusk: Date?            // crépuscule civil
        var night: Date?           // début de la nuit astronomique
        var nadir: Date?

        /// Durée du jour (lever → coucher).
        var dayLength: TimeInterval? {
            guard let sunrise, let sunset else { return nil }
            return sunset.timeIntervalSince(sunrise)
        }
        /// Fenêtre "heure bleue" du soir : entre le coucher et le crépuscule.
        var blueHourEvening: (Date, Date)? {
            guard let sunset, let dusk else { return nil }
            return (sunset, dusk)
        }
        var blueHourMorning: (Date, Date)? {
            guard let dawn, let sunrise else { return nil }
            return (dawn, sunrise)
        }
    }

    private static let sunAngles: [(angle: Double, rise: WritableKeyPath<SunTimes, Date?>, set: WritableKeyPath<SunTimes, Date?>)] = [
        (-0.833, \.sunrise, \.sunset),
        (-0.3, \.sunriseEnd, \.sunsetStart),
        (-6, \.dawn, \.dusk),
        (-12, \.nightEnd, \.night),
        (6, \.goldenHourEnd, \.goldenHour)
    ]

    static func sunTimes(date: Date, lat: Double, lon: Double) -> SunTimes {
        let lw = rad * -lon
        let phi = rad * lat
        let d = toDays(Calendar.current.startOfDay(for: date).addingTimeInterval(12 * 3600))
        let n = julianCycle(d, lw)
        let ds = approxTransit(0, lw, n)
        let M = solarMeanAnomaly(ds)
        let L = eclipticLongitude(M)
        let dec = declination(L, 0)
        let Jnoon = solarTransitJ(ds, M, L)

        var times = SunTimes()
        times.solarNoon = fromJulian(Jnoon)
        times.nadir = fromJulian(Jnoon - 0.5)

        for a in sunAngles {
            let h0 = a.angle * rad
            let w = hourAngle(h0, phi, dec)
            guard w.isFinite else { continue }
            let Jset = solarTransitJ(approxTransit(w, lw, n), M, L)
            let Jrise = Jnoon - (Jset - Jnoon)
            times[keyPath: a.rise] = fromJulian(Jrise)
            times[keyPath: a.set] = fromJulian(Jset)
        }
        return times
    }

    // MARK: - Lune

    static func moonCoords(_ d: Double) -> (ra: Double, dec: Double, dist: Double) {
        let L = rad * (218.316 + 13.176396 * d)  // longitude écliptique moyenne
        let M = rad * (134.963 + 13.064993 * d)  // anomalie moyenne
        let F = rad * (93.272 + 13.229350 * d)   // distance moyenne au nœud

        let l = L + rad * 6.289 * sin(M)
        let b = rad * 5.128 * sin(F)
        let dt = 385001 - 20905 * cos(M)
        return (rightAscension(l, b), declination(l, b), dt)
    }

    /// La même position, avec les termes que `moonCoords` laisse tomber.
    ///
    /// Pour dessiner un croissant ou lever la lune, la série courte suffit. Le
    /// coefficient de marée, lui, varie comme le **cube** de la distance : les
    /// deux termes que le soleil impose à l'orbite lunaire — l'évection et la
    /// variation, quelque six mille kilomètres à eux deux — font toute la
    /// différence entre une grande marée ordinaire et une très grande. Sans
    /// eux, l'estimation manquait cinq points sur les marées d'équinoxe.
    ///
    /// Termes principaux de Meeus (chapitre 47), tronqués là où ils cessent de
    /// peser sur le coefficient.
    static func moonCoordsFine(_ d: Double) -> (ra: Double, dec: Double, dist: Double) {
        let L = rad * (218.316 + 13.176396 * d)   // longitude moyenne
        let M = rad * (134.963 + 13.064993 * d)   // anomalie moyenne de la lune
        let F = rad * (93.272 + 13.229350 * d)    // distance moyenne au nœud
        let D = rad * (297.850 + 12.190749 * d)   // élongation moyenne
        let Ms = rad * (357.529 + 0.985600 * d)   // anomalie moyenne du soleil

        let l = L + rad * (6.289 * sin(M) + 1.274 * sin(2 * D - M) + 0.658 * sin(2 * D)
                           + 0.214 * sin(2 * M) - 0.186 * sin(Ms) - 0.114 * sin(2 * F))
        let b = rad * (5.128 * sin(F) + 0.281 * sin(M + F) - 0.278 * sin(F - M))
        let dist = 385000.56
            - 20905.355 * cos(M)
            - 3699.111 * cos(2 * D - M)
            - 2955.968 * cos(2 * D)
            - 569.925 * cos(2 * M)
            + 246.158 * cos(2 * M - 2 * D)
            - 204.586 * cos(Ms - 2 * D)
            - 170.733 * cos(M + 2 * D)
            - 152.138 * cos(M - 2 * D + Ms)
        return (rightAscension(l, b), declination(l, b), dist)
    }

    /// Demi-grand axe de l'orbite lunaire, à la même échelle que `moonCoordsFine`.
    static let meanMoonDistance = 385000.56

    static func moonPosition(date: Date, lat: Double, lon: Double) -> (azimuth: Double, altitude: Double, distance: Double, parallacticAngle: Double) {
        let lw = rad * -lon
        let phi = rad * lat
        let d = toDays(date)
        let c = moonCoords(d)
        let H = siderealTime(d, lw) - c.ra
        var h = altitude(H, phi, c.dec)
        let pa = atan2(sin(H), tan(phi) * cos(c.dec) - sin(c.dec) * cos(H))
        h += astroRefraction(h)
        return (azimuth(H, phi, c.dec), h, c.dist, pa)
    }

    struct MoonIllumination: Hashable, Sendable {
        var fraction: Double  // 0 = nouvelle lune, 1 = pleine lune
        var phase: Double     // 0 → 1 sur le cycle synodique
        var angle: Double

        /// Âge de la lune en jours depuis la nouvelle lune.
        var age: Double { phase * 29.530588853 }

        var isWaxing: Bool { phase < 0.5 }

        var name: String {
            switch phase {
            case ..<0.02: return "Nouvelle lune"
            case ..<0.24: return "Premier croissant"
            case ..<0.26: return "Premier quartier"
            case ..<0.49: return "Gibbeuse croissante"
            case ..<0.51: return "Pleine lune"
            case ..<0.74: return "Gibbeuse décroissante"
            case ..<0.76: return "Dernier quartier"
            case ..<0.98: return "Dernier croissant"
            default: return "Nouvelle lune"
            }
        }

        var symbolName: String {
            switch phase {
            case ..<0.02: return "moonphase.new.moon"
            case ..<0.24: return "moonphase.waxing.crescent"
            case ..<0.26: return "moonphase.first.quarter"
            case ..<0.49: return "moonphase.waxing.gibbous"
            case ..<0.51: return "moonphase.full.moon"
            case ..<0.74: return "moonphase.waning.gibbous"
            case ..<0.76: return "moonphase.last.quarter"
            case ..<0.98: return "moonphase.waning.crescent"
            default: return "moonphase.new.moon"
            }
        }
    }

    static func moonIllumination(date: Date) -> MoonIllumination {
        let sdist: Double = 149_598_000
        let d = toDays(date)
        let s = sunCoords(d)
        let m = moonCoords(d)

        let phi = acos(sin(s.dec) * sin(m.dec) + cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra))
        let inc = atan2(sdist * sin(phi), m.dist - sdist * cos(phi))
        let angle = atan2(cos(s.dec) * sin(s.ra - m.ra),
                          sin(s.dec) * cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra))

        return MoonIllumination(
            fraction: (1 + cos(inc)) / 2,
            phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / .pi,
            angle: angle)
    }

    /// Lever et coucher de la lune pour la journée locale.
    static func moonTimes(date: Date, lat: Double, lon: Double) -> (rise: Date?, set: Date?, alwaysUp: Bool, alwaysDown: Bool) {
        let start = Calendar.current.startOfDay(for: date)
        let hc = 0.133 * rad
        var h0 = moonPosition(date: start, lat: lat, lon: lon).altitude - hc
        var rise: Double?
        var set: Double?
        var ye: Double = 0

        var i = 1.0
        while i <= 24 {
            let h1 = moonPosition(date: start.addingTimeInterval(i * 3600), lat: lat, lon: lon).altitude - hc
            let h2 = moonPosition(date: start.addingTimeInterval((i + 1) * 3600), lat: lat, lon: lon).altitude - hc

            let a = (h0 + h2) / 2 - h1
            let b = (h2 - h0) / 2
            let xe = -b / (2 * a)
            ye = (a * xe + b) * xe + h1
            let d = b * b - 4 * a * h1
            var roots = 0
            var x1: Double = 0
            var x2: Double = 0

            if d >= 0 {
                let dx = sqrt(d) / (abs(a) * 2)
                x1 = xe - dx
                x2 = xe + dx
                if abs(x1) <= 1 { roots += 1 }
                if abs(x2) <= 1 { roots += 1 }
                if x1 < -1 { x1 = x2 }
            }

            if roots == 1 {
                if h0 < 0 { rise = i + x1 } else { set = i + x1 }
            } else if roots == 2 {
                rise = i + (ye < 0 ? x2 : x1)
                set = i + (ye < 0 ? x1 : x2)
            }

            if rise != nil && set != nil { break }
            h0 = h2
            i += 2
        }

        let riseDate = rise.map { start.addingTimeInterval($0 * 3600) }
        let setDate = set.map { start.addingTimeInterval($0 * 3600) }
        return (riseDate, setDate, rise == nil && set == nil && ye > 0, rise == nil && set == nil && ye <= 0)
    }

    /// Prochaine nouvelle lune / pleine lune à partir d'une date.
    static func nextPhase(_ target: Double, after date: Date) -> Date? {
        // Recherche par balayage journalier puis affinage à la minute.
        var best: Date?
        var previous = moonIllumination(date: date).phase
        for day in 1...45 {
            guard let d = Calendar.current.date(byAdding: .day, value: day, to: date) else { break }
            let p = moonIllumination(date: d).phase
            if crossed(target, previous, p) {
                best = d
                break
            }
            previous = p
        }
        guard var coarse = best else { return nil }
        coarse = coarse.addingTimeInterval(-86_400)
        var prev = moonIllumination(date: coarse).phase
        for step in 1...(24 * 60) {
            let d = coarse.addingTimeInterval(Double(step) * 60)
            let p = moonIllumination(date: d).phase
            if crossed(target, prev, p) { return d }
            prev = p
        }
        return best
    }

    private static func crossed(_ target: Double, _ a: Double, _ b: Double) -> Bool {
        if a <= b { return a < target && target <= b }
        // passage par 0 (nouvelle lune)
        return target > a || target <= b
    }
}
