import Foundation
import CoreLocation
import Firebase

typealias JSON = [String: Any]

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
    private var mapListeners = NSMapTable<NSString, AnyObject>.strongToWeakObjects()
    private let manager: CLLocationManager
    
    private let collection = Firestore.firestore().collection("users")
    private var document: DocumentReference { return collection.document("tplisk") }
    
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
        
        document.setData(location.json)
        
//        collection.getDocuments { (querySnapshot, error) in
//            if let error = error {
//                print("Could not locate document due to error: \(error)")
//                return
//            }
//            guard let documents = querySnapshot?.documents else {
//                print("could not locate documents")
//                return
//            }
//            documents.first?.data()
//        }
        
//        collection.addDocument(data: ["tplisk": location.json])
        
        locationManagerUpdateListeners.forEach({ $0.locationUpdated(location) })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startUpdatingLocation()
    }
}
