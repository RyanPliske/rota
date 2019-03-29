import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            print("App Library Location: \(libraryDirectory.absoluteString)")
        }
        FirebaseApp.configure()
        return true
    }
}

