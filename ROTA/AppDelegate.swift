import UIKit
import Firebase

var collection: CollectionReference!
var userId: UUID!
var document: DocumentReference { return collection.document(userId.uuidString) }

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            print("App Library Location: \(libraryDirectory.absoluteString)")
        }
        FirebaseApp.configure()
        collection = Firestore.firestore().collection("users")
        userId = UIDevice.current.identifierForVendor!
        return true
    }
}

