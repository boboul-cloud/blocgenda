import SwiftUI

/// Le morceau de bande détaché, rendu en image : on peut l'envoyer par message,
/// l'enregistrer dans ses photos, ou simplement le garder comme un ticket.
struct TearReceipt: View {
    let entries: [TapeEntry]
    let total: Double
    let currency: String
    let place: String

    private var days: [TapeDay] {
        Dictionary(grouping: entries) { $0.day }
            .map { TapeDay(day: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.day < $1.day }
    }

    var body: some View {
        VStack(spacing: 0) {
            TornEdge(seed: 11, atBottom: false).fill(Ink.paper).frame(height: 12)

            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text("BLOCGENDA")
                        .font(Type.tape(13, weight: .bold))
                        .tracking(5)
                    Text(place.uppercased())
                        .font(Type.tape(9))
                        .tracking(2)
                        .foregroundStyle(Ink.textSoft)
                }
                .padding(.top, 6)

                DottedRule()

                ForEach(days) { day in
                    VStack(spacing: 5) {
                        Text(Fmt.dayFull.string(from: day.day).uppercased())
                            .font(Type.tape(9, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Ink.textSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(day.entries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(Fmt.hmShort.string(from: entry.date))
                                    .font(Type.tape(9))
                                    .foregroundStyle(Ink.textFaint)
                                    .frame(width: 32, alignment: .leading)
                                Text(line(for: entry))
                                    .font(Type.tape(11))
                                    .foregroundStyle(Ink.text)
                                Spacer(minLength: 4)
                                if let v = entry.value {
                                    Text(NumberStyleFR.money(v, symbol: entry.kind == .calc ? "" : currency))
                                        .font(Type.tape(11, weight: .semibold))
                                        .foregroundStyle(Ink.text)
                                }
                            }
                        }
                    }
                }

                DottedRule()

                HStack {
                    Text("TOTAL")
                        .font(Type.tape(12, weight: .bold))
                        .tracking(2)
                    Spacer()
                    Text(NumberStyleFR.money(total, symbol: currency))
                        .font(Type.tape(15, weight: .bold))
                }
                .foregroundStyle(Ink.text)

                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(Type.tape(8))
                    .foregroundStyle(Ink.textFaint)
                    .padding(.top, 2)
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 20)

            TornEdge(seed: 23, atBottom: true).fill(Ink.paper).frame(height: 12)
        }
        .frame(width: 340)
        .background(Ink.paper)
    }

    private func line(for entry: TapeEntry) -> String {
        switch entry.kind {
        case .calc: return entry.expression ?? ""
        case .task: return "\(entry.done ? "☑" : "☐") \(entry.text)"
        case .subtotal: return entry.text.uppercased()
        case .event: return "▸ \(entry.text)"
        case .note, .memo: return entry.text
        }
    }
}
