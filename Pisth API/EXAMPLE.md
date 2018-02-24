# AppDelegate

```swift
import UIKit
import Pisth_API

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Set app URL scheme
        Pisth.shared.urlScheme = URL(string: "pisth-api://")


        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if let data = Pisth.shared.dataReceived {
            if let image = UIImage(data: data) {
                (UIApplication.shared.keyWindow?.rootViewController as? ViewController)?.imageView.image = image
            }
        }

        if let filename = Pisth.shared.filename(fromURL: url) {
            (UIApplication.shared.keyWindow?.rootViewController as? ViewController)?.filename.text = filename
        }

        return true
    }

}
```

# ViewController

```swift
import UIKit
import Pisth_API

class ViewController: UIViewController {

    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filename: UILabel!

    @IBAction func importFromPisth(_ sender: Any) {

        // Import file
        Pisth.shared.importFile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable button only if app can import file from Pisth
        importButton.isEnabled = Pisth.shared.canOpen
    }

}

