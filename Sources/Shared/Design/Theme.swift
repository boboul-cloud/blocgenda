import SwiftUI
import UIKit

/// Charte graphique : une machine à écrire en ivoire. Un châssis clair et mat,
/// une bande de papier plus blanche qui court dedans, deux accents — l'ambre de
/// l'encre et le bleu de la mer.
///
/// Tout se lit en encre sombre sur fond clair : c'est un carnet posé sur une
/// table, pas un tableau de bord. Le contraste des textes tient les 4,5:1
/// demandés par l'accessibilité, y compris pour les accents.
enum Ink {
    // Châssis — du plus profond au plus clair
    /// Le fond de l'écran : l'ivoire du capot de la machine.
    static let chassis = Color(hex: 0xE9E2D3)
    /// Les cartes et les barres, posées en relief sur le châssis.
    static let chassisSoft = Color(hex: 0xFCF8EF)
    /// Filets, bordures, séparateurs.
    static let chassisLine = Color(hex: 0xD3C9B4)
    /// Les creux : afficheur du total, touches, pastilles enfoncées.
    /// Remplace les noirs translucides d'avant, qui trouaient le fond clair.
    static let sunken = Color(hex: 0xDED5C2)

    // Papier de la bande
    static let paper = Color(hex: 0xFFFDF8)
    static let paperShade = Color(hex: 0xFAF4E7)
    static let paperEdge = Color(hex: 0xE2D9C6)

    // Encre
    static let text = Color(hex: 0x201F1B)
    static let textSoft = Color(hex: 0x55514A)
    static let textFaint = Color(hex: 0x6B6558)

    // Accents. Les tons pleins servent aux aplats, les tons profonds aux textes.
    static let amber = Color(hex: 0xD98324)
    static let amberDeep = Color(hex: 0x945610)
    static let sea = Color(hex: 0x0F6E7B)
    static let seaDeep = Color(hex: 0x0A4F59)
    static let moss = Color(hex: 0x4C7A40)
    static let rouge = Color(hex: 0xB33A30)
    static let violet = Color(hex: 0x5E4B96)

    /// L'encre posée sur un aplat d'accent (bouton ambre, pastille pleine).
    static let onAccent = Color(hex: 0x241703)

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

#if WIDGET
    /// Le widget vit dans un gabarit imposé : sa typographie ne bouge pas,
    /// sous peine de déborder du cadre que lui donne le système.
    static let scale: CGFloat = 1

    static func resolve(_ base: CGFloat) -> CGFloat { base }
#else
    /// Grossissement de base. Le rouleau se lit souvent d'une main, de loin,
    /// parfois en plein soleil : la lisibilité prime sur la densité.
    static let scale: CGFloat = 1.24

    /// Les corps donnés par la charte passent d'abord par un plancher : sous
    /// 15 pt, on remonte d'autant plus qu'on descend. Les mentions à 9 ou 10 pt
    /// — libellés de colonnes, unités, dates — étaient les seules vraiment
    /// illisibles, et un grossissement uniforme les aurait laissées derrière.
    static func floored(_ base: CGFloat) -> CGFloat { max(base, 5.5 + base * 0.6) }

    /// Suit en plus le réglage « Taille du texte » d'iOS, mais de façon bornée :
    /// au-delà, les colonnes chiffrées de la bande ne s'aligneraient plus.
    static func resolve(_ base: CGFloat) -> CGFloat {
        let enlarged = floored(base) * scale
        return min(UIFontMetrics.default.scaledValue(for: enlarged), enlarged * 1.3)
    }
#endif

    static func tape(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: resolve(size), weight: weight, design: .monospaced)
    }
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: resolve(size), weight: weight, design: .rounded)
    }
    /// Un pictogramme suit le texte qu'il accompagne : sans cela, les symboles
    /// paraissaient rétrécir à mesure que la typographie grossissait.
    static func icon(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: resolve(size), weight: weight)
    }

    /// Largeur d'une gouttière ou d'une colonne fixe, grossie comme le texte
    /// qu'elle doit contenir.
    static func gutter(_ base: CGFloat) -> CGFloat { resolve(base) }

    /// Une pastille, un bouton rond, une case : sa taille suit la typographie
    /// pour rester au moins aussi grande que la cible tactile de 44 pt.
    static func control(_ base: CGFloat) -> CGFloat { resolve(base) }

    /// Hauteur à réserver en bas d'un écran pour la barre d'onglets flottante.
    /// Elle grossit avec le texte qu'elle contient : une valeur figée laisserait
    /// la barre recouvrir la dernière ligne.
    static var tabBarInset: CGFloat { resolve(64) }

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
                        .fill(Ink.text.opacity(0.13))
                        .frame(width: 5, height: 5)
                        .frame(height: spacing)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Le fond de papier : dégradé chaud, grain léger, et deux bords ombrés.
