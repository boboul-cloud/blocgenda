import Foundation

extension Store {

    /// Recalcule tout ce qui concerne la journée : l'astronomie en local et
    /// tout de suite, la marée et la météo par le réseau, en arrière-plan.
    func refreshDay(for date: Date = Date(), force: Bool = false) async {
        let place = settings.place
        let cal = Calendar.current

        // La clé retient le lieu *et* le port de marée : ils peuvent changer
        // l'un sans l'autre, et un relevé déjà fait pour l'un ne vaut pas pour
        // l'autre.
        let key = "\(place.id)#\(settings.tideReference.id)"
        let alreadyDone = dayData.computedFor.map { cal.isDate($0, inSameDayAs: date) } ?? false
        if alreadyDone && dayData.computedPlace == key && !force { return }

        // 1. Calculs locaux, immédiats.
        dayData.sun = Astro.sunTimes(date: date, lat: place.latitude, lon: place.longitude)
        dayData.moon = Astro.moonIllumination(date: date)
        let mt = Astro.moonTimes(date: date, lat: place.latitude, lon: place.longitude)
        dayData.moonTimes = (mt.rise, mt.set)
        dayData.solunar = Solunar.periods(for: date, lat: place.latitude, lon: place.longitude)
        dayData.computedFor = date
        dayData.computedPlace = key

        // 2. Réseau.
        dayData.isLoading = true
        dayData.tideError = nil

        async let weather = try? WeatherService.fetch(place: place)
        let reference = settings.tideReference
        let outcome = await loadTide(for: reference, fallbackFrom: place)

        dayData.weather = await weather
        switch outcome {
        case .fresh(let day):
            dayData.tide = day
            dayData.tideError = nil
            await Notifications.scheduleTide(marks: day.marks, settings: settings)

        case .failed(let message):
            // On garde la courbe déjà affichée si elle vaut encore pour ce
            // port : un rafraîchissement manqué ne doit pas effacer des heures
            // justes. Elle ne vaut plus dès que le port a changé — mieux vaut
            // rien que la marée d'ailleurs sous un autre nom.
            let encoreValable = [reference.name, ReferencePorts.nearest(to: place).name]
            if let shown = dayData.tide?.portName, !encoreValable.contains(shown) {
                dayData.tide = nil
            }
            dayData.tideError = message

        case .interrupted:
            // Geste relâché, écran quitté : on ne touche à rien.
            break
        }
        dayData.isLoading = false
        refreshWidget()
    }

    private enum TideOutcome {
        case fresh(TideDay)
        case failed(String)
        case interrupted
    }

    private func loadTide(for place: Place, fallbackFrom origin: Place) async -> TideOutcome {
        do {
            return .fresh(try await TideService.fetch(place: place))
        } catch TideService.TideError.cancelled {
            return .interrupted
        } catch TideService.TideError.noCoverage {
            // Hors couverture maritime — et seulement dans ce cas : on bascule
            // sur le port le plus proche. Réessayer ailleurs après une panne de
            // réseau ne ferait qu'un second appel condamné.
            guard settings.tidePort == nil else {
                return .failed(TideService.TideError.noCoverage.errorDescription ?? "Marées indisponibles.")
            }
            let nearest = ReferencePorts.nearest(to: origin)
            if var day = try? await TideService.fetch(place: nearest) {
                day.portName = nearest.name
                return .fresh(day)
            }
            return .failed("Marées indisponibles pour ce lieu.")
        } catch {
            return .failed((error as? LocalizedError)?.errorDescription ?? "Marées indisponibles.")
        }
    }
}
