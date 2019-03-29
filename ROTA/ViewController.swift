import UIKit
import MapKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet private weak var mapView: MKMapView!
    
    private var listener: ListenerRegistration?
    private var shouldZoom = true
    private var hasAddedAnnotations = false
    private var userAnnotations: [UserLocationAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.addListener(self)
        mapView.showsUserLocation = true
        if let lastLocation = LocationManager.shared.lastLocation {
            zoomToMapRegionWithCenter(lastLocation)
        }
        
        listener = collection.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let `self` = self else { return }
            if let error = error {
                print("Could not locate document due to error: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("could not locate documents")
                return
            }
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.userAnnotations = documents
                .compactMap { User(userId: UUID(uuidString: $0.documentID)!, $0.data()) }
                .compactMap { UserLocationAnnotation(title: $0.userId.uuidString, coordinate: CLLocationCoordinate2D(latitude: $0.location!.latitude, longitude: $0.location!.longitude)) }
            self.mapView.addAnnotations(self.userAnnotations)
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is UserLocationAnnotation else { return nil }
        
        guard let userView = mapView.dequeueReusableAnnotationView(withIdentifier: UserLocationAnnotation.reuseId) else {
            let new = MKAnnotationView(annotation: annotation, reuseIdentifier: UserLocationAnnotation.reuseId)
            new.canShowCallout = false
            new.image = UIImage(named: "userLocation")
            new.accessibilityLabel = "userLocation"
            return new
        }

        userView.annotation = annotation
        return userView
    }
}

extension ViewController: LocationManagerUpdateListener {
    func locationUpdated(_ location: Location) {
        zoomToMapRegionWithCenter(location)
    }
}

extension ViewController {
    private func zoomToMapRegionWithCenter(_ center: Location) {
        guard shouldZoom else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let coordinate = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: true)
        shouldZoom = false
    }
}

final class UserLocationAnnotation: NSObject, MKAnnotation {
    static let reuseId = "userLocation"
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        super.init()
    }
}
