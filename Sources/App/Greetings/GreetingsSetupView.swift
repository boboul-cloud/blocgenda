import SwiftUI

/// Le mode d'emploi de l'automatisation.
///
/// Raccourcis est une application où l'on montre du doigt : la décrire en
/// phrases ne marche pas. Chaque geste est donc dessiné — la barre où l'on
/// cherche, la rangée au-dessus du clavier où se prennent les variables, le
/// menu où l'on choisit la propriété, l'interrupteur et sa position. Le
/// lecteur compare son écran au dessin plutôt que de traduire une consigne.
struct GreetingsSetupView: View {

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                preamble

                Chapter(number: 1, title: "Le raccourci",
                        subtitle: "Celui qui envoie. Il est déjà monté : vous n’avez qu’à l’installer.")

                install

                Chapter(number: 2, title: "L’automatisation",
                        subtitle: "Celle qui appuie sur le bouton à votre place, chaque matin. Trois gestes, aucune variable.")

                stepAutomationTab
                stepTrigger
                stepRunShortcut
                automationRecap

                essay
                manualAssembly
                Color.clear.frame(height: 8)
            }
            .padding(20)
        }
        .background(Ink.chassis)
        .navigationTitle("Envoyer sans y penser")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Le raccourci tout prêt

    private var install: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                openURL(Greetings.shortcutLink)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(Type.icon(15, weight: .bold))
                    Text("Installer le raccourci")
                        .font(Type.ui(16, weight: .semibold))
                }
                .foregroundStyle(Ink.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Ink.amber)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("souhaits.installer")

            Text("Raccourcis s’ouvre et montre ce que le raccourci contient. Faites défiler, puis **Ajouter le raccourci**. Tout est déjà en place : les variables, l’envoi dans la boucle, l’interrupteur d’affichage éteint.")
                .font(Type.ui(13.5))
                .foregroundStyle(Ink.textSoft)
                .fixedSize(horizontal: false, vertical: true)

            Recap(title: "Ce que vous obtenez") {
                shortcutBlocks
            }

            Aside("**Faites-le sur l’iPhone.** L’annuaire de Blocgenda ne se synchronise pas d’un appareil à l’autre : sur iPad, le raccourci ne trouverait personne à fêter. Un iPad n’envoie d’ailleurs de SMS qu’aux numéros iMessage, et c’est le téléphone qui est allumé le matin. La copie du raccourci qui apparaîtra sur l’iPad est sans effet — les automatisations, elles, ne se synchronisent pas.")
        }
    }

    /// Les quatre blocs du raccourci fini, montrés à l'installation comme au
    /// bout du montage manuel : c'est la même chose, obtenue par deux chemins.
    @ViewBuilder
    private var shortcutBlocks: some View {
        SketchBlock(icon: "gift.fill", tint: Ink.amberDeep) {
            SketchLine { Piece.word("Salutations du jour") }
            SketchSwitch(label: "Ne pas renvoyer deux fois le même jour", on: true)
        }
        SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft) {
            SketchLine {
                Piece.word("Répéter avec chaque élément dans")
                Piece.pill("Salutations du jour")
            }
        }
        SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true) {
            SketchLine {
                Piece.word("Envoyer")
                Piece.pill("Message")
                Piece.word("à")
                Piece.pill("Numéro")
            }
            SketchSwitch(label: "Afficher la feuille de composition", on: false)
        }
        SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft) {
            SketchLine { Piece.word("Fin de la récurrence") }
        }
    }

    // MARK: - Le montage à la main, pour qui en a besoin

    private var manualAssembly: some View {
        DisclosureGroup("Monter le raccourci à la main") {
            VStack(alignment: .leading, spacing: 20) {
                Text("Utile si le lien ne répond plus, ou pour comprendre ce que fait le raccourci. **Sur iPhone** : le champ des destinataires y accepte les variables, pas celui de l’iPad.")
                    .font(Type.ui(13.5))
                    .foregroundStyle(Ink.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                stepOpenShortcuts
                stepName
                stepAddAction
                stepAddLoop
                stepAddMessage
                stepFillFields
                stepShowWhenRun
                shortcutRecap
            }
            .padding(.bottom, 8)
        }
        .font(Type.ui(15, weight: .semibold))
        .tint(Ink.amberDeep)
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

    // MARK: - Préambule

    private var preamble: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deux choses à monter, une fois pour toutes")
                .font(Type.ui(20, weight: .bold))
                .foregroundStyle(Ink.text)
            Text("Blocgenda prépare les messages ; c’est l’application **Raccourcis** d’iOS qui les envoie — aucune application n’a le droit d’envoyer un SMS d’elle-même. Le raccourci s’installe d’un bouton ; l’automatisation, elle, ne peut être créée que par vous, à la main : iOS l’interdit aux applications.")
                .font(Type.ui(14))
                .foregroundStyle(Ink.textSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 1. Le raccourci

    private var stepOpenShortcuts: some View {
        Step(1, "Ouvrez Raccourcis, onglet Raccourcis") {
            Where("Tout en bas de l’écran, la barre d’onglets.")
            TabBarSketch(items: ["Raccourcis", "Automatisation"], selected: "Raccourcis")
            Where("Puis le **+**, en haut à droite.")
            NavBarSketch(title: "Raccourcis", trailing: "plus")
        }
    }

    private var stepName: some View {
        Step(2, "Nommez-le « Souhaits du jour »") {
            Where("Touchez le nom provisoire, en haut de l’éditeur, et choisissez **Renommer**.")
            NavBarSketch(title: "Nouveau raccourci", trailing: "chevron.down", titleIsTarget: true)
        }
    }

    private var stepAddAction: some View {
        Step(3, "Ajoutez l’action de Blocgenda") {
            Where("La barre de recherche est **en bas**, sous le raccourci. Tapez-y :")
            SearchSketch(typed: "Salutations")
            Where("Un seul résultat, sous le nom de l’app. Touchez-le.")
            ResultSketch(action: "Salutations du jour", app: "Blocgenda", icon: "gift.fill", tint: Ink.amberDeep)
            Where("Le bloc s’installe. Laissez son interrupteur allumé.")
            SketchBlock(icon: "gift.fill", tint: Ink.amberDeep) {
                SketchLine { Piece.word("Salutations du jour") }
                SketchSwitch(label: "Ne pas renvoyer deux fois le même jour", on: true)
            }
        }
    }

    private var stepAddLoop: some View {
        Step(4, "Ajoutez la boucle") {
            Where("Même barre de recherche, en bas :")
            SearchSketch(typed: "Répéter avec chaque")
            Where("Deux blocs s’ajoutent d’un coup — l’ouverture et la fermeture. Le champ se remplit tout seul avec le résultat du bloc précédent.")
            VStack(alignment: .leading, spacing: 8) {
                SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft) {
                    SketchLine {
                        Piece.word("Répéter avec chaque élément dans")
                        Piece.pill("Salutations du jour")
                    }
                }
                SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft) {
                    SketchLine { Piece.word("Fin de la récurrence") }
                }
            }
            Aside("Si le champ est resté vide : touchez-le, et prenez **Salutations du jour** dans la rangée au-dessus du clavier.")
        }
    }

    private var stepAddMessage: some View {
        Step(5, "Ajoutez l’envoi — dans la boucle") {
            Where("Toujours la barre du bas :")
            SearchSketch(typed: "Envoyer un message")
            Where("Elle arrive **sous** la boucle, ce qui ne convient pas. Gardez le doigt appuyé dessus et glissez-la entre les deux blocs de répétition.")
            Comparison(
                wrong: AnyView(loopSketch(messageInside: false)),
                right: AnyView(loopSketch(messageInside: true)))
        }
    }

    /// La boucle, avec l'envoi dedans ou dessous : c'est la seule différence
    /// qui compte, et elle ne se voit qu'au décalage vers la droite.
    private func loopSketch(messageInside: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft, compact: true) {
                SketchLine { Piece.word("Répéter avec chaque élément") }
            }
            if messageInside {
                SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true, compact: true) {
                    SketchLine { Piece.word("Envoyer un message") }
                }
            }
            SketchBlock(icon: "arrow.triangle.2.circlepath", tint: Ink.textSoft, compact: true) {
                SketchLine { Piece.word("Fin de la récurrence") }
            }
            if !messageInside {
                SketchBlock(icon: "message.fill", tint: Ink.moss, compact: true) {
                    SketchLine { Piece.word("Envoyer un message") }
                }
            }
        }
    }

    private var stepFillFields: some View {
        Step(6, "Remplissez les deux champs") {
            Where("Les deux champs sont vides : ils s’affichent **en bleu pâle**, ce qui les fait paraître désactivés — ils ne le sont pas. Touchez la partie texte du champ **message**, jamais le ⊕ à droite, qui ouvre le carnet d’adresses.")
            SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true) {
                SketchLine {
                    Piece.word("Envoyer")
                    Piece.empty("message")
                    Piece.word("à")
                    Piece.empty("destinataires")
                }
            }
            Where("Le clavier monte, et **une rangée de pastilles apparaît juste au-dessus**. Touchez celle-ci :")
            KeyboardBarSketch(pills: ["Élément de répétition", "Salutations du jour"],
                              target: "Élément de répétition")
            Where("La pastille s’insère dans le champ. **Touchez-la de nouveau** : un menu propose les propriétés de la personne en cours.")
            MenuSketch(options: ["Prénom", "Nom", "Numéro", "Message", "Occasion"], target: "Message")
            Where("Recommencez pour les **destinataires**, en choisissant **Numéro** dans le même menu. Vous devez obtenir deux pastilles courtes :")
            SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true) {
                SketchLine {
                    Piece.word("Envoyer")
                    Piece.pill("Message")
                    Piece.word("à")
                    Piece.pill("Numéro")
                }
            }
            Aside("Une pastille restée sur « Élément de répétition » enverrait le nom du contact à la place du texte.")
            Aside("**Montez ce raccourci sur l’iPhone.** Sur iPad, le champ des destinataires ouvre une feuille « À : » qui n’accepte que de vrais contacts : la rangée de pastilles n’y paraît pas, et la variable ne peut pas y entrer. Les raccourcis se synchronisent par iCloud — méfiez-vous alors de l’inverse : rouvrir celui-ci sur l’iPad peut y vider le champ, et la synchro reporte ce vide sur le téléphone.")
        }
    }

    private var stepShowWhenRun: some View {
        Step(7, "Éteignez l’interrupteur d’affichage") {
            Where("Dans la même action, touchez le **chevron ⟩** — il est à droite des pastilles, et déplie les options.")
            SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true) {
                SketchLine {
                    Piece.word("Envoyer")
                    Piece.pill("Message")
                    Piece.word("à")
                    Piece.pill("Numéro")
                    Piece.target("chevron.right")
                }
            }
            Where("Un interrupteur apparaît, allumé d’origine. Éteignez-le. Selon la version d’iOS, il s’appelle **« Afficher lors de l’exécution »** ou **« Afficher la feuille de composition »** — c’est le même.")
            SketchBlock(icon: "message.fill", tint: Ink.moss, indented: true) {
                SketchSwitch(label: "Afficher la feuille de composition", on: false)
            }
            Aside("C’est **le** réglage qui décide de tout : allumé, Messages s’ouvre et attend votre doigt ; éteint, le message part seul.")
        }
    }

    private var shortcutRecap: some View {
        Recap(title: "Votre raccourci, en entier") { shortcutBlocks }
    }

    // MARK: - 2. L'automatisation

    private var stepAutomationTab: some View {
        Step(1, "Passez à l’onglet Automatisation") {
            Where("Toujours dans Raccourcis, l’onglet voisin, puis le **+** en haut à droite.")
            TabBarSketch(items: ["Raccourcis", "Automatisation"], selected: "Automatisation")
        }
    }

    private var stepTrigger: some View {
        Step(2, "Choisissez le déclencheur « Heure de la journée »") {
            Where("C’est la **première ligne** de la longue liste qui s’ouvre.")
            ListSketch(rows: ["Heure de la journée", "Alarme", "Sommeil", "Courriel"], target: "Heure de la journée")
            Where("Réglez l’heure, cochez **Quotidiennement**, puis **Suivant** en haut à droite.")
            SketchBlock(icon: "clock.fill", tint: Ink.sea) {
                SketchLine { Piece.word("8 h 00 · Quotidiennement") }
            }
        }
    }

    private var stepRunShortcut: some View {
        Step(3, "Faites-lui exécuter le raccourci") {
            Where("iOS propose des suggestions : passez-les et choisissez **Nouvelle automatisation vide**. La barre de recherche revient, tapez :")
            SearchSketch(typed: "Exécuter le raccourci")
            Where("Touchez le champ du bloc, désignez **Souhaits du jour**, et éteignez l’interrupteur du bas.")
            SketchBlock(icon: "play.fill", tint: Ink.amberDeep) {
                SketchLine {
                    Piece.word("Exécuter le raccourci")
                    Piece.pill("Souhaits du jour")
                }
                SketchSwitch(label: "Demander avant d’exécuter", on: false)
            }
            Aside("iOS demande confirmation pour cet interrupteur : répondez **Ne pas demander**. Puis **Terminé**.")
        }
    }

    private var automationRecap: some View {
        Recap(title: "Votre automatisation") {
            SketchBlock(icon: "clock.fill", tint: Ink.sea) {
                SketchLine { Piece.word("Heure de la journée · 8 h 00 · Quotidiennement") }
            }
            SketchBlock(icon: "play.fill", tint: Ink.amberDeep) {
                SketchLine {
                    Piece.word("Exécuter le raccourci")
                    Piece.pill("Souhaits du jour")
                }
                SketchSwitch(label: "Demander avant d’exécuter", on: false)
            }
        }
    }

    // MARK: - L'essai

    private var essay: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Essayez sur vous d’abord", systemImage: "checkmark.seal.fill")
                .font(Type.ui(16, weight: .semibold))
                .foregroundStyle(Ink.moss)

            Text("Mettez votre propre fiche dans un groupe coché, avec votre numéro et la date du jour comme anniversaire. Réglez l’automatisation deux minutes plus tard, et gardez l’iPhone allumé : une automatisation manquée ne se rattrape pas.")
                .font(Type.ui(14))
                .foregroundStyle(Ink.textSoft)
                .fixedSize(horizontal: false, vertical: true)

            Text("Une personne n’est rendue qu’une fois par jour. Pour recommencer un essai, revenez en arrière et touchez « Oublier les envois du jour ».")
                .font(Type.ui(13))
                .foregroundStyle(Ink.textFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Ink.moss.opacity(0.10))
        )
    }
}

