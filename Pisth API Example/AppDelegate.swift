// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

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

