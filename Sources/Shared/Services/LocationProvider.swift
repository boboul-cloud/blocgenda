@preconcurrency import CoreLocation
import Foundation
import Observation

/// Suit la position de l'utilisateur et la traduit en nom de lieu.
/// Précision volontairement réduite : la commune suffit pour les éphémérides.
@Observable
@MainActor
final class LocationProvider: NSObject {
    var authorization: CLAuthorizationStatus = .notDetermined
    var lastPlace: Place?
    var errorMessage: String?

    private let manager = CLLocationManager()
    private var onUpdate: ((Place) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 2000
        authorization = manager.authorizationStatus
    }

    func onPlaceChange(_ handler: @escaping (Place) -> Void) {
        onUpdate = handler
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            errorMessage = "Localisation refusée. Le lieu peut être choisi à la main."
        }
    }

    private func resolve(_ location: CLLocation) {
        Task { @MainActor in
            var name = "Position actuelle"
            if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
                name = placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.administrativeArea
                    ?? placemark.country
                    ?? name
            }
            let place = Place(name: name,
                              latitude: location.coordinate.latitude,
                              longitude: location.coordinate.longitude,
                              isAutomatic: true)
            lastPlace = place
            onUpdate?(place)
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.resolve(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Position indisponible pour le moment."
        }
    }
}