// MARK: - Gabarits du mode d'emploi

/// Le titre d'une des deux moitiés du montage.
private struct Chapter: View {
    let number: Int
    let title: String
    let subtitle: String

    init(number: Int, title: String, subtitle: String) {
        self.number = number
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(Type.ui(15, weight: .bold))
                    .foregroundStyle(Ink.onAccent)
                    .frame(width: Type.control(28), height: Type.control(28))
                    .background(Circle().fill(Ink.amber))
                Text(title)
                    .font(Type.ui(21, weight: .bold))
                    .foregroundStyle(Ink.text)
            }
            Text(subtitle)
                .font(Type.ui(13.5))
                .foregroundStyle(Ink.textFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }
}

/// Un geste : son rang, ce qu'on obtient, et les dessins de l'endroit où l'on
/// touche. Le trait vertical relie les gestes entre eux.
private struct Step<Content: View>: View {
    let rank: Int
    let title: String
    @ViewBuilder var content: Content

    init(_ rank: Int, _ title: String, @ViewBuilder content: () -> Content) {
        self.rank = rank
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text("\(rank)")
                    .font(Type.tape(12, weight: .bold))
                    .foregroundStyle(Ink.text)
                    .frame(width: Type.control(24), height: Type.control(24))
                    .background(Circle().strokeBorder(Ink.chassisLine, lineWidth: 1.5))
                Rectangle()
                    .fill(Ink.chassisLine)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(Type.ui(16, weight: .semibold))
                    .foregroundStyle(Ink.text)
                    .fixedSize(horizontal: false, vertical: true)
                content
            }
            .padding(.bottom, 14)
        }
    }
}

