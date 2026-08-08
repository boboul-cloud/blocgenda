import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Petit format

struct SmallDayView: View {
    let entry: DayEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(entry.date, format: .dateTime.day())
                    .font(Type.ui(26, weight: .bold))
                    .foregroundStyle(Ink.amberDeep)
                VStack(alignment: .leading, spacing: -1) {
                    Text(Fmt.weekdayLetter.string(from: entry.date).uppercased() + monthLetters)
                        .font(Type.ui(10, weight: .bold))
                        .foregroundStyle(Ink.text)
                    Text("sem. \(s.weekNumber)")
                        .font(Type.ui(8.5))
                        .foregroundStyle(Ink.textFaint)
                }
                Spacer(minLength: 0)
            }

            Text(s.saintOfTheDay)
                .font(Type.ui(10.5, weight: .medium))
                .foregroundStyle(Ink.textSoft)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let title = s.nextEventTitle, let date = s.nextEventDate {
                VStack(alignment: .leading, spacing: 1) {
                    Text(Fmt.hm.string(from: date))
                        .font(Type.tape(11, weight: .bold))
                        .foregroundStyle(Ink.sea)
                    Text(title)
                        .font(Type.ui(11, weight: .semibold))
                        .foregroundStyle(Ink.text)
                        .lineLimit(2)
                }
            } else if let task = s.firstOpenTask {
                Label(task, systemImage: "square")
                    .font(Type.ui(11))
                    .foregroundStyle(Ink.text)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Label(s.sunrise.map { Fmt.hm.string(from: $0) } ?? "—", systemImage: "sunrise.fill")
                Label(s.sunset.map { Fmt.hm.string(from: $0) } ?? "—", systemImage: "sunset.fill")
            }
            .font(Type.tape(9))
            .foregroundStyle(Ink.textFaint)
        }
    }

    private var monthLetters: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "MMM"
        return " " + f.string(from: entry.date).uppercased()
    }
}

// MARK: - Format moyen

struct MediumDayView: View {
    let entry: DayEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.date, format: .dateTime.day())
                        .font(Type.ui(28, weight: .bold))
                        .foregroundStyle(Ink.amberDeep)
                    VStack(alignment: .leading, spacing: -2) {
                        Text(Fmt.dayFull.string(from: entry.date).capitalizedFirst)
                            .font(Type.ui(10, weight: .semibold))
                            .foregroundStyle(Ink.text)
                            .lineLimit(1)
                        Text("\(s.saintOfTheDay) · jour \(s.dayNumber)")
                            .font(Type.ui(9))
                            .foregroundStyle(Ink.textFaint)
                            .lineLimit(1)
                    }
                }

                Divider().overlay(Ink.chassisLine)

                HStack(spacing: 10) {
                    stat(icon: "sunrise.fill", value: s.sunrise.map { Fmt.hm.string(from: $0) } ?? "—", tint: Ink.amberDeep)
                    stat(icon: "sunset.fill", value: s.sunset.map { Fmt.hm.string(from: $0) } ?? "—", tint: Ink.amberDeep)
                    if let tide = s.nextTide {
                        stat(icon: tide.isHigh ? "arrow.up.to.line" : "arrow.down.to.line",
                             value: Fmt.hm.string(from: tide.date), tint: Ink.sea)
                    }
                }

                Spacer(minLength: 0)

                if let temp = s.temperature, let symbol = s.weatherSymbol {
                    HStack(spacing: 5) {
                        Image(systemName: symbol).font(.system(size: 11))
                        Text("\(Int(temp.rounded())) °C · \(s.placeName)")
                            .font(Type.ui(10))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Ink.textSoft)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                if let title = s.nextEventTitle, let date = s.nextEventDate {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PROCHAIN")
                            .font(Type.ui(7.5, weight: .bold)).tracking(1.2)
                            .foregroundStyle(Ink.textFaint)
                        Text(Fmt.hm.string(from: date))
                            .font(Type.tape(13, weight: .bold))
                            .foregroundStyle(Ink.sea)
                        Text(title)
                            .font(Type.ui(11, weight: .semibold))
                            .foregroundStyle(Ink.text)
                            .lineLimit(2)
                    }
                }

                if let task = s.firstOpenTask, let id = s.firstOpenTaskID {
                    Button(intent: ToggleTaskIntent(entryID: id)) {
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "square")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Ink.moss)
                            Text(task)
                                .font(Type.ui(10.5))
                                .foregroundStyle(Ink.text)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("\(s.doneTaskCount)/\(s.doneTaskCount + s.openTaskCount)")
                        .font(Type.tape(10, weight: .bold))
                        .foregroundStyle(Ink.moss)
                    Text("actions")
                        .font(Type.ui(9))
                        .foregroundStyle(Ink.textFaint)
                    Spacer(minLength: 0)
                    if abs(s.todayTotal) > 0.001 {
                        Text(NumberStyleFR.money(s.todayTotal, symbol: s.currencySymbol))
                            .font(Type.tape(10, weight: .bold))
                            .foregroundStyle(Ink.amberDeep)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(tint)
            Text(value).font(Type.tape(10)).foregroundStyle(Ink.text)
        }
    }
}

