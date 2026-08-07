import Foundation
import Observation
import WidgetKit

/// Source de vérité de l'application. Charge et sauvegarde dans le conteneur
/// partagé, et tient à jour la photographie lue par le widget.
@Observable
@MainActor
final class Store {
    var tape: [TapeEntry] = []
    var events: [AgendaEvent] = []
    var contacts: [Contact] = []
    var settings = AppSettings()

    /// Données du jour dépendant du lieu (soleil, lune, marée, météo).
    var dayData = DayData()

    private var saveWorkItem: Task<Void, Never>?

    init(loadFromDisk: Bool = true) {
        guard loadFromDisk else { return }
        tape = SharedStorage.load([TapeEntry].self, from: .tape) ?? []
        events = SharedStorage.load([AgendaEvent].self, from: .events) ?? []
        contacts = SharedStorage.load([Contact].self, from: .contacts) ?? []
        settings = SharedStorage.load(AppSettings.self, from: .settings) ?? AppSettings()
        if !settings.hasSeededSample && tape.isEmpty && events.isEmpty && contacts.isEmpty {
            seedSampleContent()
            settings.hasSeededSample = true
            persistNow()
        }
    }

    // MARK: - Sauvegarde

    /// Écriture différée : les frappes au clavier ne déclenchent pas un flush disque.
    func scheduleSave() {
        saveWorkItem?.cancel()
        saveWorkItem = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.persistNow()
        }
    }

    func persistNow() {
        SharedStorage.save(tape, to: .tape)
        SharedStorage.save(events, to: .events)
        SharedStorage.save(contacts, to: .contacts)
        SharedStorage.save(settings, to: .settings)
        refreshWidget()
    }

    /// Relit le disque : le widget peut avoir coché une action pendant que
    /// l'app était en arrière-plan.
    func reloadFromDisk() {
        guard let disk = SharedStorage.load([TapeEntry].self, from: .tape) else { return }
        if disk != tape { tape = disk }
    }

    func refreshWidget() {
        makeSnapshot().save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Rouleau

    var rollEntries: [TapeEntry] {
        tape.filter(\.isOnRoll).sorted { $0.date < $1.date }
    }

    var rollDays: [TapeDay] {
        let grouped = Dictionary(grouping: rollEntries) { $0.day }
        return grouped.map { TapeDay(day: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.day < $1.day }
    }

    func entries(on day: Date) -> [TapeEntry] {
        let start = Calendar.current.startOfDay(for: day)
        return tape.filter { $0.day == start }.sorted { $0.date < $1.date }
    }

    @discardableResult
    func add(_ entry: TapeEntry) -> TapeEntry {
        tape.append(entry)
        scheduleSave()
        return entry
    }

    func update(_ entry: TapeEntry) {
        guard let i = tape.firstIndex(where: { $0.id == entry.id }) else { return }
        tape[i] = entry
        scheduleSave()
    }

    func delete(entryID: UUID) {
        tape.removeAll { $0.id == entryID }
        scheduleSave()
    }

    func toggleDone(entryID: UUID) {
        guard let i = tape.firstIndex(where: { $0.id == entryID }) else { return }
        tape[i].done.toggle()
        scheduleSave()
    }

    /// Total courant de la bande depuis le dernier sous-total imprimé.
    var runningTotal: Double {
        let entries = rollEntries
        let lastSubtotal = entries.lastIndex { $0.kind == .subtotal }
        let slice = lastSubtotal.map { Array(entries[($0 + 1)...]) } ?? entries
        return slice.compactMap(\.amount).reduce(0, +)
    }

    /// Imprime un trait de sous-total et repart de zéro.
    func printSubtotal(label: String = "TOTAL") {
        let total = runningTotal
        add(TapeEntry(kind: .subtotal, text: label, value: total))
    }

    /// Détache la bande : les lignes courantes sont archivées.
    func tearOff() -> [TapeEntry] {
        let now = Date()
        let detached = rollEntries
        for entry in detached {
            guard let i = tape.firstIndex(where: { $0.id == entry.id }) else { continue }
            // Les actions non faites restent sur la bande : on ne perd rien.
            if tape[i].kind == .task && !tape[i].done { continue }
            if tape[i].pinned { continue }
            tape[i].tornAt = now
        }
        scheduleSave()
        return detached
    }

    // MARK: - Agenda

    func occurrences(on day: Date) -> [EventOccurrence] {
        events.compactMap { event in
            event.occurrence(on: day).map { EventOccurrence(event: event, start: $0) }
        }
        .sorted { a, b in
            if a.event.isAllDay != b.event.isAllDay { return a.event.isAllDay }
            return a.start < b.start
        }
    }

    func occurrences(from start: Date, days: Int) -> [EventOccurrence] {
        let cal = Calendar.current
        return (0..<days).flatMap { offset -> [EventOccurrence] in
            guard let d = cal.date(byAdding: .day, value: offset, to: start) else { return [] }
            return occurrences(on: d)
        }
    }

    var nextOccurrence: EventOccurrence? {
        let now = Date()
        return occurrences(from: Calendar.current.startOfDay(for: now), days: 30)
            .first { $0.start > now }
    }

    func save(event: AgendaEvent) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
        scheduleSave()
        Task { await Notifications.reschedule(events: events, settings: settings) }
    }

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        tape.removeAll { $0.eventID == id && $0.kind == .event }
        scheduleSave()
        Task { await Notifications.reschedule(events: events, settings: settings) }
    }

    func toggleCompletion(of event: AgendaEvent, on day: Date) {
        guard let i = events.firstIndex(where: { $0.id == event.id }) else { return }
        let key = Calendar.current.startOfDay(for: day)
        if events[i].completedDays.contains(key) {
            events[i].completedDays.remove(key)
        } else {
            events[i].completedDays.insert(key)
        }
        scheduleSave()
    }

    // MARK: - Annuaire

    func save(contact: Contact) {
        if let i = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[i] = contact
        } else {
            contacts.append(contact)
        }
        scheduleSave()
    }

    func deleteContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        scheduleSave()
    }

    func birthdays(on day: Date) -> [Contact] {
        contacts.filter { $0.hasBirthday(on: day) }
    }

    /// Les anniversaires des trente prochains jours, dans l'ordre.
    func upcomingBirthdays(limit: Int = 5) -> [(contact: Contact, date: Date)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [(Contact, Date)] = []
        for offset in 0..<60 {
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            for c in contacts where c.hasBirthday(on: d) {
                result.append((c, d))
            }
        }
        return Array(result.prefix(limit))
    }

    // MARK: - Saisie unifiée

    /// Point d'entrée de la barre du rouleau : une ligne de texte devient
    /// calcul, action, rendez-vous ou note selon ce qu'elle contient.
    @discardableResult
    func submit(_ raw: String) -> TapeEntry? {
        guard let parsed = SmartInput.parse(raw) else { return nil }
        var entry = TapeEntry()
        entry.tags = parsed.tags

        switch parsed.intent {
        case .calculation(let expression, let value):
            entry.kind = .calc
            entry.expression = expression
            entry.value = value
            entry.text = ""

        case .task(let text, let due):
            entry.kind = .task
            entry.text = text
            if let due {
                var event = AgendaEvent()
                event.title = text
                event.start = due
                event.isAllDay = Calendar.current.component(.hour, from: due) == 0
                event.duration = 1800
                save(event: event)
                entry.eventID = event.id
            }

        case .event(let title, let start, let duration, let allDay):
            var event = AgendaEvent()
            event.title = title
            event.start = start
            event.duration = duration
            event.isAllDay = allDay
            event.colorIndex = abs(title.hashValue) % Ink.palette.count
            save(event: event)
            entry.kind = .event
            entry.text = title
            entry.eventID = event.id
            entry.value = nil

        case .note(let text, let amount):
            entry.kind = .note
            entry.text = text
            entry.value = amount
        }

        // Rattachement à un contact mentionné par « @ ».
        if let mention = parsed.mentions.first,
           let contact = contacts.first(where: {
               $0.fullName.folding(options: .diacriticInsensitive, locale: .current)
                   .localizedCaseInsensitiveContains(mention)
           }) {
            entry.text += entry.text.isEmpty ? "@\(contact.fullName)" : " — @\(contact.fullName)"
        }

        return add(entry)
    }

    // MARK: - Photographie pour le widget

    func makeSnapshot() -> WidgetSnapshot {
        var s = WidgetSnapshot()
        let now = Date()
        let cal = Calendar.current
        let place = settings.place
        let eph = Ephemeris.forDay(now)

        s.generatedAt = now
        s.placeName = place.name
        s.latitude = place.latitude
        s.longitude = place.longitude

        let sun = Astro.sunTimes(date: now, lat: place.latitude, lon: place.longitude)
        s.sunrise = sun.sunrise
        s.sunset = sun.sunset

        let moon = Astro.moonIllumination(date: now)
        s.moonPhaseName = moon.name
        s.moonIllumination = moon.fraction

        s.saintOfTheDay = eph.saint
        s.dayNumber = eph.dayOfYear
        s.weekNumber = eph.weekNumber

        if let next = nextOccurrence {
            s.nextEventTitle = next.event.title
            s.nextEventDate = next.start
            s.nextEventPlace = next.event.place.isEmpty ? nil : next.event.place
        }

        let todayEntries = entries(on: now)
        let tasks = todayEntries.filter { $0.kind == .task }
        s.openTaskCount = tasks.filter { !$0.done }.count
        s.doneTaskCount = tasks.filter(\.done).count
        if let first = tasks.first(where: { !$0.done }) {
            s.firstOpenTask = first.text
            s.firstOpenTaskID = first.id.uuidString
        }
        s.todayTotal = todayEntries.compactMap(\.amount).reduce(0, +)
        s.currencySymbol = settings.currencySymbol
        s.lastNote = todayEntries.last(where: { $0.kind == .note })?.text

        s.tides = dayData.tide?.marks.filter { cal.isDate($0.date, inSameDayAs: now) } ?? []
        s.tidePortName = dayData.tide?.portName
        s.temperature = dayData.weather?.temperature
        s.weatherSymbol = dayData.weather?.symbolName
        s.birthdays = birthdays(on: now).map(\.fullName)

        return s
    }

    // MARK: - Contenu de démonstration

    private func seedSampleContent() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        contacts = [
            Contact(firstName: "Marie", lastName: "Lambert", phone: "06 12 34 56 78",
                    email: "marie.lambert@example.com", isFavorite: true, group: "Famille", colorIndex: 1),
            Contact(firstName: "Capitainerie", lastName: "du port", company: "Port de plaisance",
                    phone: "02 98 00 00 00", group: "Mer", colorIndex: 2),
            Contact(firstName: "Docteur", lastName: "Renard", phone: "02 97 11 22 33",
                    address: "3 rue des Lilas", group: "Santé", colorIndex: 4)
        ]

        var rdv = AgendaEvent()
        rdv.title = "Marché du port"
        rdv.start = cal.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today
        rdv.duration = 5400
        rdv.repeatRule = .weekly
        rdv.place = "Quai Malbert"
        rdv.colorIndex = 1
        events = [rdv]

        tape = [
            TapeEntry(date: today.addingTimeInterval(8 * 3600), kind: .note,
                      text: "Bienvenue sur votre rouleau. Écrivez ci-dessous : un calcul, une note, une action ou un rendez-vous."),
            TapeEntry(date: today.addingTimeInterval(8 * 3600 + 60), kind: .task,
                      text: "Essayer « demain 14h30 dentiste »"),
            TapeEntry(date: today.addingTimeInterval(8 * 3600 + 120), kind: .calc,
                      text: "", expression: "12,50 × 3", value: 37.5)
        ]
    }
}

/// Données du jour qui dépendent du lieu et d'Internet.
struct DayData {
    var sun: Astro.SunTimes?
    var moon: Astro.MoonIllumination?
    var moonTimes: (rise: Date?, set: Date?)?
    var tide: TideDay?
    var weather: WeatherNow?
    var solunar: [Solunar.Period] = []
    var tideError: String?
    var isLoading = false
    var computedFor: Date?
    var computedPlace: String?
}