/// La consigne qui accompagne un dessin : où toucher, quoi taper.
private struct Where: View {
    let text: LocalizedStringKey
    init(_ text: String) { self.text = LocalizedStringKey(text) }

    var body: some View {
        Text(text)
            .font(Type.ui(13.5))
            .foregroundStyle(Ink.textSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Une remarque de côté : le piège, ou le rattrapage quand ça ne se passe pas
/// comme prévu.
private struct Aside: View {
    let text: LocalizedStringKey
    init(_ text: String) { self.text = LocalizedStringKey(text) }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(Type.icon(12, weight: .bold))
                .foregroundStyle(Ink.rouge)
                .padding(.top, 1)
            Text(text)
                .font(Type.ui(13))
                .foregroundStyle(Ink.textSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Ink.rouge.opacity(0.08))
        )
    }
}

/// Le récapitulatif : à quoi doit ressembler l'ensemble, pour vérifier.
private struct Recap<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "checkmark.circle.fill")
                .font(Type.ui(15, weight: .semibold))
                .foregroundStyle(Ink.seaDeep)
            VStack(alignment: .leading, spacing: 8) { content }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Ink.sea.opacity(0.08))
        )
    }
}

/// Deux états côte à côte : celui qu'on obtient d'abord, celui qu'il faut.
private struct Comparison: View {
    let wrong: AnyView
    let right: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelled("Ce qu’iOS pose", symbol: "xmark.circle.fill", tint: Ink.rouge, view: wrong)
            labelled("Ce qu’il faut obtenir", symbol: "checkmark.circle.fill", tint: Ink.moss, view: right)
        }
    }

    private func labelled(_ text: String, symbol: String, tint: Color, view: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(text, systemImage: symbol)
                .font(Type.ui(12, weight: .semibold))
                .foregroundStyle(tint)
            view
        }
    }
}

