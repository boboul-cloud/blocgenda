import SwiftUI

/// La couleur de chaque humeur. Elle vit ici, du côté de l'écran : le moteur
/// de mise en page, lui, ne connaît que la structure de la page.
extension JournalMood {
    var accent: Color {
        switch self {
        case .posee: return Ink.sea
        case .vive: return Ink.amberDeep
        case .songeuse: return Ink.violet
        }
    }
}

/// Le rendu d'un bloc composé par le moteur. Le moteur décide *quoi* montrer
/// et dans quel ordre ; c'est ici qu'on décide de l'allure.
struct JournalBlockView: View {
    let block: JournalLayout.Block
    let mood: JournalMood

    var body: some View {
        switch block {
        case .heading(let title):
            heading(title)

        case .paragraph(_, let text, let spoken):
            paragraph(text, spoken: spoken)

        case .line(let note):
            line(note)

        case .pull(let note):
            pull(note)

        case .rule:
            Color.clear.frame(height: Ruling.rule)
        }
    }

    // MARK: - Les allures

    /// Le titre de moment tient dans deux réglures, centré entre elles : son
    /// propre filet remplace celui du papier au lieu de le croiser.
    private func heading(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(Type.ui(10.5, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(mood.accent)
            Rectangle()
                .fill(mood.accent.opacity(0.35))
                .frame(height: 1)
        }
        .frame(height: Ruling.rule * 2)
    }

    private func paragraph(_ text: String, spoken: Bool) -> some View {
        (Text(text) + micro(spoken))
            .font(Ruling.serif(Ruling.base, italic: mood == .songeuse))
            .foregroundStyle(Ink.text)
            .lineSpacing(Ruling.spacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .snappedToRules()
    }

    private func line(_ note: JournalNote) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(Fmt.hm.string(from: note.date))
                .font(Type.tape(10.5, weight: .medium))
                .foregroundStyle(mood.accent.opacity(0.85))
                .frame(width: Ruling.hourColumn, alignment: .trailing)

            (Text(note.trimmed) + micro(note.spoken))
                .font(Ruling.serif(Ruling.base))
                .foregroundStyle(Ink.text)
                .lineSpacing(Ruling.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .snappedToRules()
    }

    /// La phrase du jour, tirée hors du texte. Elle occupe ses lignes entières :
    /// la réglure reprend dessous comme si de rien n'était.
    private func pull(_ note: JournalNote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(mood.accent.opacity(0.5))
                .frame(width: 3)
            Text("« \(note.trimmed) »")
                .font(Ruling.serif(Ruling.base * 1.35, weight: .medium, italic: true))
                .foregroundStyle(mood == .songeuse ? Ink.violet : Ink.text)
                .lineSpacing(Ruling.spacing(forSize: Ruling.base * 1.35))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Ruling.lift(forSize: Ruling.base * 1.35))
        }
        .padding(.vertical, Ruling.rule * 0.35)
        .snappedToRules()
    }

    /// Le petit micro qui rappelle qu'une phrase a été dictée.
    private func micro(_ spoken: Bool) -> Text {
        guard spoken else { return Text("") }
        return Text("  ") + Text(Image(systemName: "mic.fill"))
            .font(Type.icon(8))
            .foregroundColor(Ink.textFaint)
    }
}

// MARK: - Le cartouche

/// L'en-tête de la feuille : la date, le titre s'il y en a un, et le temps
/// qu'il faisait. C'est ce qu'on écrivait en haut à droite du cahier.
struct JournalHeading: View {
    let page: JournalPage
    var onRename: () -> Void

    /// Le corps de la date, en tête de page.
    private static var titleSize: CGFloat { Ruling.base * 1.3 }

    private var stamp: DayStamp? { page.stamp }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: onRename) {
                VStack(alignment: .leading, spacing: 0) {
                    if !page.title.isEmpty {
                        Text(page.title)
                            .font(Ruling.serif(Self.titleSize, weight: .semibold))
                            .foregroundStyle(Ink.text)
                            .lineSpacing(Ruling.spacing(forSize: Self.titleSize))
                    }
                    Text(Fmt.dayFull.string(from: page.day).capitalizedFirst)
                        .font(page.title.isEmpty
                              ? Ruling.serif(Self.titleSize, weight: .semibold)
                              : Type.ui(11.5, weight: .medium))
                        .foregroundStyle(page.title.isEmpty ? Ink.text : Ink.textSoft)
                }
                .padding(.top, Ruling.lift(forSize: Self.titleSize))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Titre de la page")
            .accessibilityHint("Donner un titre à la journée")

            if let stamp {
                WeatherLine(stamp: stamp)
                    .padding(.top, 4)
            }
        }
        .padding(.bottom, Ruling.rule * 0.4)
        .snappedToRules()
    }
}

