import Foundation
import CoreLocation
import Firebase

typealias JSON = [String: Any]

struct User {
    let userId: UUID
    var location: Location?
    
    init(userId: UUID, _ json: JSON) {
        
        var location: Location? {
            guard let longitude = json["longitude"] as? Double,
                let latitude = json["latitude"] as? Double else { return nil }
            return Location(longitude: longitude, latitude: latitude)
        }

        self.location = location
        self.userId = userId
    }
    
}

struct Location {
    let longitude: Double
    let latitude: Double
    
    var json: JSON {
        return [
            "longitude": longitude,
            "latitude": latitude
        ]
    }
}

protocol LocationManagerUpdateListener: class {
    func locationUpdated(_ location: Location)
}

final class LocationManager: NSObject {
    var lastLocation: Location?
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
        guard let _location = locations.last else { return }
        
        let location = Location(longitude: _location.coordinate.longitude, latitude: _location.coordinate.latitude)
        
        lastLocation = location
        
        document.setData(location.json) { (error) in
            if let error = error {
                print((error as NSError).debugDescription)
            }
        }
        locationManagerUpdateListeners.forEach({ $0.locationUpdated(location) })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startUpdatingLocation()
    }
}
