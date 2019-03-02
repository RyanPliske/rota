import Foundation
import CoreLocation

struct Location {
    let longitude: Double
    let latitude: Double
}

protocol LocationManagerUpdateListener: class {
    func locationUpdated(_ location: Location)
}

final class LocationManager: NSObject {
    private var mapListeners = NSMapTable<NSString, AnyObject>.strongToWeakObjects()
    private let manager: CLLocationManager
    
    init(manager: CLLocationManager) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
        self.manager.activityType = .automotiveNavigation
        self.manager.pausesLocationUpdatesAutomatically = false // TODO: handle this better so as to not be a battery hog
        self.manager.allowsBackgroundLocationUpdates = true
    }
    
    static let shared: LocationManager = {
        let manager = CLLocationManager()
        let locationManager = LocationManager(manager: manager)
        locationManager.startUpdatingLocation()
        return locationManager
    }()
    
    private var locationManagerUpdateListeners: [LocationManagerUpdateListener] { return mapListeners.objectEnumerator()?.compactMap { $0 as? LocationManagerUpdateListener } ?? [] }
    
    func addListener(_ locationManagerUpdateListener: LocationManagerUpdateListener) {
        mapListeners.setObject(locationManagerUpdateListener, forKey: UUID().uuidString as NSString?)
    }
    
    private func startUpdatingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case CLAuthorizationStatus.notDetermined:
            manager.requestWhenInUseAuthorization()
        case CLAuthorizationStatus.authorizedAlways, CLAuthorizationStatus.authorizedWhenInUse:
            manager.startUpdatingLocation()
        default: break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        locationManagerUpdateListeners.forEach({ $0.locationUpdated(Location.init(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude)) })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startUpdatingLocation()
    }
}
