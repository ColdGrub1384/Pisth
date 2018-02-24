# Getting started

 1. Declare an URL scheme for your app, preferably just for importing files. Use an unique URL scheme, it's very important! Don't use URL schemes like "pisth-import", try to include the name of your app, for example: "myApp-pisth-import".
 2. Include the Pisth API framework: Drag the `Pisth API` and `Pisth_Shared` projects to your workspace and add theme to your app's embedded binary.
 3. Handle data received in your App delegate:

```swift
import Pisth_API

 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {

     // Give your app's URL scheme for importing files.
     Pisth.shared.urlScheme = "<YOUR APP URL SCHEME>"

 }

 func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

     // Getting data received
     Pisth.shared.dataReceived

     // Getting received file name
     Pisth.shared.filename(fromURL: url)

 }
```
4. Now, start importing file calling `Pisth.shared.importFile()`.