///
/// Sur un châssis clair, la bande et le capot ont presque la même valeur :
/// sans ces bords, le papier ne se détacherait plus du reste de l'écran.
struct PaperBackground: View {
    var cornerRadius: CGFloat = 0
    var body: some View {
        LinearGradient(colors: [Ink.paper, Ink.paperShade],
                       startPoint: .top, endPoint: .bottom)
        .overlay(PaperGrain().opacity(0.05))
        .overlay(
            LinearGradient(stops: [.init(color: Ink.paperEdge.opacity(0.55), location: 0),
                                   .init(color: .clear, location: 0.045),
                                   .init(color: .clear, location: 0.955),
                                   .init(color: Ink.paperEdge.opacity(0.55), location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        )
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

/// Carte du châssis : le bloc clair, légèrement soulevé, sur lequel repose
/// l'interface. Le titre porte la couleur de la carte, en toutes lettres.
struct ChassisCard<Content: View>: View {
    var title: String?
    var systemImage: String?
    var accent: Color = Ink.amber
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(Type.icon(12, weight: .bold))
                            .foregroundStyle(accent)
                    }
                    Text(title.uppercased())
                        .font(Type.micro)
                        .tracking(1.2)
                        .foregroundStyle(accent)
                    Spacer(minLength: 0)
                }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1)
                )
                .shadow(color: Ink.text.opacity(0.06), radius: 10, y: 4)
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
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundStyle(filled ? Ink.onAccent : color)
            .background(
                Capsule().fill(color.opacity(filled ? 1 : 0.16))
            )
    }
}

/// Une rangée qui passe à la ligne quand la largeur manque.
///
/// Une pile horizontale ordinaire partage la place entre ses éléments et les
/// comprime jusqu'à découper les mots en colonnes d'une lettre — c'est ce qui
/// arrivait à la ligne d'informations d'un rendez-vous dès qu'elle portait un
/// thème, un lieu, une répétition et un rappel, ou une seule adresse un peu
/// longue. Ici chacun garde sa taille naturelle et se reporte à la ligne
/// suivante ; celui qui, à lui seul, dépasse la largeur est ramené à la
/// colonne — c'est à lui de savoir se tronquer.
struct FlowRow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let lines = lines(subviews, width: width)
        guard !lines.isEmpty else { return .zero }
        return CGSize(width: min(width, lines.map(\.width).max() ?? 0),
                      height: lines.map(\.height).reduce(0, +)
                              + lineSpacing * CGFloat(lines.count - 1))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(subviews, width: bounds.width) {
            var x = bounds.minX
            for i in line.items {
                let size = fitted(subviews[i], within: bounds.width)
                subviews[i].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                                  proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct FlowLine {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func fitted(_ subview: LayoutSubview, within width: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard ideal.width > width else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    private func lines(_ subviews: Subviews, width: CGFloat) -> [FlowLine] {
        var result: [FlowLine] = []
        var current = FlowLine()
        for i in subviews.indices {
            let size = fitted(subviews[i], within: width)
            if !current.items.isEmpty && current.width + spacing + size.width > width {
                result.append(current)
                current = FlowLine()
            }
            current.width += (current.items.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.items.append(i)
        }
        if !current.items.isEmpty { result.append(current) }
        return result
    }
}

// MARK: - Feuilles

extension View {
    /// Les écrans présentés en feuille (réglages, éditeurs) reprennent le fond
    /// du châssis au lieu du gris d'iOS : le clair de l'application ne doit pas
    /// changer de teinte quand on ouvre une fiche.
    func paperSheet() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Ink.chassis)
            .tint(Ink.amberDeep)
            .preferredColorScheme(.light)
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

    /// « dans 2 h 15 » / « il y a 40 min » / « maintenant »
    static func relative(_ date: Date, from now: Date = Date()) -> String {
        let delta = date.timeIntervalSince(now)
        guard abs(delta) >= 60 else { return "maintenant" }
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
