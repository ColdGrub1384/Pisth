# Getting started

 - Declare an URL scheme for your app, preferably just for importing files. Use an unique URL scheme, it's very important! Don't use URL schemes like "pisth-import", try to include the name of your app, for example: "myApp-pisth-import".
 - Include the Pisth_API framework and Pisth_Shared: Drag the `Pisth API` and `Pisth Shared` projects to your workspace and add them to your app's embedded binary.
 - Add this to your `info.plist`:
 
 ```xml
 <key>LSApplicationQueriesSchemes</key>
 <array>
 <string>pisthapt</string>
 <string>pisth-import</string>
 </array>
 ```

## Opening Pisth APT connection

- Configure the `PisthAPT` instance:

```swift
let pisthAPT = PisthAPT(urlScheme: URL(string: "pisth-api://")! /* This app's URL Scheme */)
```
- Setup the connection:

```swift
let connection = RemoteConnection(host: "coldg.ddns.net", username: "pisthtest", password: "pisth", name: "Pisth Test", path: "~", port: 22, useSFTP: false, os: "Raspbian")
```

- Now, open the connection calling `pisthAPT.open(connection: connection)` and check if Pisth APT is installed with `pisthAPT.canOpen`.

## Importing files from Pisth

- Configure the `Pisth` instance:

```swift
let pisth = Pisth(message: nil /* Default message */, urlScheme: URL(string: "pisth-api://")! /* This app URL scheme */)
```
- Handle data received in your App delegate:

```swift
import Pisth_API

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        // Getting data received
        pisth.receivedFile?.data

        // Getting received file name
        pisth.receivedFile?.filename

    }
}
```
- Now, start importing file calling `pisth.importFile()`. Check if Pisth is installed with `pisth.canOpen`.

