// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import Pisth_Shared

/// The app delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Shared and unique instance.
    static var shared: AppDelegate!
    
    /// The app's window.
    var window: UIWindow?
    
    /// Updates.
    var updates = [String]()
    
    /// SSH session.
    var session: NMSSHSession?
    
    /// Search for updates
    func searchForUpdates() {
        // Search for updates
        if let session = session {
            if session.isConnected && session.isAuthorized {
                if let packages = (try? session.channel.execute("aptitude -F%p --disable-columns search ~U").components(separatedBy: "\n")) {
                    self.updates = packages
                    
                    if TabBarController.shared != nil {
                        DispatchQueue.main.async {
                            if self.updates.count != 0 {
                                TabBarController.shared.viewControllers?[2].tabBarItem.badgeValue = "\(self.updates.count)"
                            } else {
                                TabBarController.shared.viewControllers?[2].tabBarItem.badgeValue = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Open the session.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
    
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        // Connect
        if DataManager.shared.connections.indices.contains(UserDefaults.standard.integer(forKey: "connection")) {
            let connection = DataManager.shared.connections[UserDefaults.standard.integer(forKey: "connection")]
            
            if let session = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username) {
                if session.isConnected {
                    session.authenticate(byPassword: connection.password)
                }
                
                self.session = session
            }

        }
        
        return true
    }

    /// Search for updates.
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        let activityVC = ActivityViewController(message: "Loading...")
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true) {
            self.searchForUpdates()
            activityVC.dismiss(animated: true, completion: nil)
        }
    }

}

