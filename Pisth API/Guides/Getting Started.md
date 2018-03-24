# Getting started

 1. Declare an URL scheme for your app, preferably just for importing files. Use an unique URL scheme, it's very important! Don't use URL schemes like "pisth-import", try to include the name of your app, for example: "myApp-pisth-import".
 2. Include the Pisth API framework: Drag the `Pisth API` and `Pisth_Shared` projects to your workspace and add them to your app's embedded binary.
 3. Configure the `Pisth` instance:
```swift
let pisth = Pisth(message: nil /* Default message */, urlScheme: URL(string: "pisth-api://")! /* This app URL scheme */)
```
 4. Handle data received in your App delegate:

```swift
import Pisth_API

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        // Getting data received
        pisth.dataReceived

        // Getting received file name
        pisth.filename(fromURL: url)

    }
}
```
4. Now, start importing file calling `pisth.importFile()`.
