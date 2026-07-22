import CoreLocation
import Combine

/// Owns only When-In-Use authorization state for the map's native user-location presentation.
/// Per DESIGN_DECISIONS.md Decision 014: no background tracking, no location history,
/// no Always authorization. Permission is requested lazily on first use, never at launch.
@MainActor
final class LocationAuthorizationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let locationManager: CLLocationManager

    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestWhenInUseAuthorizationIfNeeded() {
        guard authorizationStatus == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationAuthorizationService: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
