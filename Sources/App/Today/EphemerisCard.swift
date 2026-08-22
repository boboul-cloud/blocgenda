import SwiftUI

/// L'éphéméride : le saint du jour, le dicton, la place du jour dans l'année
/// et ce qui s'est passé un tel jour.
struct EphemerisCard: View {
    let ephemeris: Ephemeris

    /// Les prénoms du jour que le titre ne dit pas : les variantes, et ceux
    /// qu'un jour férié efface de l'éphéméride — le 14 juillet, c'est Camille.
    private var alsoCelebrated: [String] {
        let shown = NameDays.fold(ephemeris.saint)
        return NameDays.names(on: ephemeris.date).filter { NameDays.fold($0) != shown }
    }

    private var yearProgress: Double {
        let total = Double(ephemeris.dayOfYear + ephemeris.daysRemaining)
        return total > 0 ? Double(ephemeris.dayOfYear) / total : 0
    }

    var body: some View {
        ChassisCard(title: "Éphéméride", systemImage: "book.closed.fill", accent: Ink.amberDeep) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ephemeris.saint)
                            .font(Type.ui(18, weight: .bold))
                            .foregroundStyle(Ink.text)
                        if let holiday = ephemeris.holidayName {
                            Pill(text: holiday, color: Ink.rouge, filled: true)
                        }
                        Spacer(minLength: 0)
                    }
                    if !alsoCelebrated.isEmpty {
                        Text("on fête aussi \(alsoCelebrated.joined(separator: " · "))")
                            .font(Type.ui(11.5))
                            .foregroundStyle(Ink.textFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Label("jour \(ephemeris.dayOfYear)", systemImage: "number")
                        Label("semaine \(ephemeris.weekNumber)", systemImage: "calendar.day.timeline.left")
                        Spacer(minLength: 0)
                        Text("\(ephemeris.daysRemaining) j restants")
                    }
                    .font(Type.ui(10.5, weight: .medium))
                    .foregroundStyle(Ink.textFaint)

                    YearBar(progress: yearProgress)
                        .frame(height: 5)
                }

                if !ephemeris.dicton.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(Type.icon(10))
                            .foregroundStyle(Ink.amberDeep)
                        Text(ephemeris.dicton)
                            .font(Type.ui(12.5))
                            .italic()
                            .foregroundStyle(Ink.textSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !ephemeris.historicalEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CE JOUR-LÀ")
                            .font(Type.micro).tracking(1.4)
                            .foregroundStyle(Ink.textFaint)
                        ForEach(ephemeris.historicalEvents, id: \.self) { event in
                            HStack(alignment: .top, spacing: 7) {
                                Circle().fill(Ink.amber).frame(width: 4, height: 4).padding(.top, 6)
                                Text(event)
                                    .font(Type.ui(12))
                                    .foregroundStyle(Ink.textSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// La barre de progression de l'année : une petite jauge de temps qui passe.
struct YearBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Ink.chassisLine)
                Capsule()
                    .fill(LinearGradient(colors: [Ink.amberDeep, Ink.amber],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress.clamped(to: 0...1))
            }
        }
    }
}

/// Les anniversaires et les fêtes tirés de l'annuaire — l'autre visage de
/// l'éphéméride : le calendrier des postes, mais avec des visages connus.
struct BirthdayCard: View {
    let today: [Contact]
    /// Les fiches dont c'est la fête du prénom aujourd'hui.
    var nameDays: [Contact] = []
    let upcoming: [(contact: Contact, date: Date)]

    private var title: String {
        nameDays.isEmpty ? "Anniversaires" : "Anniversaires et fêtes"
    }

    var body: some View {
        ChassisCard(title: title, systemImage: "gift.fill", accent: Ink.rouge) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(today) { contact in
                    HStack(spacing: 10) {
                        Avatar(contact: contact, size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(contact.fullName)
                                .font(Type.ui(13, weight: .semibold))
                                .foregroundStyle(Ink.text)
                            if let age = contact.age() {
                                Text("\(age) ans aujourd’hui")
                                    .font(Type.ui(11))
                                    .foregroundStyle(Ink.rouge)
                            }
                        }
                        Spacer(minLength: 0)
                        if !contact.phone.isEmpty, let url = URL(string: "tel://\(contact.phone.filter { $0.isNumber || $0 == "+" })") {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(Type.icon(12, weight: .semibold))
                                    .foregroundStyle(Ink.moss)
                                    .frame(width: Type.control(30), height: Type.control(30))
                                    .background(Circle().fill(Ink.moss.opacity(0.15)))
                            }
                        }
                    }
                }

                let celebrating = nameDays.filter { !today.contains($0) }
                if !celebrating.isEmpty {
                    if !today.isEmpty { Divider().overlay(Ink.chassisLine) }
                    ForEach(celebrating) { contact in
                        HStack(spacing: 10) {
                            Avatar(contact: contact, size: 30)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(contact.fullName)
                                    .font(Type.ui(13, weight: .semibold))
                                    .foregroundStyle(Ink.text)
                                Text("bonne fête")
                                    .font(Type.ui(11))
                                    .foregroundStyle(Ink.sea)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }

                let others = upcoming.filter { !today.contains($0.contact) }
                if !others.isEmpty {
                    if !today.isEmpty { Divider().overlay(Ink.chassisLine) }
                    ForEach(others, id: \.contact.id) { item in
                        HStack(spacing: 8) {
                            Circle().fill(Ink.label(item.contact.colorIndex))
                                .frame(width: 5, height: 5)
                            Text(item.contact.fullName)
                                .font(Type.ui(12))
                                .foregroundStyle(Ink.textSoft)
                            Spacer(minLength: 4)
                            Text(Fmt.dayShort.string(from: item.date))
                                .font(Type.tape(11))
                                .foregroundStyle(Ink.textFaint)
                        }
                    }
                }
            }
        }
    }
}