// MARK: - Le vocabulaire des dessins

/// Un morceau de ligne d'action : du texte, une variable en pastille bleue, un
/// champ encore vide, ou l'élément sur lequel il faut appuyer.
enum Piece: Identifiable {
    case word(String)
    case pill(String)
    case empty(String)
    case target(String)

    var id: String {
        switch self {
        case .word(let s): return "w\(s)"
        case .pill(let s): return "p\(s)"
        case .empty(let s): return "e\(s)"
        case .target(let s): return "t\(s)"
        }
    }
}

/// Une ligne d'action, qui se replie quand la largeur manque — comme dans
/// Raccourcis.
struct SketchLine: View {
    private let pieces: [Piece]

    init(@SketchLineBuilder _ content: () -> [Piece]) { pieces = content() }

    var body: some View {
        FlowRow(spacing: 5, lineSpacing: 5) {
            ForEach(pieces) { piece in
                switch piece {
                case .word(let text):
                    Text(text)
                        .font(Type.ui(14, weight: .medium))
                        .foregroundStyle(Ink.text)
                case .pill(let text):
                    Text(text)
                        .font(Type.ui(13, weight: .semibold))
                        .foregroundStyle(Ink.seaDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Ink.sea.opacity(0.16)))
                case .empty(let name):
                    Text(name)
                        .font(Type.ui(13))
                        .foregroundStyle(Ink.textFaint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Ink.sunken))
                case .target(let symbol):
                    Image(systemName: symbol)
                        .font(Type.icon(11, weight: .bold))
                        .foregroundStyle(Ink.onAccent)
                        .frame(width: Type.control(22), height: Type.control(22))
                        .background(Circle().fill(Ink.amber))
                }
            }
        }
    }
}

