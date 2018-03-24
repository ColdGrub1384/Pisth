// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import Pisth_Shared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Shared and unique instance.
    static var shared: AppDelegate!
    
    /// Updates.
    var updates = [String]()
    
    /// SSH session.
    var session: NMSSHSession?
    
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        let activityVC = ActivityViewController(message: "Loading...")
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true) {
            self.searchForUpdates()
            activityVC.dismiss(animated: true, completion: nil)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

