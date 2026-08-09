import SwiftUI
import UIKit

/// La réglure : l'écart entre deux lignes de la feuille, et tout ce qu'il faut
/// pour que l'écriture tombe dessus au lieu de flotter entre.
///
/// Le principe tient en une phrase : une ligne de texte occupe exactement une
/// réglure. On mesure donc la police une fois, on en déduit l'interligne à
/// demander à SwiftUI, et on trace les traits sous les lignes de base.
enum Ruling {
    /// Corps de l'écriture courante, avant le grossissement de la charte.
    static let base: CGFloat = 15.5

    /// Le journal s'écrit en romain à empattements : ni la ronde de
    /// l'interface, ni la chasse fixe du rouleau. C'est un carnet.
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let font = Font.system(size: Type.resolve(size), weight: weight, design: .serif)
        return italic ? font.italic() : font
    }

    private static func measured(_ size: CGFloat) -> UIFont {
        let plain = UIFont.systemFont(ofSize: size)
        guard let descriptor = plain.fontDescriptor.withDesign(.serif) else { return plain }
        return UIFont(descriptor: descriptor, size: size)
    }

    static var size: CGFloat { Type.resolve(base) }
    static var lineHeight: CGFloat { measured(size).lineHeight }
    static var ascent: CGFloat { measured(size).ascender }

    /// L'écart d'une ligne à l'autre. Un peu plus aéré que la police ne
    /// l'exige : c'est une page qu'on relit, pas un formulaire.
    static var rule: CGFloat { (lineHeight * 1.45).rounded() }

    /// L'interligne à demander à SwiftUI pour qu'une ligne fasse une réglure.
    static var spacing: CGFloat { max(0, rule - lineHeight) }

    /// Le blanc laissé en haut de la feuille avant la première réglure.
    static var top: CGFloat { rule }

    /// La marge de gauche, celle du trait rouge et des perforations.
    static var margin: CGFloat { Type.gutter(38) }

    /// La colonne des heures, dans les mises en page qui les affichent.
    static var hourColumn: CGFloat { Type.gutter(42) }

    /// L'interligne à demander pour un texte d'un autre corps : là aussi, une
    /// ligne occupe un nombre entier de réglures.
    static func spacing(forSize base: CGFloat) -> CGFloat {
        let height = measured(Type.resolve(base)).lineHeight
        let slots = max(1, (height / rule).rounded(.up))
        return max(0, slots * rule - height)
    }

    /// Ce qu'il faut ajouter au-dessus d'un texte écrit dans un autre corps —
    /// un titre, une citation en gros — pour que sa ligne de base retombe elle
    /// aussi sur une réglure. Un corps plus gros descend plus bas : on le
    /// remonte, ou on le pousse, selon la réglure la plus proche.
    static func lift(forSize base: CGFloat) -> CGFloat {
        let delta = ascent - measured(Type.resolve(base)).ascender
        var wrapped = delta.truncatingRemainder(dividingBy: rule)
        if wrapped > rule / 2 { wrapped -= rule }
        if wrapped < -rule / 2 { wrapped += rule }
        return wrapped
    }
}

// MARK: - Alignement sur la réglure

private struct RuleSnap: ViewModifier {
    @State private var slack: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                guard height > 0 else { return }
                let rule = Ruling.rule
                let filled = (height / rule).rounded(.up) * rule
                slack = max(0, filled - height)
            }
            .padding(.bottom, slack)
    }
}

extension View {
    /// Complète le bloc jusqu'à la réglure suivante. Un titre, une citation en
    /// gros, un cartouche : chacun occupe un nombre entier de lignes, et le
    /// texte qui suit retombe sur les traits.
    func snappedToRules() -> some View { modifier(RuleSnap()) }
}

// MARK: - La feuille

/// Une feuille de classeur : papier chaud, réglure bleue, marge rouge et
/// perforations sur le bord gauche.
struct RuledSheet<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Ruling.margin + 12)
        .padding(.trailing, 16)
        .padding(.top, Ruling.top)
        .padding(.bottom, Ruling.rule * 2)
        .background(RuledPaper())
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Ink.paperEdge, lineWidth: 1)
        )
        .shadow(color: Ink.text.opacity(0.10), radius: 10, y: 5)
    }
}

/// Le fond de la feuille. Tout est tracé d'un coup : les traits horizontaux
/// sous les lignes de base, le trait de marge, et les trous du classeur.
struct RuledPaper: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Ink.paper, Ink.paperShade],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            PaperGrain().opacity(0.04)

            Canvas { context, size in
                let rule = Ruling.rule
                let margin = Ruling.margin

                // Les réglures, posées juste sous la ligne de base du texte.
                var y = Ruling.top + Ruling.ascent + 0.5
                while y < size.height {
                    var line = Path()
                    line.move(to: CGPoint(x: 6, y: y))
                    line.addLine(to: CGPoint(x: size.width - 6, y: y))
                    context.stroke(line, with: .color(Ink.sea.opacity(0.22)), lineWidth: 0.7)
                    y += rule
                }

                // Le trait de marge.
                var edge = Path()
                edge.move(to: CGPoint(x: margin, y: 0))
                edge.addLine(to: CGPoint(x: margin, y: size.height))
                context.stroke(edge, with: .color(Ink.rouge.opacity(0.35)), lineWidth: 1)

                // Les perforations, reprises tout au long de la feuille : la
                // page est plus longue qu'un feuillet, mais c'est bien du
                // classeur qu'on tourne.
                let step = rule * 5
                let radius: CGFloat = 7
                var hole = step * 0.55
                while hole < size.height - radius {
                    let box = CGRect(x: margin / 2 - radius, y: hole - radius,
                                     width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: box), with: .color(Ink.chassis))
                    context.stroke(Path(ellipseIn: box),
                                   with: .color(Ink.paperEdge), lineWidth: 0.8)
                    hole += step
                }
            }
            .allowsHitTesting(false)
        }
    }
}
