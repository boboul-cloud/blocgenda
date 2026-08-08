import SwiftUI
import UserNotifications

@main
struct BlocgendaApp: App {
    @State private var store = Store()
    @State private var location = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(location)
                .preferredColorScheme(.light)
                .tint(Ink.amberDeep)
                .task { await bootstrap() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.reloadFromDisk()
                Task { await store.refreshDay() }
            } else {
                store.persistNow()
            }
        }
    }

    private func bootstrap() async {
        location.onPlaceChange { place in
            guard store.settings.followLocation else { return }
            store.settings.place = place
            store.scheduleSave()
            Task { await store.refreshDay(force: true) }
        }
        if store.settings.followLocation { location.request() }
        await store.refreshDay()
        // Sans cette demande, tout ce qui suit est programmé pour rien.
        await Notifications.ensureAuthorization()
        await Notifications.reschedule(events: store.events, settings: store.settings)
        await Notifications.scheduleGoldenHour(settings: store.settings)
    }
}

/// Affiche les notifications même quand l'app est au premier plan : un rappel
/// de rendez-vous doit se voir, y compris pendant qu'on écrit sur le rouleau.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
