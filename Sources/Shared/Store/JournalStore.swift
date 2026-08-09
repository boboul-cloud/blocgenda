import Foundation

/// Le journal côté rangement : ouvrir la page d'un jour, y déposer une note,
/// et lui apposer le tampon de la journée.
extension Store {

    // MARK: - Lecture

    func journalPage(on day: Date) -> JournalPage? {
        let key = Calendar.current.startOfDay(for: day)
        return journal.first { $0.day == key }
    }

    /// Les jours déjà écrits, du plus récent au plus ancien.
    var journalDays: [Date] {
        journal.filter { !$0.isEmpty }.map(\.day).sorted(by: >)
    }

    // MARK: - Écriture

    /// Ouvre la page du jour si elle n'existe pas encore, et lui appose
    /// aussitôt le tampon de la journée.
    @discardableResult
    func openJournalPage(on day: Date) -> JournalPage {
        let key = Calendar.current.startOfDay(for: day)
        if let existing = journalPage(on: key) { return existing }
        var page = JournalPage(day: key)
        page.stamp = stamp(for: key)
        journal.append(page)
        scheduleSave()
        return page
    }

    /// Dépose un moment sur la page. Une ligne vide n'écrit rien.
    @discardableResult
    func addJournalNote(_ raw: String, on day: Date, spoken: Bool = false) -> JournalNote? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let cal = Calendar.current
        let key = cal.startOfDay(for: day)
        openJournalPage(on: key)
        guard let i = journal.firstIndex(where: { $0.day == key }) else { return nil }

        // Sur un jour passé, la note se range à l'heure qu'il est mais au jour
        // choisi : sans quoi elle se donnerait pour écrite aujourd'hui.
        var note = JournalNote(text: text, spoken: spoken)
        if !cal.isDateInToday(key) {
            let now = cal.dateComponents([.hour, .minute, .second], from: Date())
            note.date = cal.date(bySettingHour: now.hour ?? 12,
                                 minute: now.minute ?? 0,
                                 second: now.second ?? 0,
                                 of: key) ?? key
        }
        journal[i].notes.append(note)
        scheduleSave()
        return note
    }

    func updateJournalNote(_ note: JournalNote, on day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        guard let p = journal.firstIndex(where: { $0.day == key }),
              let n = journal[p].notes.firstIndex(where: { $0.id == note.id }) else { return }
        journal[p].notes[n] = note
        scheduleSave()
    }

    func deleteJournalNote(id: UUID, on day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        guard let p = journal.firstIndex(where: { $0.day == key }) else { return }
        journal[p].notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func setJournalMood(_ mood: JournalMood, on day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        openJournalPage(on: key)
        guard let p = journal.firstIndex(where: { $0.day == key }) else { return }
        journal[p].mood = mood
        scheduleSave()
    }

    func setJournalTitle(_ title: String, on day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        guard let p = journal.firstIndex(where: { $0.day == key }) else { return }
        journal[p].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        scheduleSave()
    }

    // MARK: - Tampon de la journée

    /// Réapplique le tampon tant que le jour n'est pas fini : la météo et la
    /// marée arrivent par le réseau, souvent après l'ouverture de la page. Une
    /// page passée garde le tampon qu'elle avait — c'est tout son intérêt.
    func refreshJournalStamp(on day: Date) {
        let cal = Calendar.current
        let key = cal.startOfDay(for: day)
        guard cal.isDateInToday(key),
              let p = journal.firstIndex(where: { $0.day == key }) else { return }
        var fresh = stamp(for: key)
        // L'heure du tampon est celle de la première apposition : la garder
        // évite qu'un tampon inchangé se croie neuf à chaque passage.
        if let previous = journal[p].stamp { fresh.capturedAt = previous.capturedAt }
        guard journal[p].stamp != fresh else { return }
        journal[p].stamp = fresh
        scheduleSave()
    }

    /// Recopie dans la page tout ce que la journée avait d'objectif.
    func stamp(for day: Date) -> DayStamp {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let place = settings.place
        let eph = Ephemeris.forDay(day)

        var s = DayStamp()
        s.placeName = place.name

        // Le temps et la marée ne valent que pour aujourd'hui : `dayData` ne
        // décrit jamais un autre jour.
        if isToday {
            if let w = dayData.weather {
                s.temperature = w.temperature
                s.minTemperature = w.minTemperature
                s.maxTemperature = w.maxTemperature
                s.weatherLabel = w.label
                s.weatherSymbol = w.symbolName
                s.windCardinal = w.windCardinal
                s.beaufort = w.beaufort
            }
            if let tide = dayData.tide {
                s.tidePort = tide.portName
                s.nextHighTide = tide.marks.first { $0.isHigh && $0.date > Date() }?.date
                    ?? tide.marks.first(where: \.isHigh)?.date
            }
        }

        let sun = isToday ? dayData.sun : nil
        let computed = sun ?? Astro.sunTimes(date: day, lat: place.latitude, lon: place.longitude)
        s.sunrise = computed.sunrise
        s.sunset = computed.sunset

        let moon = isToday ? (dayData.moon ?? Astro.moonIllumination(date: day))
                           : Astro.moonIllumination(date: day)
        s.moonName = moon.name
        s.moonSymbol = moon.symbolName

        s.saint = eph.saint.isEmpty ? nil : eph.saint
        s.dicton = eph.dicton.isEmpty ? nil : eph.dicton
        s.historicalEvent = eph.historicalEvents.first
        s.holidayName = eph.holidayName
        s.dayOfYear = eph.dayOfYear
        s.daysRemaining = eph.daysRemaining
        s.weekNumber = eph.weekNumber

        let fetes = birthdays(on: day).map(\.fullName)
        s.birthdays = fetes.isEmpty ? nil : fetes

        return s
    }
}
