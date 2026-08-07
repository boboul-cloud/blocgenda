import SwiftUI

/// L'agenda : une bande de jours en haut, la journée choisie en dessous.
struct AgendaView: View {
    @Environment(Store.self) private var store
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var editing: AgendaEvent?
    @State private var weekOffset = 0

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let base = cal.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        guard let start = cal.dateInterval(of: .weekOfYear, for: base)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var occurrences: [EventOccurrence] { store.occurrences(on: selectedDay) }

    /// Ce que l'agenda montre du rouleau : les actions et les notes du jour.
    /// Les calculs et les sous-totaux restent sur la bande — leur place est
    /// dans la colonne de chiffres, pas dans une journée.
    private var dayEntries: [TapeEntry] {
        store.entries(on: selectedDay).filter(Self.belongsInAgenda)
    }

    static func belongsInAgenda(_ entry: TapeEntry) -> Bool {
        guard entry.isOnRoll else { return false }
        switch entry.kind {
        case .task, .note: return true
        case .calc, .subtotal, .memo, .event: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Agenda",
                         subtitle: Fmt.dayTitle(selectedDay)) {
                HStack(spacing: 8) {
                    if !Calendar.current.isDateInToday(selectedDay) || weekOffset != 0 {
                        Button {
                            withAnimation(.snappy) {
                                weekOffset = 0
                                selectedDay = Calendar.current.startOfDay(for: Date())
                            }
                        } label: {
                            Text("Aujourd’hui")
                                .font(Type.ui(11, weight: .semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Capsule().fill(Ink.chassisSoft))
                                .foregroundStyle(Ink.textSoft)
                        }
                    }
                    Button {
                        var event = AgendaEvent()
                        event.start = defaultStart(on: selectedDay)
                        editing = event
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Ink.amber))
                    }
                    .accessibilityIdentifier("agenda.nouveau")
                    .accessibilityLabel("Nouveau rendez-vous")
                }
                .buttonStyle(.plain)
            }

            WeekStrip(days: weekDays,
                      selected: $selectedDay,
                      offset: $weekOffset,
                      density: densities)

            ScrollView {
                VStack(spacing: 10) {
                    if occurrences.isEmpty && dayEntries.isEmpty {
                        EmptyDay(day: selectedDay)
                    }

                    ForEach(occurrences) { occurrence in
                        EventRow(occurrence: occurrence) {
                            editing = occurrence.event
                        } onToggle: {
                            withAnimation(.snappy) {
                                store.toggleCompletion(of: occurrence.event, on: occurrence.start)
                            }
                        }
                    }

                    if !dayEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES ET ACTIONS")
                                .font(Type.micro).tracking(1.4)
                                .foregroundStyle(Ink.textFaint)
                                .padding(.horizontal, 4)
                            ForEach(dayEntries) { entry in
                                AgendaTapeRow(entry: entry,
                                              currency: store.settings.currencySymbol)
                            }
                        }
                    }

                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .animation(.snappy(duration: 0.25), value: dayEntries.count)
            }
            .scrollDismissesKeyboard(.interactively)

            SmartBar(text: $draft,
                     showKeypad: .constant(false),
                     focused: $inputFocused,
                     onSubmit: print,
                     placeholder: barPlaceholder,
                     showsKeypadToggle: false,
                     reference: referenceDate,
                     tagSuggestions: store.frequentTags())

            Color.clear.frame(height: 62) // place pour la barre d'onglets
        }
        .background(Ink.chassis)
        .sheet(item: $editing) { event in
            EventEditor(event: event).environment(store)
        }
    }

    // MARK: - Saisie

    /// Le jour visé sert de repère à l'analyse : sur un jour à venir, « 9h »
    /// désigne neuf heures ce jour-là.
    private var referenceDate: Date {
        Calendar.current.isDateInToday(selectedDay) ? Date() : selectedDay
    }

    private var barPlaceholder: String {
        Calendar.current.isDateInToday(selectedDay)
            ? "Ajouter aujourd’hui…"
            : "Ajouter au \(Fmt.dayShort.string(from: selectedDay))…"
    }

    private func print() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if store.submit(text, on: selectedDay) != nil {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        draft = ""
    }

    /// Nombre d'événements par jour, pour les points sous la bande de semaine.
    private var densities: [Date: Int] {
        var result: [Date: Int] = [:]
        for day in weekDays {
            result[day] = store.occurrences(on: day).count
                + store.entries(on: day).filter(Self.belongsInAgenda).count
        }
        return result
    }

    private func defaultStart(on day: Date) -> Date {
        let cal = Calendar.current
        let hour = cal.isDateInToday(day) ? min(cal.component(.hour, from: Date()) + 1, 21) : 9
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}

