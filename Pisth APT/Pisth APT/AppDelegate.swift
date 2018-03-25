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
    
    /// Updates available.
    var updates = [String]()
    
    /// Installed packages.
    var installed = [String]()
    
    /// All available packages with name and description.
    var allPackages = [String]()
    
    /// SSH session.
    var session: NMSSHSession?
    
    /// Session used for the shell
    var shellSession: NMSSHSession?
    
    /// Open the session.
    func connect() {
        // Connect
        if DataManager.shared.connections.indices.contains(UserDefaults.standard.integer(forKey: "connection")) {
            let connection = DataManager.shared.connections[UserDefaults.standard.integer(forKey: "connection")]
            
            let errorTitle = "Error opening the session!"
            var error: String?
            
            if let session = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username) {
                if session.isConnected {
                    session.authenticate(byPassword: connection.password)
                    
                    if session.isAuthorized {
                        try? session.channel.startShell()
                    } else {
                        error = "There was an error trying to login as '\(connection.username)'. Check for the username and for the password."
                    }
                } else {
                    error = "There was an error trying to connect to the server, check for the connection IP address and for your internet connection."
                }
                
                self.session = session
            }
            
            if error != nil {
                _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                    if let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "error") as? ErrorViewController {
                        UIApplication.shared.keyWindow?.rootViewController = vc
                        vc.errorLabel.text = error
                        vc.errorTitleLabel.text = errorTitle
                    }
                })
            }
            
            if let session = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username) {
                if session.isConnected {
                    session.authenticate(byPassword: connection.password)
                    
                    if session.isAuthorized {
                        session.channel.requestPty = true
                        session.channel.ptyTerminalType = .xterm
                        try? session.channel.startShell()
                    }
                }
                
                self.shellSession = session
            }
            
        } else {
            // No connection
            
            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                if let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "error") as? ErrorViewController {
                    UIApplication.shared.keyWindow?.rootViewController = vc
                    vc.errorTitleLabel.text = "No connection"
                    vc.errorLabel.text = "Setup an SSH connection in settings."
                    vc.errorView.backgroundColor = .orange
                    vc.retryButton.isHidden = true
                }
            })
        }
    }
    
    /// Search for updates
    func searchForUpdates() {
        // Search for updates
        if let session = session {
            if session.isConnected && session.isAuthorized {
                if let packages = (try? session.channel.execute("aptitude -F%p --disable-columns search ~U").components(separatedBy: "\n")) {
                    self.updates = packages
                    
                    if TabBarController.shared != nil {
                        DispatchQueue.main.async {
                            if let tableView = ((TabBarController.shared.viewControllers?[2] as? UINavigationController)?.topViewController as? UpdatesTableViewController)?.tableView {
                                tableView.reloadData()
                            }
                            if self.updates.count > 1 {
                                TabBarController.shared.viewControllers?[2].tabBarItem.badgeValue = "\(self.updates.count-1)"
                            } else {
                                TabBarController.shared.viewControllers?[2].tabBarItem.badgeValue = nil
                            }
                        }
                    }
                }
                
                if let installed = (try? session.channel.execute("apt-mark showmanual").components(separatedBy: "\n")) {
                    self.installed = installed
                    
                    DispatchQueue.main.async {
                        if let tableView = ((TabBarController.shared.viewControllers?[1] as? UINavigationController)?.topViewController as? InstalledTableViewController)?.tableView {
                            tableView.reloadData()
                        }
                    }
                }
                
                if let allPackages = (try? session.channel.execute("apt-cache search .").components(separatedBy: "\n")) {
                    self.allPackages = allPackages
                    
                    if let tableView = ((TabBarController.shared.viewControllers?[0] as? UINavigationController)?.topViewController as? PackagesTableViewController)?.tableView {
                        tableView.reloadData()
                    }
                }
            }
        }
    }
    
    /// Open the session.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
    
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        connect()
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            // Search for updates
            let activityVC = ActivityViewController(message: "Loading...")
            UIApplication.shared.keyWindow?.topViewController()?.present(activityVC, animated: true) {
                self.searchForUpdates()
                activityVC.dismiss(animated: true, completion: nil)
            }
        })
        
        return true
    }

}

