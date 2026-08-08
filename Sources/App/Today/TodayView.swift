import SwiftUI

/// « Le jour » : tout ce que la journée a d'objectif — la course du soleil,
/// la marée, la lune, l'éphéméride et les anniversaires.
struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var now = Date()
    @State private var showPlacePicker = false

    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var place: Place { store.settings.place }
    private var ephemeris: Ephemeris { Ephemeris.forDay(now) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(title: "Le jour", subtitle: ephemeris.dayLabel) {
                    Button { showPlacePicker = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: place.isAutomatic ? "location.fill" : "mappin")
                                .font(Type.icon(10, weight: .bold))
                            Text(place.name)
                                .font(Type.ui(12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Ink.sea)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Ink.sea.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, -20)

                SunCard(sun: store.dayData.sun, weather: store.dayData.weather, now: now,
                        yesterday: Astro.sunTimes(date: now.addingTimeInterval(-86400),
                                                  lat: place.latitude, lon: place.longitude))

                TideCard(tide: store.dayData.tide,
                         error: store.dayData.tideError,
                         loading: store.dayData.isLoading,
                         moon: store.dayData.moon,
                         now: now,
                         placeName: place.name)

                MoonCard(illumination: store.dayData.moon,
                         times: store.dayData.moonTimes,
                         now: now)

                EphemerisCard(ephemeris: ephemeris)

                if !store.birthdays(on: now).isEmpty || !store.upcomingBirthdays().isEmpty {
                    BirthdayCard(today: store.birthdays(on: now),
                                 upcoming: store.upcomingBirthdays())
                }

                LightCard(sun: store.dayData.sun, now: now)

                SolunarCard(periods: store.dayData.solunar,
                            rating: Solunar.dayRating(for: now),
                            now: now)

                Color.clear.frame(height: Type.tabBarInset + 12)
            }
            .padding(.horizontal, 20)
        }
        .background(Ink.chassis)
        .refreshable { await store.refreshDay(force: true) }
        .onReceive(clock) { now = $0 }
        .sheet(isPresented: $showPlacePicker) {
            PlacePicker().environment(store)
        }
    }
}

// MARK: - Choix du lieu

struct PlacePicker: View {
    @Environment(Store.self) private var store
    @Environment(LocationProvider.self) private var location
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var ports: [Place] {
        guard !query.isEmpty else { return ReferencePorts.all }
        return ReferencePorts.all.filter {
            $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .contains(query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current))
        }
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    Toggle("Suivre ma position", isOn: $store.settings.followLocation)
                        .onChange(of: store.settings.followLocation) { _, on in
                            if on { location.request() }
                            store.scheduleSave()
                        }
                    if let current = location.lastPlace {
                        Button {
                            select(current)
                        } label: {
                            Label(current.name, systemImage: "location.fill")
                        }
                    }
                    if let message = location.errorMessage {
                        Text(message).font(Type.ui(12)).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Position")
                } footer: {
                    Text("Le lieu détermine le lever et le coucher du soleil, la lune, la météo et la marée.")
                }

                Section {
                    ForEach(ports) { port in
                        Button {
                            select(port)
                        } label: {
                            HStack {
                                Text(port.name)
                                Spacer()
                                if store.settings.place.name == port.name {
                                    Image(systemName: "checkmark").foregroundStyle(Ink.amberDeep)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Ports de référence")
                } footer: {
                    Text("Utile quand vous n’êtes pas sur la côte : la marée est alors donnée pour le port choisi.")
                }

                Section {
                    Button("Utiliser le port le plus proche pour la marée") {
                        store.settings.tidePort = ReferencePorts.nearest(to: store.settings.place)
                        store.scheduleSave()
                        Task { await store.refreshDay(force: true) }
                        dismiss()
                    }
                    if store.settings.tidePort != nil {
                        Button("Détacher le port de marée", role: .destructive) {
                            store.settings.tidePort = nil
                            store.scheduleSave()
                            Task { await store.refreshDay(force: true) }
                        }
                    }
                } header: {
                    Text("Marée")
                }
            }
            .searchable(text: $query, prompt: "Chercher un port")
            .navigationTitle("Lieu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .paperSheet()
    }

    private func select(_ place: Place) {
        store.settings.place = place
        store.settings.followLocation = place.isAutomatic
        // Le port de marée épinglé l'a été comme « le plus proche » du lieu
        // d'alors : il n'a plus de sens une fois qu'on a déménagé. Sans ce
        // report, on changeait de lieu et les heures de marée ne bougeaient
        // pas d'un pouce — sans que rien ne dise pourquoi.
        if store.settings.tidePort != nil {
            store.settings.tidePort = ReferencePorts.nearest(to: place)
        }
        store.scheduleSave()
        Task { await store.refreshDay(force: true) }
        dismiss()
    }
}
