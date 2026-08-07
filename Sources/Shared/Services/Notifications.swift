import Foundation
import UserNotifications

/// Programme les notifications : rappels de rendez-vous, briefing du matin,
/// bilan du soir, et les alertes optionnelles (heure dorée, marée).
enum Notifications {

    static let morningID = "blocgenda.morning"
    static let eveningID = "blocgenda.evening"
    static let goldenID = "blocgenda.golden"
    static let tideID = "blocgenda.tide"

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Reconstruit toute la programmation. Appelé après chaque modification.
    static func reschedule(events: [AgendaEvent], settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        let existing = await center.pendingNotificationRequests()
        let eventIDs = existing.map(\.identifier).filter { $0.hasPrefix("evt.") }
        center.removePendingNotificationRequests(withIdentifiers: eventIDs)

        let cal = Calendar.current
        let now = Date()
        var scheduled = 0

        for event in events {
            guard scheduled < 56 else { break } // iOS plafonne à 64 notifications locales
            for dayOffset in 0..<21 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: now),
                      let start = event.occurrence(on: day) else { continue }
                for minutes in event.reminders {
                    let fire = start.addingTimeInterval(-Double(minutes) * 60)
                    guard fire > now, scheduled < 56 else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = event.title
                    var pieces: [String] = []
                    if !event.isAllDay { pieces.append(Fmt.hm.string(from: start)) }
                    if !event.place.isEmpty { pieces.append(event.place) }
                    if minutes > 0 { pieces.append("dans \(Fmt.duration(Double(minutes) * 60))") }
                    content.body = pieces.joined(separator: " · ")
                    content.sound = .default
                    content.userInfo = ["eventID": event.id.uuidString]

                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                        repeats: false)
                    let id = "evt.\(event.id.uuidString).\(dayOffset).\(minutes)"
                    try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                    scheduled += 1
                }
            }
        }

        await scheduleDailyDigests(settings: settings)
    }

    static func scheduleDailyDigests(settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])

        if settings.morningBriefingEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Le point du matin"
            content.body = morningBody(settings: settings)
            content.sound = .default
            var comps = DateComponents()
            comps.hour = settings.morningBriefingHour
            comps.minute = settings.morningBriefingMinute
            try? await center.add(UNNotificationRequest(
                identifier: morningID, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
        }

        if settings.eveningReviewEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Bilan de la journée"
            content.body = "Un coup d’œil au rouleau avant de le déchirer ?"
            content.sound = .default
            var comps = DateComponents()
            comps.hour = settings.eveningReviewHour
            comps.minute = settings.eveningReviewMinute
            try? await center.add(UNNotificationRequest(
                identifier: eveningID, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
        }
    }

    /// Texte du briefing : éphéméride + soleil, calculés à l'avance pour demain.
    private static func morningBody(settings: AppSettings) -> String {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let place = settings.place
        let eph = Ephemeris.forDay(tomorrow)
        let sun = Astro.sunTimes(date: tomorrow, lat: place.latitude, lon: place.longitude)
        var pieces = ["\(eph.saint)"]
        if let rise = sun.sunrise, let set = sun.sunset {
            pieces.append("soleil \(Fmt.hm.string(from: rise)) → \(Fmt.hm.string(from: set))")
        }
        pieces.append(place.name)
        return pieces.joined(separator: " · ")
    }

    /// Alerte « heure dorée » : 15 minutes avant le début de la lumière rasante.
    static func scheduleGoldenHour(settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [goldenID])
        guard settings.goldenHourAlert else { return }

        let place = settings.place
        for offset in 0..<3 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let sun = Astro.sunTimes(date: day, lat: place.latitude, lon: place.longitude)
            guard let golden = sun.goldenHour else { continue }
            let fire = golden.addingTimeInterval(-15 * 60)
            guard fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Heure dorée dans 15 minutes"
            var body = "La lumière rasante commence à \(Fmt.hm.string(from: golden))"
            if let dusk = sun.dusk { body += ", heure bleue jusqu’à \(Fmt.hm.string(from: dusk))" }
            content.body = body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: "\(goldenID).\(offset)", content: content, trigger: trigger))
            break
        }
    }

    /// Alerte marée : une heure avant la prochaine pleine ou basse mer.
    static func scheduleTide(marks: [TideMark], settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<6).map { "\(tideID).\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard settings.tideAlert else { return }

        let upcoming = marks.filter { $0.date > Date() }.prefix(4)
        for (i, mark) in upcoming.enumerated() {
            let fire = mark.date.addingTimeInterval(-3600)
            guard fire > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(mark.label) dans une heure"
            content.body = String(format: "%@ à %@ · %.2f m",
                                  settings.tideReference.name,
                                  Fmt.hm.string(from: mark.date), mark.height)
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: "\(tideID).\(i)", content: content, trigger: trigger))
        }
    }
}
