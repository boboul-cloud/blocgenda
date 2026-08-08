import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showArchive = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Lieu", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text(store.settings.place.name).foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Coordonnées", systemImage: "globe")
                        Spacer()
                        Text(store.settings.place.shortCoordinates)
                            .font(Type.tape(12))
                            .foregroundStyle(.secondary)
                    }
                    if let port = store.settings.tidePort {
                        HStack {
                            Label("Port de marée", systemImage: "water.waves")
                            Spacer()
                            Text(port.name).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Éphéméride")
                } footer: {
                    Text("Le lieu se change depuis l’écran « Le jour ».")
                }

                Section {
                    switch notificationStatus {
                    case .notDetermined:
                        Button("Autoriser les notifications") {
                            Task {
                                notificationStatus = await Notifications.ensureAuthorization()
                                await reschedule()
                            }
                        }
                    case .denied:
                        // iOS ne repose jamais la question : le seul chemin
                        // ouvert est le réglage système.
                        Button("Ouvrir les Réglages d’iOS") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                    default:
                        EmptyView()
                    }
                    Toggle("Le point du matin", isOn: $store.settings.morningBriefingEnabled)
                    if store.settings.morningBriefingEnabled {
                        TimeRow(hour: $store.settings.morningBriefingHour,
                                minute: $store.settings.morningBriefingMinute,
                                label: "Heure du matin")
                    }
                    Toggle("Bilan du soir", isOn: $store.settings.eveningReviewEnabled)
                    if store.settings.eveningReviewEnabled {
                        TimeRow(hour: $store.settings.eveningReviewHour,
                                minute: $store.settings.eveningReviewMinute,
                                label: "Heure du soir")
                    }
                    Toggle("Alerte heure dorée", isOn: $store.settings.goldenHourAlert)
                    Toggle("Alerte marée (1 h avant)", isOn: $store.settings.tideAlert)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(notificationStatus == .denied
                         ? "iOS bloque les rappels de Blocgenda : rien n’arrivera, quels que soient les réglages ci-dessus. L’autorisation se rend dans Réglages ▸ Blocgenda ▸ Notifications."
                         : "Le point du matin résume le saint du jour, le soleil et le lieu. Le bilan du soir invite à faire le point sur le rouleau.")
                }

                Section("Calculatrice") {
                    HStack {
                        Text("Symbole monétaire")
                        Spacer()
                        TextField("€", text: $store.settings.currencySymbol)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    HStack {
                        Text("Taux de TVA")
                        Spacer()
                        Text("\(NumberStyleFR.format(store.settings.vatRate)) %")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.settings.vatRate, in: 0...30, step: 0.5)
                }

                Section("Rouleau") {
                    Button {
                        showArchive = true
                    } label: {
                        HStack {
                            Label("Bandes archivées", systemImage: "archivebox")
                            Spacer()
                            Text("\(store.tape.filter { !$0.isOnRoll }.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Imprimer un sous-total maintenant") {
                        store.printSubtotal()
                        dismiss()
                    }
                }

                Section {
                    HStack {
                        Text("Lignes sur le rouleau")
                        Spacer()
                        Text("\(store.rollEntries.count)").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Rendez-vous")
                        Spacer()
                        Text("\(store.events.count)").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Fiches d’annuaire")
                        Spacer()
                        Text("\(store.contacts.count)").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Contenu")
                } footer: {
                    Text("Blocgenda enregistre tout sur votre appareil, dans un dossier partagé avec le widget. Aucune donnée n’est envoyée ailleurs ; seules la météo et la marée sont demandées à Open-Meteo à partir de coordonnées arrondies.")
                }

                Section {
                    Link(destination: Legal.privacy) {
                        Label("Politique de confidentialité", systemImage: "hand.raised")
                    }
                    Link(destination: Legal.terms) {
                        Label("Conditions d’utilisation", systemImage: "doc.text")
                    }
                    Link(destination: Legal.support) {
                        Label("Assistance", systemImage: "lifepreserver")
                    }
                    Link(destination: Legal.site) {
                        Label("Site de Blocgenda", systemImage: "globe")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Legal.versionString).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("À propos")
                } footer: {
                    Text(Legal.copyright)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        store.persistNow()
                        Task { await reschedule() }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showArchive) {
                ArchiveView().environment(store)
            }
            .task { notificationStatus = await Notifications.authorizationStatus() }
            // L'autorisation a pu changer dans les Réglages d'iOS pendant que
            // l'écran restait ouvert : on relit l'état au retour.
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { notificationStatus = await Notifications.authorizationStatus() }
            }
        }
        .paperSheet()
    }

    private func reschedule() async {
        await Notifications.reschedule(events: store.events, settings: store.settings)
        await Notifications.scheduleGoldenHour(settings: store.settings)
        if let marks = store.dayData.tide?.marks {
            await Notifications.scheduleTide(marks: marks, settings: store.settings)
        }
    }
}

struct TimeRow: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let label: String

    private var date: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                hour = Calendar.current.component(.hour, from: newValue)
                minute = Calendar.current.component(.minute, from: newValue)
            })
    }

    var body: some View {
        DatePicker(label, selection: date, displayedComponents: [.hourAndMinute])
    }
}

/// Les bandes détachées, conservées et consultables.
struct ArchiveView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var archived: [(day: Date, entries: [TapeEntry])] {
        let torn = store.tape.filter { !$0.isOnRoll }
        return Dictionary(grouping: torn) { Calendar.current.startOfDay(for: $0.tornAt ?? $0.date) }
            .map { (day: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            List {
                if archived.isEmpty {
                    ContentUnavailableView("Aucune bande archivée",
                                           systemImage: "archivebox",
                                           description: Text("Les bandes déchirées depuis le rouleau se retrouvent ici."))
                }
                ForEach(archived, id: \.day) { group in
                    Section(Fmt.dayFull.string(from: group.day).capitalizedFirst) {
                        ForEach(group.entries) { entry in
                            HStack(alignment: .top, spacing: 10) {
                                Text(Fmt.hmShort.string(from: entry.date))
                                    .font(Type.tape(10))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, alignment: .leading)
                                Text(entry.kind == .calc ? (entry.expression ?? "") : entry.text)
                                    .font(Type.tape(12))
                                Spacer(minLength: 4)
                                if let v = entry.value {
                                    Text(NumberStyleFR.money(v, symbol: store.settings.currencySymbol))
                                        .font(Type.tape(12, weight: .semibold))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bandes archivées")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    if !archived.isEmpty {
                        Button("Vider", role: .destructive) {
                            store.tape.removeAll { !$0.isOnRoll }
                            store.persistNow()
                        }
                    }
                }
            }
        }
        .paperSheet()
    }
}
