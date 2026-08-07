import Foundation

/// Photographie compacte de la journée, écrite par l'app et lue par le widget.
/// Le widget ne recalcule que ce qui dépend de l'heure courante.
struct WidgetSnapshot: Codable, Hashable, Sendable {
    var generatedAt: Date = Date()
    var placeName: String = "—"
    var latitude: Double = Place.paris.latitude
    var longitude: Double = Place.paris.longitude

    var sunrise: Date? = nil
    var sunset: Date? = nil
    var moonPhaseName: String = ""
    var moonIllumination: Double = 0

    var saintOfTheDay: String = ""
    var dayNumber: Int = 0
    var weekNumber: Int = 0

    var nextEventTitle: String? = nil
    var nextEventDate: Date? = nil
    var nextEventPlace: String? = nil

    var openTaskCount: Int = 0
    var doneTaskCount: Int = 0
    var firstOpenTask: String? = nil
    var firstOpenTaskID: String? = nil

    var todayTotal: Double = 0
    var currencySymbol: String = "€"
    var lastNote: String? = nil

    var tides: [TideMark] = []
    var tidePortName: String? = nil
    var temperature: Double? = nil
    var weatherSymbol: String? = nil

    var birthdays: [String] = []

    static func load() -> WidgetSnapshot {
        SharedStorage.load(WidgetSnapshot.self, from: .snapshot) ?? WidgetSnapshot.placeholder
    }

    func save() {
        SharedStorage.save(self, to: .snapshot)
    }

    var nextTide: TideMark? {
        tides.first { $0.date > Date() }
    }

    static let placeholder: WidgetSnapshot = {
        var s = WidgetSnapshot()
        let cal = Calendar.current
        let now = Date()
        s.placeName = "Brest"
        s.sunrise = cal.date(bySettingHour: 6, minute: 42, second: 0, of: now)
        s.sunset = cal.date(bySettingHour: 21, minute: 18, second: 0, of: now)
        s.saintOfTheDay = "Saint Gaétan"
        s.dayNumber = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        s.weekNumber = cal.component(.weekOfYear, from: now)
        s.moonPhaseName = "Premier quartier"
        s.moonIllumination = 0.54
        s.nextEventTitle = "Rendez-vous notaire"
        s.nextEventDate = cal.date(bySettingHour: 14, minute: 30, second: 0, of: now)
        s.openTaskCount = 3
        s.doneTaskCount = 2
        s.firstOpenTask = "Rappeler le garage"
        s.todayTotal = 47.60
        s.tides = [
            TideMark(date: cal.date(bySettingHour: 8, minute: 12, second: 0, of: now) ?? now, height: 6.8, isHigh: true),
            TideMark(date: cal.date(bySettingHour: 14, minute: 26, second: 0, of: now) ?? now, height: 1.4, isHigh: false),
            TideMark(date: cal.date(bySettingHour: 20, minute: 38, second: 0, of: now) ?? now, height: 7.1, isHigh: true)
        ]
        s.tidePortName = "Brest"
        s.temperature = 19
        s.weatherSymbol = "cloud.sun.fill"
        return s
    }()
}
