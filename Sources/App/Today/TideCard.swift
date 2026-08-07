import Charts
import SwiftUI

/// La marée du lieu : la courbe du jour, la prochaine étale et le marnage.
struct TideCard: View {
    let tide: TideDay?
    let error: String?
    let loading: Bool
    let moon: Astro.MoonIllumination?
    let now: Date

    private var todaySamples: [TideDay.TideSample] {
        guard let tide else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = start.addingTimeInterval(86_400)
        return tide.samples.filter { $0.date >= start && $0.date <= end }
    }

    private var todayMarks: [TideMark] {
        guard let tide else { return [] }
        return tide.marks.filter { Calendar.current.isDate($0.date, inSameDayAs: now) }
    }

    private var next: TideMark? {
        tide?.marks.first { $0.date > now }
    }

    /// Vive-eau ou morte-eau, d'après la position de la lune.
    private var springNeapLabel: String? {
        guard let moon else { return nil }
        let d = min(min(moon.phase, abs(moon.phase - 0.5)), abs(moon.phase - 1))
        switch d {
        case ..<0.08: return "vive-eau"
        case ..<0.17: return "marée moyenne"
        default: return "morte-eau"
        }
    }

    var body: some View {
        ChassisCard(title: "Marée", systemImage: "water.waves", accent: Ink.sea) {
            if let error {
                VStack(alignment: .leading, spacing: 6) {
                    Text(error)
                        .font(Type.ui(12))
                        .foregroundStyle(Ink.textSoft)
                    Text("Choisissez un port de référence depuis le lieu, en haut de l’écran.")
                        .font(Type.ui(11))
                        .foregroundStyle(Ink.textFaint)
                }
            } else if todaySamples.isEmpty {
                HStack(spacing: 8) {
                    if loading { ProgressView().controlSize(.small) }
                    Text(loading ? "Lecture de la marée…" : "Marée indisponible.")
                        .font(Type.ui(12))
                        .foregroundStyle(Ink.textSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    headline
                    chart.frame(height: 110)
                    marksRow
                    footer
                    Text("Hauteurs par rapport au niveau moyen de la mer (prévision Open-Meteo). Pour naviguer, référez-vous à l’annuaire officiel des marées.")
                        .font(Type.ui(9.5))
                        .foregroundStyle(Ink.textFaint.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var headline: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let next {
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.label)
                        .font(Type.ui(13, weight: .bold))
                        .foregroundStyle(next.isHigh ? Ink.sea : Ink.amber)
                    Text("\(Fmt.hm.string(from: next.date)) · \(Fmt.relative(next.date, from: now))")
                        .font(Type.ui(11))
                        .foregroundStyle(Ink.textFaint)
                }
            }
            Spacer(minLength: 0)
            if let height = tide?.height(at: now) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%+.2f m", height))
                        .font(Type.tape(15, weight: .semibold))
                        .foregroundStyle(Ink.paper)
                    if let rising = tide?.isRising(at: now) {
                        Label(rising ? "montante" : "descendante",
                              systemImage: rising ? "arrow.up.right" : "arrow.down.right")
                            .font(Type.ui(10, weight: .medium))
                            .foregroundStyle(rising ? Ink.sea : Ink.amber)
                    }
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(todaySamples, id: \.date) { sample in
                AreaMark(x: .value("Heure", sample.date),
                         y: .value("Hauteur", sample.height))
                    .foregroundStyle(
                        LinearGradient(colors: [Ink.sea.opacity(0.45), Ink.sea.opacity(0.03)],
                                       startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Heure", sample.date),
                         y: .value("Hauteur", sample.height))
                    .foregroundStyle(Ink.sea)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
            }

            ForEach(todayMarks) { mark in
                PointMark(x: .value("Heure", mark.date),
                          y: .value("Hauteur", mark.height))
                    .foregroundStyle(mark.isHigh ? Ink.sea : Ink.amber)
                    .symbolSize(40)
                    .annotation(position: mark.isHigh ? .top : .bottom, spacing: 2) {
                        Text(Fmt.hm.string(from: mark.date))
                            .font(Type.tape(8.5, weight: .medium))
                            .foregroundStyle(Ink.textFaint)
                    }
            }

            RuleMark(x: .value("Maintenant", now))
                .foregroundStyle(Ink.paper.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisValueLabel(format: .dateTime.hour())
                    .font(Type.ui(9))
                    .foregroundStyle(Ink.textFaint)
                AxisGridLine().foregroundStyle(Ink.chassisLine)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisValueLabel()
                    .font(Type.ui(9))
                    .foregroundStyle(Ink.textFaint)
                AxisGridLine().foregroundStyle(Ink.chassisLine.opacity(0.6))
            }
        }
    }

    private var marksRow: some View {
        HStack(spacing: 6) {
            ForEach(todayMarks) { mark in
                VStack(spacing: 1) {
                    Image(systemName: mark.symbol)
                        .font(.system(size: 9, weight: .bold))
                    Text(Fmt.hm.string(from: mark.date))
                        .font(Type.tape(11, weight: .semibold))
                    Text(String(format: "%.2f m", mark.height))
                        .font(Type.tape(9))
                        .foregroundStyle(Ink.textFaint)
                }
                .foregroundStyle(mark.isHigh ? Ink.sea : Ink.amber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.black.opacity(0.22)))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let port = tide?.portName {
                Pill(text: port, color: Ink.sea)
            }
            if let springNeapLabel {
                Pill(text: springNeapLabel, color: Ink.violet)
            }
            Spacer(minLength: 0)
            if let range = tide?.range(on: now) {
                Text(String(format: "marnage %.2f m", range))
                    .font(Type.ui(10.5, weight: .medium))
                    .foregroundStyle(Ink.textFaint)
            }
        }
    }
}

/// La lune : phase, éclairement, lever et coucher, prochaines syzygies.
struct MoonCard: View {
    let illumination: Astro.MoonIllumination?
    let times: (rise: Date?, set: Date?)?
    let now: Date

    var body: some View {
        ChassisCard(title: "Lune", systemImage: "moon.stars.fill", accent: Ink.violet) {
            HStack(spacing: 16) {
                MoonDisc(phase: illumination?.phase ?? 0)
                    .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 4) {
                    Text(illumination?.name ?? "—")
                        .font(Type.ui(14, weight: .semibold))
                        .foregroundStyle(Ink.paper)
                    Text("\(Int(((illumination?.fraction ?? 0) * 100).rounded())) % éclairée · \(String(format: "%.1f", illumination?.age ?? 0)) jours")
                        .font(Type.ui(11))
                        .foregroundStyle(Ink.textFaint)

                    HStack(spacing: 12) {
                        Label(times?.rise.map { Fmt.hm.string(from: $0) } ?? "—",
                              systemImage: "moonrise.fill")
                        Label(times?.set.map { Fmt.hm.string(from: $0) } ?? "—",
                              systemImage: "moonset.fill")
                    }
                    .font(Type.tape(11))
                    .foregroundStyle(Ink.textSoft)

                    HStack(spacing: 10) {
                        if let full = Astro.nextPhase(0.5, after: now) {
                            Pill(text: "pleine \(Fmt.dayShort.string(from: full))", color: Ink.violet)
                        }
                        if let new = Astro.nextPhase(0.0, after: now) {
                            Pill(text: "nouvelle \(Fmt.dayShort.string(from: new))", color: Ink.textFaint)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

/// Disque lunaire dessiné selon la phase : le terminateur est une ellipse.
struct MoonDisc: View {
    let phase: Double

    var body: some View {
        Canvas { context, size in
            let r = min(size.width, size.height) / 2 - 1
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let disc = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                              width: r * 2, height: r * 2))
            context.fill(disc, with: .color(Ink.chassisLine))

            // Le croissant se construit en deux temps : un demi-disque éclairé
            // du bon côté, puis l'ellipse du terminateur qui le ronge ou l'élargit.
            let k = (1 - cos(phase * 2 * .pi)) / 2   // fraction éclairée
            let waxing = phase < 0.5
            let light = Ink.paper.opacity(0.92)
            let dark = Ink.chassisLine

            var half = Path()
            half.addArc(center: center, radius: r,
                        startAngle: .degrees(-90), endAngle: .degrees(90),
                        clockwise: !waxing)
            half.closeSubpath()
            context.fill(half, with: .color(light))

            let ellipseWidth = abs(2 * k - 1) * r
            let terminator = Path(ellipseIn: CGRect(x: center.x - ellipseWidth,
                                                    y: center.y - r,
                                                    width: ellipseWidth * 2,
                                                    height: r * 2))
            context.fill(terminator, with: .color(k > 0.5 ? light : dark))

            context.stroke(disc, with: .color(Ink.chassisLine), lineWidth: 1)
        }
    }
}

/// Les périodes solunaires du jour, quand la faune bouge.
struct SolunarCard: View {
    let periods: [Solunar.Period]
    let rating: Int
    let now: Date

    var body: some View {
        ChassisCard(title: "Activité — pêche & nature", systemImage: "fish.fill", accent: Ink.moss) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Image(systemName: i < rating ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundStyle(i < rating ? Ink.moss : Ink.chassisLine)
                    }
                    Text(ratingLabel)
                        .font(Type.ui(11, weight: .medium))
                        .foregroundStyle(Ink.textSoft)
                        .padding(.leading, 4)
                }

                if periods.isEmpty {
                    Text("Périodes indisponibles.")
                        .font(Type.ui(11)).foregroundStyle(Ink.textFaint)
                } else {
                    ForEach(periods) { period in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(period.isMajor ? Ink.moss : Ink.moss.opacity(0.4))
                                .frame(width: 6, height: 6)
                            Text(period.label)
                                .font(Type.ui(11.5, weight: period.contains(now) ? .bold : .regular))
                                .foregroundStyle(period.contains(now) ? Ink.paper : Ink.textSoft)
                            if period.contains(now) {
                                Text("maintenant")
                                    .font(Type.ui(9, weight: .bold))
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Capsule().fill(Ink.moss.opacity(0.25)))
                                    .foregroundStyle(Ink.moss)
                            }
                            Spacer(minLength: 4)
                            Text("\(Fmt.hm.string(from: period.start)) → \(Fmt.hm.string(from: period.end))")
                                .font(Type.tape(11))
                                .foregroundStyle(Ink.textFaint)
                        }
                    }
                }

                Text("Les périodes majeures encadrent le passage de la lune au méridien, les mineures son lever et son coucher.")
                    .font(Type.ui(10))
                    .foregroundStyle(Ink.textFaint.opacity(0.8))
            }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 4: return "journée excellente"
        case 3: return "bonne journée"
        case 2: return "journée moyenne"
        default: return "journée calme"
        }
    }
}