@resultBuilder
enum SketchLineBuilder {
    static func buildBlock(_ pieces: Piece...) -> [Piece] { pieces }
}

/// Un interrupteur dessiné dans la position qu'il doit avoir : plus court à
/// lire qu'« allumez ceci, éteignez cela », et impossible à confondre.
struct SketchSwitch: View {
    let label: String
    let on: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Type.ui(12.5))
                .foregroundStyle(Ink.textSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 6)
            Capsule()
                .fill(on ? Ink.moss : Ink.sunken)
                .frame(width: Type.control(34), height: Type.control(20))
                .overlay(alignment: on ? .trailing : .leading) {
                    Circle()
                        .fill(Ink.paper)
                        .frame(width: Type.control(16), height: Type.control(16))
                        .padding(2)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) : \(on ? "allumé" : "éteint")")
    }
}

/// Un bloc d'action, comme Raccourcis le dessine. Celui qui est dans une
/// boucle est décalé — c'est à ce décalage qu'on reconnaît qu'il y est.
struct SketchBlock<Content: View>: View {
    let icon: String
    let tint: Color
    var indented: Bool = false
    /// Version resserrée, pour les dessins qui ne montrent que l'ordre des blocs.
    var compact: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(Type.icon(compact ? 10 : 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: Type.control(compact ? 20 : 24),
                       height: Type.control(compact ? 20 : 24))
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tint))

            VStack(alignment: .leading, spacing: 8) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(compact ? 9 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1)
                )
        )
        .padding(.leading, indented ? 24 : 0)
    }
}

