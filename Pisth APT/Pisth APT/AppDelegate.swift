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
import Firebase

/// Pisth API object
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
    
    /// Connection opened.
    var connection: RemoteConnection?
    
    /// The user's home directory.
    var homeDirectory: String?
    
    /// Reason to open the app.
    var openReason = OpenReason.default
    
    /// URL of app that opened this app with the API.
    var apiURL: URL?
    
    /// Close connection opened with the API.
    @objc func goToPreviousApp() {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: {
            if let url = self.apiURL {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { (success) in
                    if success {
                        UIApplication.shared.keyWindow?.tintColor = UIView().tintColor
                        self.openReason = .default
                        TabBarController.shared.customConnection = nil
                        self.session?.disconnect()
                        self.shellSession?.disconnect()
                        self.session = nil
                        self.shellSession = nil
                        self.allPackages = []
                        self.installed = []
                        self.updates = []
                        
                        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                            let activityVC = ActivityViewController(message: "Loading...")
                            UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: {
                                self.connect()
                                self.searchForUpdates(completion: {
                                    activityVC.dismiss(animated: true, completion: nil)
                                })
                            })
                        })
                    }
                })
            }
        })
    }
    
    /// Open the session.
    func connect() {
        
        func noConnection() {
            
            guard openReason != .openConnection else {
                return
            }
            
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
        
        // Connect
        if DataManager.shared.connections.indices.contains(UserDefaults.standard.integer(forKey: "connection")) || openReason == .openConnection {
            
            var connection: RemoteConnection!
            
            if TabBarController.shared?.customConnection != nil && openReason == .openConnection {
                connection = TabBarController.shared?.customConnection
            } else if DataManager.shared.connections.indices.contains(UserDefaults.standard.integer(forKey: "connection")) {
                connection = DataManager.shared.connections[UserDefaults.standard.integer(forKey: "connection")]
            } else {
                noConnection()
                return
            }
            
            self.connection = connection
            
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
                if let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "error") as? ErrorViewController {
                    _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                        UIApplication.shared.keyWindow?.rootViewController = vc
                        vc.errorLabel?.text = error
                        vc.errorTitleLabel?.text = errorTitle
                    })
                }
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
            noConnection()
        }
    }
    
    /// Search for updates
    ///
    /// - Parameters:
    ///     - completion: Optional block to execute after updating data.
    func searchForUpdates(completion: (() -> ())? = nil) {
        // Search for updates
        if let session = session {
            if session.isConnected && session.isAuthorized {
                
                guard let result = (try? session.channel.execute("echo $HOME; echo '__PisthAPT__Data__'; aptitude -F%p --disable-columns search ~U; echo '__PisthAPT__Data__'; apt-mark showmanual; echo '__PisthAPT__Data__'; apt-cache search .")) else {
                    return
                }
                
                let components = result.components(separatedBy: "__PisthAPT__Data__")
                
                guard components.count == 4 else {
                    return
                }
                
                self.homeDirectory = components[0].replacingOccurrences(of: "\n", with: "")

                var packages = components[1].components(separatedBy: "\n")
                if packages.first == "" {
                    packages.removeFirst()
                }
                
                self.updates = packages
                self.updates.removeLast()
                
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
                
                var installed = components[2].components(separatedBy: "\n")
                if installed.first == "" {
                    installed.removeFirst()
                }
                
                self.installed = installed
                self.installed.removeLast()
                    
                DispatchQueue.main.async {
                    if let tableView = ((TabBarController.shared.viewControllers?[1] as? UINavigationController)?.topViewController as? InstalledTableViewController)?.tableView {
                        tableView.reloadData()
                    }
                }
                
                var allPackages = components[3].components(separatedBy: "\n")
                if allPackages.first == "" {
                    allPackages.removeFirst()
                }
                
                self.allPackages = allPackages
                self.allPackages.removeLast()
                
                if let tableView = ((TabBarController.shared.viewControllers?[0] as? UINavigationController)?.topViewController as? PackagesTableViewController)?.tableView {
                    tableView.reloadData()
                }
            }
        }
        
        completion?()
    }
    
    // MARK: - Application delegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
    
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            self.connect()
        })
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            if self.openReason != .openConnection {
                // Search for updates
                let activityVC = ActivityViewController(message: "Loading...")
                UIApplication.shared.keyWindow?.topViewController()?.present(activityVC, animated: true) {
                    self.searchForUpdates()
                    activityVC.dismiss(animated: true, completion: nil)
                }
            }
        })
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        guard let vc = UIApplication.shared.keyWindow?.rootViewController else {
            return false
        }
        
        if url.absoluteString.hasPrefix("pisthapt:") { // Open connection from the API
            
            openReason = .openConnection
            
            if let scheme = url.queryParameters?["scheme"]?.removingPercentEncoding {
                apiURL = URL(string: scheme)
            }
            
            guard let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() as? TabBarController else {
                return false
            }
            
            viewController.modalTransitionStyle = .crossDissolve
            viewController.viewControllers?.removeLast()
            
            TabBarController.shared = viewController
            
            if let data = UIPasteboard.general.data(forPasteboardType: "public.data") {
                if let connection = NSKeyedUnarchiver.unarchiveObject(with: data) as? RemoteConnection {
                    
                    guard connection != self.connection else {
                        return true
                    }
                    
                    viewController.customConnection = connection
                    
                    guard let connectingVC = Bundle.main.loadNibNamed("Connecting", owner: nil, options: nil)?[0] as? ConnectingViewController else {
                        return false
                    }
                    
                    connectingVC.connection = connection
                    
                    UIApplication.shared.keyWindow?.topViewController()?.present(connectingVC, animated: true, completion: {
                        
                        self.connect()
                        
                        if let session = self.session, session.isConnected {
                            
                            self.searchForUpdates()
                            
                            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                                if let tintColor = url.queryParameters?["tintColor"]?.removingPercentEncoding {
                                    if let color = UIColor(hexString: tintColor) {
                                        UIApplication.shared.keyWindow?.tintColor = color
                                    }
                                }
                                
                                connectingVC.present(viewController, animated: true, completion: {
                                    for vc in viewController.viewControllers ?? [] {
                                        (vc as? UINavigationController)?.visibleViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goToPreviousApp))
                                    }
                                })
                            })
                        }
                    })
                }
            }
        } else if let file = pisth.receivedFile { // Import file with the API
            
            openReason = .installDeb
            
            let filename = file.filename
            if filename.lowercased().hasSuffix(".deb") {
                
                let activityVC = ActivityViewController(message: "Uploading...")
                
                var success = false
                
                let localFilePath = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("PisthDEBInstall.deb").path
                
                vc.present(activityVC, animated: true, completion: {
                    
                    FileManager.default.createFile(atPath: localFilePath, contents: file.data, attributes: nil)
                    print("\(self.homeDirectory ?? "")/PisthDEBInstall.deb")
                    success = self.session?.channel.uploadFile(localFilePath, to: "\(self.homeDirectory ?? "")/PisthDEBInstall.deb") ?? false
                    
                    try? FileManager.default.removeItem(atPath: localFilePath)
                    
                    activityVC.dismiss(animated: true, completion: {
                        
                        if success {
                            guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
                                return
                            }
                            
                            termVC.command = "clear; sudo dpkg -i ~/PisthDEBInstall.deb; rm ~/PisthDEBInstall.deb; echo -e \"\\033[CLOSE\""
                            termVC.title = "Installing packages..."
                            
                            let navVC = UINavigationController(rootViewController: termVC)
                            navVC.modalPresentationStyle = .formSheet
                            
                            vc.present(navVC, animated: true, completion: nil)
                        } else {
                            let alert = UIAlertController(title: "Cannot upload file!", message: "Make sure the file is not empty.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            
                            vc.present(alert, animated: true, completion: nil)
                        }
                        
                    })
                })
                
                return true
            } else {
                let alert = UIAlertController(title: "Invalid file!", message: "Please select a \"Deb\" file.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                vc.present(alert, animated: true, completion: nil)
            }
        }
        
        return false
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
