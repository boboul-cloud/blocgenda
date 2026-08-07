import SwiftUI

/// Charte graphique : une machine à écrire moderne. Un châssis sombre et mat,
/// une bande de papier chaude qui court dedans, deux accents — l'ambre de
/// l'encre et le bleu de la mer.
enum Ink {
    // Châssis
    static let chassis = Color(hex: 0x14161A)
    static let chassisSoft = Color(hex: 0x1C1F26)
    static let chassisLine = Color(hex: 0x2A2F38)

    // Papier
    static let paper = Color(hex: 0xFAF6EC)
    static let paperShade = Color(hex: 0xF0EADC)
    static let paperEdge = Color(hex: 0xE2D9C6)

    // Encre
    static let text = Color(hex: 0x1B1D22)
    static let textSoft = Color(hex: 0x6B6A63)
    static let textFaint = Color(hex: 0xA3A096)

    // Accents
    static let amber = Color(hex: 0xE0913A)
    static let amberDeep = Color(hex: 0xC2742A)
    static let sea = Color(hex: 0x1E7F8C)
    static let seaDeep = Color(hex: 0x115A66)
    static let moss = Color(hex: 0x5B8A4E)
    static let rouge = Color(hex: 0xC1453B)
    static let violet = Color(hex: 0x6E5AA8)

    /// Couleurs d'étiquette pour les événements et les fiches.
    static let palette: [Color] = [amber, sea, moss, rouge, violet, Color(hex: 0x3B6EA5)]

    static func label(_ index: Int) -> Color {
        palette[((index % palette.count) + palette.count) % palette.count]
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

/// Typographie : le rouleau est imprimé en chasse fixe, l'interface en rond.
enum Type {
    static func tape(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let display = ui(30, weight: .bold)
    static let title = ui(19, weight: .semibold)
    static let body = ui(15)
    static let caption = ui(12, weight: .medium)
    static let micro = ui(10, weight: .semibold)
}

// MARK: - Papier

/// Bord déchiré, dents irrégulières mais stables (déterminées par une graine).
struct TornEdge: Shape {
    var seed: Int = 7
    var toothWidth: CGFloat = 12
    var depth: CGFloat = 7
    /// Vrai si la déchirure est en bas du rectangle.
    var atBottom: Bool = true

    func path(in rect: CGRect) -> Path {
        var p = Path()
        var generator = SplitMix(seed: UInt64(seed))
        let count = max(4, Int(rect.width / toothWidth))
        let step = rect.width / CGFloat(count)

        if atBottom {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - depth))
            for i in stride(from: count, through: 0, by: -1) {
                let x = rect.minX + CGFloat(i) * step
                let jitter = CGFloat(generator.nextUnit()) * depth
                p.addLine(to: CGPoint(x: x, y: rect.maxY - depth + jitter))
            }
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + depth))
            for i in 0...count {
                let x = rect.minX + CGFloat(i) * step
                let jitter = CGFloat(generator.nextUnit()) * depth
                p.addLine(to: CGPoint(x: x, y: rect.minY + depth - jitter))
            }
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}

/// Générateur pseudo-aléatoire déterministe : la déchirure ne bouge pas d'un
/// rendu à l'autre.
struct SplitMix {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func nextUnit() -> Double { Double(next() % 1000) / 1000 }
}

/// Les perforations latérales de la bande d'imprimante.
struct SprocketHoles: View {
    var spacing: CGFloat = 22
    var body: some View {
        GeometryReader { geo in
            let count = max(1, Int(geo.size.height / spacing))
            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    Circle()
                        .fill(Ink.chassis.opacity(0.16))
                        .frame(width: 5, height: 5)
                        .frame(height: spacing)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Le fond de papier : dégradé chaud, grain léger, ombre portée.
struct PaperBackground: View {
    var cornerRadius: CGFloat = 0
    var body: some View {
        LinearGradient(colors: [Ink.paper, Ink.paperShade],
                       startPoint: .top, endPoint: .bottom)
        .overlay(PaperGrain().opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Grain de papier : quelques milliers de points, dessinés une fois par Canvas.
struct PaperGrain: View {
    var body: some View {
        Canvas { context, size in
            var generator = SplitMix(seed: 42)
            let count = Int(size.width * size.height / 900)
            for _ in 0..<min(count, 2600) {
                let x = CGFloat(generator.nextUnit()) * size.width
                let y = CGFloat(generator.nextUnit()) * size.height
                let s = CGFloat(generator.nextUnit()) * 1.4 + 0.3
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                             with: .color(Ink.text.opacity(0.5)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Composants réutilisables

/// Carte du châssis : le bloc sombre sur lequel repose l'interface.
struct ChassisCard<Content: View>: View {
    var title: String?
    var systemImage: String?
    var accent: Color = Ink.amber
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 7) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accent)
                    }
                    Text(title.uppercased())
                        .font(Type.micro)
                        .tracking(1.4)
                        .foregroundStyle(Ink.textFaint)
                    Spacer(minLength: 0)
                }
            }
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1)
                )
        )
    }
}

/// Petite étiquette arrondie.
struct Pill: View {
    var text: String
    var color: Color = Ink.amber
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(Type.ui(11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(filled ? Color.black.opacity(0.85) : color)
            .background(
                Capsule().fill(color.opacity(filled ? 1 : 0.15))
            )
    }
}

/// Séparateur en pointillés, comme les traits d'une bande de caisse.
struct DottedRule: View {
    var color: Color = Ink.textFaint
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.5))
            .frame(height: 1)
            .mask(
                HStack(spacing: 3) {
                    ForEach(0..<200, id: \.self) { _ in
                        Rectangle().frame(width: 3)
                    }
                }
            )
    }
}

// MARK: - Formatage courant

enum Fmt {
    static let hm: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH'h'mm"
        return f
    }()

    static let hmShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm"
        return f
    }()

    static let dayFull: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM"
        return f
    }()

    static let weekdayLetter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEEE"
        return f
    }()

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds)) / 60
        let h = total / 60, m = total % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(String(format: "%02d", m))"
    }

    /// « dans 2 h 15 » / « il y a 40 min »
    static func relative(_ date: Date, from now: Date = Date()) -> String {
        let delta = date.timeIntervalSince(now)
        let magnitude = duration(abs(delta))
        return delta >= 0 ? "dans \(magnitude)" : "il y a \(magnitude)"
    }

    static func dayTitle(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Aujourd’hui" }
        if cal.isDateInTomorrow(date) { return "Demain" }
        if cal.isDateInYesterday(date) { return "Hier" }
        return dayFull.string(from: date).capitalizedFirst
    }
}