/// La barre d'onglets de Raccourcis, l'onglet visé en évidence.
struct TabBarSketch: View {
    let items: [String]
    let selected: String

    private func icon(_ name: String) -> String {
        name == "Automatisation" ? "clock.arrow.circlepath" : "square.grid.2x2.fill"
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { name in
                let active = name == selected
                VStack(spacing: 3) {
                    Image(systemName: icon(name))
                        .font(Type.icon(14, weight: .semibold))
                    Text(name)
                        .font(Type.ui(11, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(active ? Ink.amberDeep : Ink.textFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(active ? Ink.amber.opacity(0.18) : .clear)
                )
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Ink.chassisSoft)
                .overlay(Capsule().strokeBorder(Ink.chassisLine, lineWidth: 1))
        )
    }
}

/// La barre du haut : un titre, et le bouton visé à droite.
struct NavBarSketch: View {
    let title: String
    let trailing: String
    /// Vrai quand c'est le titre lui-même qu'il faut toucher.
    var titleIsTarget: Bool = false

    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(Type.icon(12, weight: .semibold))
                .foregroundStyle(Ink.textFaint)
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                Text(title)
                    .font(Type.ui(14, weight: .semibold))
                    .foregroundStyle(titleIsTarget ? Ink.onAccent : Ink.text)
                    .lineLimit(1)
                if titleIsTarget {
                    Image(systemName: "chevron.down")
                        .font(Type.icon(9, weight: .bold))
                        .foregroundStyle(Ink.onAccent)
                }
            }
            .padding(.horizontal, titleIsTarget ? 10 : 0)
            .padding(.vertical, titleIsTarget ? 4 : 0)
            .background(
                Capsule().fill(titleIsTarget ? Ink.amber : .clear)
            )
            Spacer(minLength: 8)
            Image(systemName: trailing)
                .font(Type.icon(13, weight: .bold))
                .foregroundStyle(titleIsTarget ? Ink.textFaint : Ink.onAccent)
                .frame(width: Type.control(26), height: Type.control(26))
                .background(Circle().fill(titleIsTarget ? .clear : Ink.amber))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1)
                )
        )
    }
}

