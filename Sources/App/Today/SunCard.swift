import SwiftUI

/// La course du soleil : un arc où le disque avance au fil de la journée,
/// avec les heures clés et la météo du moment.
struct SunCard: View {
    let sun: Astro.SunTimes?
    let weather: WeatherNow?
    let now: Date
    let yesterday: Astro.SunTimes

    private var progress: Double? {
        guard let rise = sun?.sunrise, let set = sun?.sunset else { return nil }
        let total = set.timeIntervalSince(rise)
        guard total > 0 else { return nil }
        return ((now.timeIntervalSince(rise)) / total).clamped(to: 0...1)
    }

    /// Écart de durée du jour avec la veille — le fameux « les jours rallongent ».
    private var delta: Int? {
        guard let today = sun?.dayLength, let before = yesterday.dayLength else { return nil }
        return Int((today - before) / 60)
    }

    private var deltaText: String? {
        guard let delta else { return nil }
        guard delta != 0 else { return "durée identique à hier" }
        return delta > 0 ? "+\(delta) min qu’hier" : "−\(abs(delta)) min qu’hier"
    }

    var body: some View {
        ChassisCard(title: "Soleil", systemImage: "sun.max.fill", accent: Ink.amberDeep) {
            VStack(spacing: 14) {
                SunArc(progress: progress, isDay: isDaytime)
                    .frame(height: 96)

                HStack(alignment: .top) {
                    timeBlock(icon: "sunrise.fill", label: "Lever", date: sun?.sunrise, tint: Ink.amberDeep)
                    Spacer()
                    VStack(spacing: 2) {
                        Text(sun?.dayLength.map { Fmt.duration($0) } ?? "—")
                            .font(Type.ui(15, weight: .bold))
                            .foregroundStyle(Ink.text)
                        Text("de jour")
                            .font(Type.ui(10))
                            .foregroundStyle(Ink.textFaint)
                        if let deltaText {
                            Text(deltaText)
                                .font(Type.ui(10, weight: .medium))
                                .foregroundStyle((delta ?? 0) >= 0 ? Ink.moss : Ink.amberDeep)
                        }
                    }
                    Spacer()
                    timeBlock(icon: "sunset.fill", label: "Coucher", date: sun?.sunset, tint: Ink.amberDeep)
                }

                if let weather {
                    Divider().overlay(Ink.chassisLine)
                    HStack(spacing: 12) {
                        Image(systemName: weather.symbolName)
                            .font(Type.icon(22))
                            .symbolRenderingMode(.multicolor)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(Int(weather.temperature.rounded())) °C · \(weather.label)")
                                .font(Type.ui(13, weight: .semibold))
                                .foregroundStyle(Ink.text)
                            Text("ressenti \(Int(weather.apparentTemperature.rounded())) °C · vent \(Int(weather.windSpeed.rounded())) km/h \(weather.windCardinal) · force \(weather.beaufort)")
                                .font(Type.ui(10.5))
                                .foregroundStyle(Ink.textFaint)
                        }
                        Spacer(minLength: 0)
                        if let min = weather.minTemperature, let max = weather.maxTemperature {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Int(max.rounded()))°").font(Type.ui(12, weight: .semibold))
                                    .foregroundStyle(Ink.amberDeep)
                                Text("\(Int(min.rounded()))°").font(Type.ui(12))
                                    .foregroundStyle(Ink.sea)
                            }
                        }
                    }
                }
            }
        }
    }

    private var isDaytime: Bool {
        guard let rise = sun?.sunrise, let set = sun?.sunset else { return true }
        return now >= rise && now <= set
    }

    private func timeBlock(icon: String, label: String, date: Date?, tint: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(Type.icon(13, weight: .semibold))
                .foregroundStyle(tint)
            Text(date.map { Fmt.hm.string(from: $0) } ?? "—")
                .font(Type.tape(14, weight: .semibold))
                .foregroundStyle(Ink.text)
            Text(label)
                .font(Type.ui(10))
                .foregroundStyle(Ink.textFaint)
        }
    }
}

