import SwiftUI
import WidgetKit

@main
struct BlocgendaWidgetBundle: WidgetBundle {
    var body: some Widget {
        DayWidget()
        TideWidget()
    }
}

// MARK: - Alimentation

struct DayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: Date(),
                            snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date()
        // Une entrée tous les quarts d'heure : les décomptes restent justes.
        let entries = (0..<16).compactMap { step -> DayEntry? in
            guard let date = Calendar.current.date(byAdding: .minute, value: step * 15, to: now)
            else { return nil }
            return DayEntry(date: date, snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget principal

struct DayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BlocgendaDay", provider: DayProvider()) { entry in
            DayWidgetView(entry: entry)
                .widgetURL(URL(string: "blocgenda://rouleau"))
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Ink.chassisSoft, Ink.chassis],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Le jour")
        .description("L’éphéméride, le soleil, le prochain rendez-vous et vos actions.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
    }
}

struct DayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallDayView(entry: entry)
        case .systemMedium: MediumDayView(entry: entry)
        case .systemLarge: LargeDayView(entry: entry)
        case .accessoryRectangular: RectangularAccessory(entry: entry)
        case .accessoryInline: InlineAccessory(entry: entry)
        default: SmallDayView(entry: entry)
        }
    }
}

// MARK: - Widget marée

struct TideWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BlocgendaTide", provider: DayProvider()) { entry in
            TideWidgetView(entry: entry)
                .widgetURL(URL(string: "blocgenda://jour"))
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Ink.seaDeep.opacity(0.55), Ink.chassis],
                                   startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Marée")
        .description("La prochaine pleine ou basse mer, et la course du soleil.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