/// La ligne du temps qu'il fait : ce que la page retient de la journée dehors.
struct WeatherLine: View {
    let stamp: DayStamp

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if stamp.hasWeather {
                HStack(spacing: 6) {
                    if let symbol = stamp.weatherSymbol {
                        Image(systemName: symbol)
                            .font(Type.icon(11))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text(weather)
                        .font(Type.ui(11.5, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Ink.amberDeep)
            }

            HStack(spacing: 8) {
                if let sunrise = stamp.sunrise, let sunset = stamp.sunset {
                    Text("\(Fmt.hmShort.string(from: sunrise)) – \(Fmt.hmShort.string(from: sunset))")
                        .foregroundStyle(Ink.textSoft)
                }
                if let place = stamp.placeName {
                    Text(place)
                        .foregroundStyle(Ink.textFaint)
                }
                Spacer(minLength: 0)
            }
            .font(Type.ui(11))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }

    private var weather: String {
        var parts: [String] = []
        if let t = stamp.temperatureText { parts.append(t) }
        if let label = stamp.weatherLabel { parts.append(label.lowercased()) }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}

// MARK: - Le tampon du bas de page

/// Le pied de page : ce que la journée avait de drôle ou de notable, et qu'on
/// aura oublié dans un an. Saint du jour, dicton, marée, anniversaires.
struct JournalStampView: View {
    let stamp: DayStamp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DottedRule(color: Ink.paperEdge)

            HStack(spacing: 6) {
                Image(systemName: "seal")
                    .font(Type.icon(10, weight: .bold))
                Text("Ce jour-là")
                    .font(Type.micro)
                    .tracking(1.2)
                Spacer(minLength: 0)
                Text("relevé à \(Fmt.hmShort.string(from: stamp.capturedAt))")
                    .font(Type.ui(9.5))
                    .foregroundStyle(Ink.textFaint)
            }
            .foregroundStyle(Ink.amberDeep)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(facts, id: \.text) { fact in
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Image(systemName: fact.icon)
                            .font(Type.icon(10))
                            .foregroundStyle(Ink.textFaint)
                            .frame(width: Type.gutter(14))
                        Text(fact.text)
                            .font(Type.ui(11.5))
                            .foregroundStyle(Ink.textSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.top, Ruling.rule * 0.5)
        .snappedToRules()
    }

    private struct Fact {
        var icon: String
        var text: String
    }

    private var facts: [Fact] {
        var list: [Fact] = []

        if let holiday = stamp.holidayName {
            list.append(Fact(icon: "flag.fill", text: holiday))
        }
        if let saint = stamp.saint {
            list.append(Fact(icon: "person.fill", text: "Fête : \(saint)"))
        }
        if let moon = stamp.moonName {
            list.append(Fact(icon: stamp.moonSymbol ?? "moon.fill", text: moon))
        }
        if let daylight = stamp.daylight {
            list.append(Fact(icon: "sun.max", text: "\(Fmt.duration(daylight)) de jour"))
        }
        if let wind = stamp.windCardinal, let force = stamp.beaufort, force > 0 {
            list.append(Fact(icon: "wind", text: "Vent de \(wind), force \(force)"))
        }
        if let tide = stamp.nextHighTide {
            let port = stamp.tidePort.map { " à \($0)" } ?? ""
            list.append(Fact(icon: "water.waves", text: "Pleine mer \(Fmt.hm.string(from: tide))\(port)"))
        }
        if let fetes = stamp.birthdays, !fetes.isEmpty {
            list.append(Fact(icon: "gift.fill", text: "Anniversaire : \(fetes.joined(separator: ", "))"))
        }
        if let day = stamp.dayOfYear, let left = stamp.daysRemaining, let week = stamp.weekNumber {
            list.append(Fact(icon: "number", text: "\(day)ᵉ jour de l'année · semaine \(week) · encore \(left) jours"))
        }
        if let dicton = stamp.dicton {
            list.append(Fact(icon: "quote.opening", text: dicton))
        }
        if let event = stamp.historicalEvent {
            list.append(Fact(icon: "clock.arrow.circlepath", text: event))
        }
        return list
    }
}
