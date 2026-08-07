import Foundation

extension Store {

    /// Recalcule tout ce qui concerne la journée : l'astronomie en local et
    /// tout de suite, la marée et la météo par le réseau, en arrière-plan.
    func refreshDay(for date: Date = Date(), force: Bool = false) async {
        let place = settings.place
        let cal = Calendar.current

        let alreadyDone = dayData.computedFor.map { cal.isDate($0, inSameDayAs: date) } ?? false
        if alreadyDone && dayData.computedPlace == place.id && !force { return }

        // 1. Calculs locaux, immédiats.
        dayData.sun = Astro.sunTimes(date: date, lat: place.latitude, lon: place.longitude)
        dayData.moon = Astro.moonIllumination(date: date)
        let mt = Astro.moonTimes(date: date, lat: place.latitude, lon: place.longitude)
        dayData.moonTimes = (mt.rise, mt.set)
        dayData.solunar = Solunar.periods(for: date, lat: place.latitude, lon: place.longitude)
        dayData.computedFor = date
        dayData.computedPlace = place.id

        // 2. Réseau.
        dayData.isLoading = true
        dayData.tideError = nil

        async let weather = try? WeatherService.fetch(place: place)
        let tideResult = await loadTide(for: settings.tideReference, fallbackFrom: place)

        dayData.weather = await weather
        dayData.tide = tideResult.day
        dayData.tideError = tideResult.error
        if let marks = tideResult.day?.marks {
            await Notifications.scheduleTide(marks: marks, settings: settings)
        }
        dayData.isLoading = false
        refreshWidget()
    }

    private func loadTide(for place: Place,
                          fallbackFrom origin: Place) async -> (day: TideDay?, error: String?) {
        do {
            return (try await TideService.fetch(place: place), nil)
        } catch {
            // Hors couverture maritime : on bascule sur le port le plus proche,
            // en le signalant clairement dans l'interface.
            guard settings.tidePort == nil else {
                return (nil, (error as? LocalizedError)?.errorDescription ?? "Marées indisponibles.")
            }
            let nearest = ReferencePorts.nearest(to: origin)
            if var day = try? await TideService.fetch(place: nearest) {
                day.portName = nearest.name
                return (day, nil)
            }
            return (nil, "Marées indisponibles pour ce lieu.")
        }
    }
}
