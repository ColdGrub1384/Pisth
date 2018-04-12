```swift
var pisth: Pisth!
var pisthAPT: PisthAPT!
```

# AppDelegate

```swift
import UIKit
import Pisth_API

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Setup Pisth API
        pisth = Pisth(message: nil /* Default message */, urlScheme: URL(string: "pisth-api://")! /* This app URL scheme */)
        pisthAPT = PisthAPT(urlScheme: URL(string: "pisth-api://")! /* This app's URL Scheme */)

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        let viewController = (UIApplication.shared.keyWindow?.rootViewController as? ViewController)

        if let data = pisth.dataReceived {
            viewController?.data = data
            if let image = UIImage(data: data) {
                viewController?.imageView.image = image
            }
        }

        if let filename = pisth.filename(fromURL: url) {
            viewController?.filename.text = filename
        }

        return true
    }

}
```

# ViewController

```swift
import UIKit
import Pisth_API
import Pisth_Shared

class ViewController: UIViewController {

    @IBOutlet weak var pisthAPTButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filename: UILabel!

    var data: Data?

    @IBAction func share(_ sender: Any) {

        // Share file

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(filename.text!)
        _ = FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sender as? UIView
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func openPisthAPT(_ sender: Any) {
    
        // Open connection in Pisth APT
        if pisthAPT.canOpen {
            pisthAPT.open(connection: RemoteConnection(host: "coldg.ddns.net", username: "pisthtest", password: "pisth", name: "Pisth Test", path: "~", port: 22, useSFTP: false, os: "Raspbian") /* Connection to open */)
        }
    }

    @IBAction func importFromPisth(_ sender: Any) {

        // Import file
        pisth.importFile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable button only if app can import file from Pisth
        importButton.isEnabled = pisth.canOpen
    }

}