/// La barre « Rechercher des actions », avec ce qu'il faut y taper.
struct SearchSketch: View {
    let typed: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(Type.icon(12, weight: .semibold))
                .foregroundStyle(Ink.textFaint)
            Text(typed)
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.text)
            Rectangle()
                .fill(Ink.amberDeep)
                .frame(width: 1.5, height: Type.resolve(15))
            Spacer(minLength: 0)
            Image(systemName: "mic.fill")
                .font(Type.icon(11))
                .foregroundStyle(Ink.textFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Ink.sunken)
                .overlay(Capsule().strokeBorder(Ink.chassisLine, lineWidth: 1))
        )
    }
}

/// Un résultat de recherche : l'action, et l'app qui la fournit.
struct ResultSketch: View {
    let action: String
    let app: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(Type.icon(12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: Type.control(24), height: Type.control(24))
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tint))
            VStack(alignment: .leading, spacing: 1) {
                Text(action)
                    .font(Type.ui(14, weight: .medium))
                    .foregroundStyle(Ink.text)
                Text(app)
                    .font(Type.ui(11))
                    .foregroundStyle(Ink.textFaint)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Ink.amber, lineWidth: 1.5)
                )
        )
    }
}

/// La rangée de variables au-dessus du clavier, celle qu'il faut prendre en
/// évidence — c'est là que tout le monde bute.
struct KeyboardBarSketch: View {
    let pills: [String]
    let target: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(pills, id: \.self) { name in
                    let aimed = name == target
                    Text(name)
                        .font(Type.ui(12, weight: .semibold))
                        .foregroundStyle(aimed ? Ink.onAccent : Ink.textSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(aimed ? Ink.amber : Ink.sunken))
                }
                Spacer(minLength: 0)
            }
            .padding(8)

            // Le haut du clavier, esquissé : trois rangées de touches muettes,
            // pour situer la rangée de pastilles au-dessus.
            VStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: 4) {
                        ForEach(0..<9, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Ink.chassisSoft)
                                .frame(height: Type.resolve(14))
                        }
                    }
                }
            }
            .padding(8)
            .background(Ink.sunken)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Ink.chassis)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Ink.chassisLine, lineWidth: 1)
        )
    }
}

/// Un menu déroulant, l'entrée à choisir en évidence.
struct MenuSketch: View {
    let options: [String]
    let target: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, name in
                let aimed = name == target
                HStack {
                    Text(name)
                        .font(Type.ui(13.5, weight: aimed ? .semibold : .regular))
                        .foregroundStyle(aimed ? Ink.onAccent : Ink.text)
                    Spacer(minLength: 0)
                    if aimed {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(Type.icon(11, weight: .bold))
                            .foregroundStyle(Ink.onAccent)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(aimed ? Ink.amber : .clear)

                if index < options.count - 1 {
                    Rectangle().fill(Ink.chassisLine).frame(height: 0.5)
                }
            }
        }
        .background(Ink.chassisSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Ink.chassisLine, lineWidth: 1)
        )
    }
}

/// Une liste système, la ligne visée en évidence.
struct ListSketch: View {
    let rows: [String]
    let target: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, name in
                let aimed = name == target
                HStack(spacing: 10) {
                    Text(name)
                        .font(Type.ui(13.5, weight: aimed ? .semibold : .regular))
                        .foregroundStyle(aimed ? Ink.onAccent : Ink.textSoft)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(Type.icon(10, weight: .semibold))
                        .foregroundStyle(aimed ? Ink.onAccent : Ink.textFaint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(aimed ? Ink.amber : .clear)

                if index < rows.count - 1 {
                    Rectangle().fill(Ink.chassisLine).frame(height: 0.5)
                }
            }
        }
        .background(Ink.chassisSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Ink.chassisLine, lineWidth: 1)
        )
    }
}
