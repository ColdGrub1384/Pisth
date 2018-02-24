// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Pisth API allows you to import files with Pisth from your own iOS app without extension!
///
/// # Getting started
///
/// 1. Declare an URL scheme for your app, preferably just for importing files. Use an unique URL scheme, it's very important! Don't use URL schemes like "pisth-import", try to include the name of your app, for example: "myApp-pisth-import".
/// 2. Include the Pisth API framework: Drag the `Pisth API` project to your workspace and add it to your app's embedded binary.
/// 3. In your App delegate:
///
///         import Pisth_API
///
///         func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
///
///             // Give your app's URL scheme for importing files.
///             Pisth.shared.urlScheme = "<YOUR APP URL SCHEME>"
///
///         }
///
///         func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
///
///             // Getting data received
///             Pisth.shared.dataReceived
///
///             // Getting received file name
///             Pisth.shared.filename(fromURL: url)
///
///         }
open class Pisth {
    
    /// Unique and shared instance.
    static open let shared = Pisth()
    private init() {}
    
    /// Shared pasteboard.
    open let pasteboard = UIPasteboard(name: .init("pisth-import"), create: true)
    
    /// Imported file data.
    open var dataReceived: Data? {
        return pasteboard?.data(forPasteboardType: "public.data")
    }
    
    /// Pisth URL scheme used to import files.
    open var pisthURLScheme: URL {
        return URL(string: "pisth-import://?scheme=\(urlScheme?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")")!
    }
    
    /// This app URL scheme.
    open var urlScheme: URL?
    
    /// Returns `true` if current application can open Pisth URL scheme.
    open var canOpen: Bool {
        return UIApplication.shared.canOpenURL(pisthURLScheme)
    }
    
    /// Open Pisth and import file.
    ///
    /// This function takes a screenshot of key window and use it as blurred background for Pisth.
    open func importFile() {
        
        // Take screenshot
        
        if let window = UIApplication.shared.keyWindow {
            let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
            
            let screenshot = renderer.image(actions: { context in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            })
            
            pasteboard?.image = screenshot
        }
        
        UIApplication.shared.open(pisthURLScheme, options: [:], completionHandler: nil)
    }
    
    /// Get filename from opened URL.
    open func filename(fromURL url: URL) -> String? {
        return url.queryParameters?["filename"]?.removingPercentEncoding
    }
}