/// L'arc de la course solaire, dessiné au trait.
struct SunArc: View {
    /// 0 au lever, 1 au coucher. `nil` si le soleil ne se lève pas.
    let progress: Double?
    let isDay: Bool

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 12
            let baseline = size.height - 14
            let width = size.width - inset * 2
            let height = size.height - 26

            func point(_ t: Double) -> CGPoint {
                let x = inset + width * t
                let y = baseline - sin(t * .pi) * height
                return CGPoint(x: x, y: y)
            }

            // Ligne d'horizon
            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: baseline))
            horizon.addLine(to: CGPoint(x: size.width, y: baseline))
            context.stroke(horizon, with: .color(Ink.chassisLine), lineWidth: 1)

            // Arc complet, en pointillés
            var full = Path()
            full.move(to: point(0))
            for i in 1...80 { full.addLine(to: point(Double(i) / 80)) }
            context.stroke(full, with: .color(Ink.textFaint.opacity(0.35)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))

            guard let progress else { return }

            // Portion déjà parcourue, pleine et dégradée
            var done = Path()
            done.move(to: point(0))
            let steps = max(1, Int(progress * 80))
            for i in 1...steps { done.addLine(to: point(Double(i) / 80)) }
            context.stroke(done,
                           with: .linearGradient(
                            Gradient(colors: [Ink.amberDeep, Ink.amber]),
                            startPoint: CGPoint(x: inset, y: baseline),
                            endPoint: CGPoint(x: size.width - inset, y: baseline)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Le disque
            let p = point(progress)
            let radius: CGFloat = isDay ? 9 : 6
            context.fill(Path(ellipseIn: CGRect(x: p.x - radius * 2.4, y: p.y - radius * 2.4,
                                                width: radius * 4.8, height: radius * 4.8)),
                         with: .radialGradient(
                            Gradient(colors: [Ink.amber.opacity(0.35), .clear]),
                            center: p, startRadius: 0, endRadius: radius * 2.4))
            context.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius,
                                                width: radius * 2, height: radius * 2)),
                         with: .color(isDay ? Ink.amber : Ink.textFaint))
        }
    }
}

/// Heures dorée et bleue : le créneau des photographes.
struct LightCard: View {
    let sun: Astro.SunTimes?
    let now: Date

    var body: some View {
        ChassisCard(title: "Lumière", systemImage: "camera.filters", accent: Ink.violet) {
            VStack(spacing: 10) {
                row(label: "Heure dorée du matin",
                    from: sun?.sunrise, to: sun?.goldenHourEnd, color: Ink.amberDeep)
                row(label: "Heure dorée du soir",
                    from: sun?.goldenHour, to: sun?.sunset, color: Ink.amberDeep)
                row(label: "Heure bleue",
                    from: sun?.sunset, to: sun?.dusk, color: Ink.sea)
                row(label: "Nuit noire",
                    from: sun?.night, to: sun?.nightEnd, color: Ink.violet)
            }
        }
    }

    private func row(label: String, from: Date?, to: Date?, color: Color) -> some View {
        let active = (from.map { now >= $0 } ?? false) && (to.map { now <= $0 } ?? false)
        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(Type.ui(12, weight: active ? .bold : .regular))
                .foregroundStyle(active ? Ink.text : Ink.textSoft)
            if active {
                Text("en cours")
                    .font(Type.ui(9, weight: .bold))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(color.opacity(0.25)))
                    .foregroundStyle(color)
            }
            Spacer(minLength: 4)
            Text(range(from, to))
                .font(Type.tape(11))
                .foregroundStyle(Ink.textFaint)
        }
    }

    private func range(_ a: Date?, _ b: Date?) -> String {
        guard let a, let b else { return "—" }
        return "\(Fmt.hm.string(from: a)) → \(Fmt.hm.string(from: b))"
    }
}
