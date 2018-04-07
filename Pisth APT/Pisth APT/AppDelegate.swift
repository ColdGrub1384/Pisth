// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import Pisth_Shared
import Pisth_API

let pisth = Pisth(message: "Import DEB package", urlScheme: URL(string:"dpkgPisthInstall://")!)

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
    
    /// Install Deb.
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        guard let vc = UIApplication.shared.keyWindow?.rootViewController else {
            return false
        }
        
        if let data = pisth.dataReceived {
            if let filename = pisth.filename(fromURL: url) {
                if filename.lowercased().hasSuffix(".deb") {
                    
                    let activityVC = ActivityViewController(message: "Uploading...")
                    
                    var success = false
                    
                    vc.present(activityVC, animated: true, completion: {
                        self.session?.sftp.connect()
                        success = self.session?.sftp.writeContents(data, toFileAtPath: "~/\(filename)") ?? false
                        
                        activityVC.dismiss(animated: true, completion: nil)
                    })
                    
                    if success {
                        guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
                            return false
                        }
                        
                        termVC.command = "clear; dpkg -i ~/\(filename); rm ~/\(filename); echo -e \"\\033[CLOSE\""
                        termVC.title = "Installing packages..."
                        
                        let navVC = UINavigationController(rootViewController: termVC)
                        navVC.view.backgroundColor = .clear
                        navVC.modalPresentationStyle = .overCurrentContext
                        
                        vc.present(navVC, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: "Cannot upload file!", message: "Make sure SFTP is enabled and the file is not empty.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        
                        vc.present(alert, animated: true, completion: nil)
                    }
                    
                    return true
                } else {
                    let alert = UIAlertController(title: "Invalid file!", message: "Please select a \"Deb\" file.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    vc.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        return false
    }

}