/// La bande des sept jours de la semaine.
struct WeekStrip: View {
    let days: [Date]
    @Binding var selected: Date
    @Binding var offset: Int
    let density: [Date: Int]

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button { withAnimation(.snappy) { offset -= 1 } } label: {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                }
                Spacer()
                Text(monthLabel)
                    .font(Type.ui(12, weight: .semibold))
                    .foregroundStyle(Ink.textSoft)
                Spacer()
                Button { withAnimation(.snappy) { offset += 1 } } label: {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(Ink.textFaint)
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            HStack(spacing: 5) {
                ForEach(days, id: \.self) { day in
                    DayChip(day: day,
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selected),
                            isToday: Calendar.current.isDateInToday(day),
                            count: density[day] ?? 0)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(.snappy) { selected = day }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    withAnimation(.snappy) { offset += value.translation.width < 0 ? 1 : -1 }
                }
        )
    }

    private var monthLabel: String {
        guard let first = days.first, let last = days.last else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "MMMM yyyy"
        let a = f.string(from: first).capitalizedFirst
        let b = f.string(from: last).capitalizedFirst
        return a == b ? a : "\(a) – \(b)"
    }
}

struct DayChip: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(Fmt.weekdayLetter.string(from: day).uppercased())
                .font(Type.ui(9, weight: .bold))
                .foregroundStyle(isSelected ? .black.opacity(0.6) : Ink.textFaint)
            Text("\(Calendar.current.component(.day, from: day))")
                .font(Type.ui(16, weight: .semibold))
                .foregroundStyle(isSelected ? .black.opacity(0.9) : (isToday ? Ink.amber : Ink.paper))
            HStack(spacing: 2) {
                ForEach(0..<min(count, 3), id: \.self) { _ in
                    Circle()
                        .fill(isSelected ? Color.black.opacity(0.5) : Ink.sea)
                        .frame(width: 3.5, height: 3.5)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isSelected ? Ink.amber : Ink.chassisSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(isToday && !isSelected ? Ink.amber.opacity(0.5) : .clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

struct EventRow: View {
    let occurrence: EventOccurrence
    var onTap: () -> Void
    var onToggle: () -> Void

    private var event: AgendaEvent { occurrence.event }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                if event.isAllDay {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.textFaint)
                    Text("jour")
                        .font(Type.ui(9))
                        .foregroundStyle(Ink.textFaint)
                } else {
                    Text(Fmt.hm.string(from: occurrence.start))
                        .font(Type.tape(13, weight: .semibold))
                        .foregroundStyle(Ink.paper)
                    Text(Fmt.hm.string(from: occurrence.end))
                        .font(Type.tape(10))
                        .foregroundStyle(Ink.textFaint)
                }
            }
            .frame(width: Type.gutter(50))

            RoundedRectangle(cornerRadius: 2)
                .fill(Ink.label(event.colorIndex))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(Type.ui(14, weight: .semibold))
                    .strikethrough(occurrence.isCompleted, color: Ink.textFaint)
                    .foregroundStyle(occurrence.isCompleted ? Ink.textFaint : Ink.paper)
                HStack(spacing: 6) {
                    if !event.place.isEmpty {
                        Label(event.place, systemImage: "mappin")
                    }
                    if event.repeatRule != .none {
                        Label(event.repeatRule.shortLabel, systemImage: "repeat")
                    }
                    if !event.reminders.isEmpty {
                        Label("\(event.reminders.count)", systemImage: "bell.fill")
                    }
                }
                .font(Type.ui(10.5))
                .foregroundStyle(Ink.textFaint)
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(Type.ui(11))
                        .foregroundStyle(Ink.textSoft)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button(action: onToggle) {
                Image(systemName: occurrence.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(occurrence.isCompleted ? Ink.moss : Ink.chassisLine)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Ink.chassisSoft)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Ink.chassisLine, lineWidth: 1))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

/// Une note ou une action du jour, vue depuis l'agenda : plus compacte que sur
/// la bande, mais on peut cocher sans changer d'écran.
struct AgendaTapeRow: View {
    let entry: TapeEntry
    let currency: String
    @Environment(Store.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if entry.kind == .task {
                    Image(systemName: entry.done ? "checkmark.square.fill" : "square")
                        .foregroundStyle(entry.done ? Ink.moss : Ink.textFaint)
                } else {
                    Image(systemName: "text.alignleft").foregroundStyle(Ink.textFaint)
                }
            }
            .font(.system(size: 14, weight: .medium))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(Type.ui(13))
                    .strikethrough(entry.done, color: Ink.textFaint)
                    .foregroundStyle(entry.done ? Ink.textFaint : Ink.paper)
                    .multilineTextAlignment(.leading)
                if !entry.tags.isEmpty {
                    Text(entry.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(Type.ui(10, weight: .medium))
                        .foregroundStyle(Ink.amberDeep)
                }
            }

            Spacer(minLength: 4)

            if let value = entry.value {
                Text(NumberStyleFR.money(value, symbol: currency))
                    .font(Type.tape(12, weight: .semibold))
                    .foregroundStyle(value < 0 ? Ink.rouge : Ink.textSoft)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Ink.chassisSoft))
        .contentShape(Rectangle())
        .onTapGesture {
            guard entry.kind == .task else { return }
            withAnimation(.snappy) { store.toggleDone(entryID: entry.id) }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { store.delete(entryID: entry.id) }
            } label: { Label("Supprimer", systemImage: "trash") }
        }
    }
}

struct EmptyDay: View {
    let day: Date

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Ink.textFaint)
            Text("Rien de prévu \(Fmt.dayTitle(day).lowercased()).")
                .font(Type.ui(14, weight: .medium))
                .foregroundStyle(Ink.textSoft)
            Text("Ajoutez un rendez-vous, ou écrivez-le\ndirectement sur le rouleau.")
                .font(Type.ui(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
