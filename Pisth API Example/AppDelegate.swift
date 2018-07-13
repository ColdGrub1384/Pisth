// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_API

var pisth: Pisth!
var pisthAPT: PisthAPT!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Setup Pisth API
        pisth = Pisth(message: nil /* Default message */, urlScheme: URL(string: "pisth-api://")! /* This app's URL scheme */)
        pisthAPT = PisthAPT(urlScheme: URL(string: "pisth-api://")! /* This app's URL Scheme */)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let viewController = (UIApplication.shared.keyWindow?.rootViewController as? ViewController)
        
        if let file = pisth.receivedFile {
            viewController?.data = file.data
            if let image = UIImage(data: file.data) {
                viewController?.imageView.image = image
            }
            viewController?.filename.text = file.filename
        }
        return true
    }

}