// MARK: - Grand format

struct LargeDayView: View {
    let entry: DayEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MediumDayView(entry: entry)
                .frame(height: 118)

            Divider().overlay(Ink.chassisLine)

            if !s.tides.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MARÉE — \(s.tidePortName ?? s.placeName)".uppercased())
                        .font(Type.ui(7.5, weight: .bold)).tracking(1.2)
                        .foregroundStyle(Ink.textFaint)
                    HStack(spacing: 6) {
                        ForEach(s.tides) { mark in
                            VStack(spacing: 1) {
                                Image(systemName: mark.symbol)
                                    .font(.system(size: 8, weight: .bold))
                                Text(Fmt.hm.string(from: mark.date))
                                    .font(Type.tape(10, weight: .semibold))
                                Text(String(format: "%.1f m", mark.height))
                                    .font(Type.tape(8))
                                    .foregroundStyle(Ink.textFaint)
                            }
                            .foregroundStyle(mark.isHigh ? Ink.sea : Ink.amberDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Ink.sunken))
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "moonphase.first.quarter")
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.violet)
                Text("\(s.moonPhaseName) · \(Int((s.moonIllumination * 100).rounded())) %")
                    .font(Type.ui(10.5))
                    .foregroundStyle(Ink.textSoft)
                Spacer(minLength: 0)
                if !s.birthdays.isEmpty {
                    Label(s.birthdays.joined(separator: ", "), systemImage: "gift.fill")
                        .font(Type.ui(10))
                        .foregroundStyle(Ink.rouge)
                        .lineLimit(1)
                }
            }

            if let note = s.lastNote {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DERNIÈRE LIGNE DU ROULEAU")
                        .font(Type.ui(7.5, weight: .bold)).tracking(1.2)
                        .foregroundStyle(Ink.textFaint)
                    Text(note)
                        .font(Type.tape(11))
                        .foregroundStyle(Ink.text)
                        .lineLimit(3)
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Ink.sunken))
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Écran verrouillé

struct RectangularAccessory: View {
    let entry: DayEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(s.saintOfTheDay)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            if let title = s.nextEventTitle, let date = s.nextEventDate {
                Text("\(Fmt.hm.string(from: date)) \(title)")
                    .font(.system(size: 12))
                    .lineLimit(1)
            } else if let task = s.firstOpenTask {
                Text(task).font(.system(size: 12)).lineLimit(1)
            }
            HStack(spacing: 6) {
                if let rise = s.sunrise { Label(Fmt.hm.string(from: rise), systemImage: "sunrise.fill") }
                if let set = s.sunset { Label(Fmt.hm.string(from: set), systemImage: "sunset.fill") }
            }
            .font(.system(size: 10))
        }
        .widgetAccentable()
    }
}

struct InlineAccessory: View {
    let entry: DayEntry

    var body: some View {
        if let tide = entry.snapshot.nextTide {
            Text("\(tide.label) \(Fmt.hm.string(from: tide.date))")
        } else if let event = entry.snapshot.nextEventTitle, let date = entry.snapshot.nextEventDate {
            Text("\(Fmt.hm.string(from: date)) \(event)")
        } else {
            Text(entry.snapshot.saintOfTheDay)
        }
    }
}

// MARK: - Widget marée

struct TideWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry
    private var s: WidgetSnapshot { entry.snapshot }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -1) {
                    Image(systemName: s.nextTide?.isHigh == true ? "arrow.up.to.line" : "arrow.down.to.line")
                        .font(.system(size: 11, weight: .bold))
                    Text(s.nextTide.map { Fmt.hmShort.string(from: $0.date) } ?? "—")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
        case .accessoryRectangular:
            RectangularAccessory(entry: entry)
        default:
            tideCard
        }
    }

    private var tideCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "water.waves")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Ink.sea)
                Text((s.tidePortName ?? s.placeName).uppercased())
                    .font(Type.ui(9, weight: .bold)).tracking(1.1)
                    .foregroundStyle(Ink.textFaint)
                    .lineLimit(1)
            }

            if let next = s.nextTide {
                VStack(alignment: .leading, spacing: 0) {
                    Text(next.label)
                        .font(Type.ui(11, weight: .semibold))
                        .foregroundStyle(next.isHigh ? Ink.sea : Ink.amberDeep)
                    Text(Fmt.hm.string(from: next.date))
                        .font(Type.tape(22, weight: .bold))
                        .foregroundStyle(Ink.text)
                    Text(String(format: "%.2f m · %@", next.height, Fmt.relative(next.date, from: entry.date)))
                        .font(Type.ui(9.5))
                        .foregroundStyle(Ink.textFaint)
                }
            } else {
                Text("Marée indisponible")
                    .font(Type.ui(11))
                    .foregroundStyle(Ink.textFaint)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Label(s.sunrise.map { Fmt.hm.string(from: $0) } ?? "—", systemImage: "sunrise.fill")
                Label(s.sunset.map { Fmt.hm.string(from: $0) } ?? "—", systemImage: "sunset.fill")
            }
            .font(Type.tape(9))
            .foregroundStyle(Ink.textSoft)
        }
    }
}
