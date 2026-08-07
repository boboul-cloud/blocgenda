import Foundation

/// Périodes solunaires : les créneaux où la faune est traditionnellement la plus
/// active (pêche, observation). Les périodes majeures encadrent le passage de la
/// lune au méridien, les mineures son lever et son coucher.
enum Solunar {

    struct Period: Identifiable, Hashable, Sendable {
        var id: Date { start }
        var start: Date
        var end: Date
        var isMajor: Bool

        var label: String { isMajor ? "Période majeure" : "Période mineure" }
        func contains(_ date: Date) -> Bool { date >= start && date <= end }
    }

    static func periods(for day: Date, lat: Double, lon: Double) -> [Period] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        var result: [Period] = []

        // Passages au méridien : extrêmes de la hauteur lunaire sur 24 h.
        var altitudes: [(Date, Double)] = []
        for step in 0...(24 * 6) {
            let d = start.addingTimeInterval(Double(step) * 600)
            altitudes.append((d, Astro.moonPosition(date: d, lat: lat, lon: lon).altitude))
        }
        for i in 1..<(altitudes.count - 1) {
            let a = altitudes[i - 1].1, b = altitudes[i].1, c = altitudes[i + 1].1
            if (b >= a && b >= c) || (b <= a && b <= c) {
                let t = altitudes[i].0
                result.append(Period(start: t.addingTimeInterval(-3600),
                                     end: t.addingTimeInterval(3600),
                                     isMajor: true))
            }
        }

        let moon = Astro.moonTimes(date: day, lat: lat, lon: lon)
        for t in [moon.rise, moon.set].compactMap({ $0 }) {
            result.append(Period(start: t.addingTimeInterval(-45 * 60),
                                 end: t.addingTimeInterval(45 * 60),
                                 isMajor: false))
        }

        return result.sorted { $0.start < $1.start }
    }

    /// Note du jour sur 4 : la pêche est réputée meilleure autour des syzygies
    /// (nouvelle et pleine lune), quand les marées sont les plus fortes.
    static func dayRating(for day: Date) -> Int {
        let phase = Astro.moonIllumination(date: day).phase
        let distanceToSyzygy = min(min(phase, abs(phase - 0.5)), abs(phase - 1))
        switch distanceToSyzygy {
        case ..<0.03: return 4
        case ..<0.08: return 3
        case ..<0.16: return 2
        default: return 1
        }
    }
}
