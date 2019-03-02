import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.addListener(self)
    }
}

extension ViewController: LocationManagerUpdateListener {
    func locationUpdated(_ location: Location) {
        print(location)
    }
}
