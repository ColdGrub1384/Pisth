// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import CoreData
import GoogleMobileAds
import SwiftKeychainWrapper
import SwiftyStoreKit
import Pisth_Shared
import Firebase
import Pisth_API

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryCollectionViewControllerDelegate, BookmarksTableViewControllerDelegate, LocalDirectoryCollectionViewControllerStaticDelegate, UISplitViewControllerDelegate {
    
    /// The window used with app.
    var window: UIWindow?
    
    /// Message from Pisth API.
    var importReason: String?
    
    /// Action to do when opening the app with an URL scheme.
    var action: AppAction?
        
    /// The shared Navigation controller used in the app.
    var navigationController = UINavigationController()
    
    /// The shared Split view controller used in the app.
    var splitViewController = SplitViewController()
    
    /// An instance of DirectoryCollectionViewController to be used to upload files from the share menu.
    var directoryCollectionViewController: DirectoryCollectionViewController?
    
    /// The file opened from share menu.
    var openedFile: URL?
    
    /// URL scheme of app that is using Pisth API and opened the URL scheme.
    var dataReceiverAppURLScheme: URL!
    
    /// Go back to app that opened the URL scheme.
    @objc func goToPreviousApp() {
        window?.rootViewController?.dismiss(animated: true, completion: {
            
            if self.dataReceiverAppURLScheme != nil {
                UIApplication.shared.open(self.dataReceiverAppURLScheme!, options: [:], completionHandler: nil)
            }
        })
    }
    
    /// Upload file at directory opened in `directoryCollectionViewController`.
    @objc func uploadFile() {
        if let directoryCollectionViewController = directoryCollectionViewController {
            if let file = openedFile {
                directoryCollectionViewController.localDirectoryCollectionViewController(LocalDirectoryCollectionViewController(directory: FileManager.default.documents), didOpenFile: file)
            }
        }
    }
    
    /// Dismiss app's Root View Controller and cancel file upload.
    /// Called did close the BookmarksTableViewController opened when upload a file.
    @objc func close() {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.dismiss(animated: true, completion: {
                self.openedFile = nil
                self.directoryCollectionViewController = nil
            })
        }
    }
    
    /// Show a `CompactBookmarksTableViewController` from compact window or show it from the left.
    @objc func showBookmarks() {
        
        if !splitViewController.isCollapsed {
            let button = AppDelegate.shared.splitViewController.displayModeButtonItem
            _ = button.target?.perform(button.action)
        } else {
            let navVC = UINavigationController(rootViewController: CompactBookmarksTableViewController())
            navVC.navigationBar.barStyle = .black
            navVC.modalPresentationStyle = .overCurrentContext
            navVC.view.backgroundColor = .clear
            navVC.modalTransitionStyle = .crossDissolve
            UIApplication.shared.keyWindow?.rootViewController?.present(navVC, animated: true, completion: nil)
        }
    }
    
    /// A Bar button item to show bookmarks from an active connection.
    ///
    /// Returns each time a new instance.
    var showBookmarksBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: "Bookmarks", style: .done, target: self, action: #selector(showBookmarks))
    }
    
    /// Update 3D touch shortucts from connections.
    func update3DTouchShortucts() {
        
        var shortcuts = [UIApplicationShortcutItem]()
        
        var i = 0
        for connection in DataManager.shared.connections {
            var icon: UIApplicationShortcutIcon {
                if connection.useSFTP {
                    return UIApplicationShortcutIcon(templateImageName: "folder black")
                } else {
                    return UIApplicationShortcutIcon(templateImageName: "shell")
                }
            }
            
            var title: String {
                if connection.name == "" {
                    return "\(connection.username)@\(connection.host)"
                } else {
                    return connection.name
                }
            }
            
            var subtitle: String? {
                if connection.name == "" {
                    return nil
                } else {
                    return "\(connection.username)@\(connection.host)"
                }
            }
            
            shortcuts.append(UIApplicationShortcutItem.init(type: "connection \(i)", localizedTitle: title, localizedSubtitle: subtitle, icon: icon, userInfo: nil))
            
            i += 1
        }
        
        UIApplication.shared.shortcutItems = shortcuts
    }
    
    // MARK: - Application delegate
    
    /// Initialize app's window, and setup / repair saved data.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        UIMenuController.shared.menuItems = [
            .init(title: "Delete", action: #selector(FileCollectionViewCell.deleteFile(_:))),
            .init(title: "Move", action: #selector(FileCollectionViewCell.moveFile(_:))),
            .init(title: "Rename", action: #selector(FileCollectionViewCell.renameFile(_:))),
            .init(title: "Info", action: #selector(FileCollectionViewCell.showFileInfo(_:))),
            .init(title: "Share", action: #selector(FileCollectionViewCell.shareFile(_:))),
            .init(title: "Open in new panel", action: #selector(FileCollectionViewCell.openInNewPanel(_:))),
            .init(title: "Selection mode", action: #selector(TerminalViewController.selectionMode)),
            .init(title: "Insert mode", action: #selector(TerminalViewController.insertMode)),
            .init(title: "Paste", action: #selector(TerminalViewController.pasteText)),
            .init(title: "Toggle top bar", action: #selector(TerminalViewController.showNavBar)),
            .init(title: "Paste selection", action: #selector(TerminalViewController.pasteSelection))
        ]
        UIMenuController.shared.update()
        
        DataManager.shared.saveCompletion = update3DTouchShortucts
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController.content
        window?.makeKeyAndVisible()
        GADBannerView.appearance().ignoresInvertColors = true
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9214899206650515~2846344793")
        
        // Firebase analytics
        FirebaseApp.configure()
        
        // Save passwords to keychain if they are not
        // See how passwords are managed since 3.0 at 'Helpers/DataManager.swift'
        if !UserDefaults.standard.bool(forKey: "savedToKeychain") {
            // Update data to be compatible with 3.0
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
            request.returnsObjectsAsFaults = false
            
            do {
                let results = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                
                for result in results {
                    let passKey = String.random(length: 100)
                    if let password = result.value(forKey: "password") as? String {
                        SwiftKeychainWrapper.KeychainWrapper.standard.set(password, forKey: passKey)
                    }
                    result.setValue(passKey, forKey: "password")
                }
                
                try? DataManager.shared.coreDataContext.save()
            } catch let error {
                print("Error retrieving connections: \(error.localizedDescription)")
            }
            
            UserDefaults.standard.set(true, forKey: "savedToKeychain")
            UserDefaults.standard.synchronize()
        }
        
        // Add 'sftp' attributes to saved connections if there are not
        // 'sftp' attribute was added in 5.1
        if !UserDefaults.standard.bool(forKey: "addedSftpAttribute") {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
            request.returnsObjectsAsFaults = false
            
            do {
                let results = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                
                for result in results {
                    if result.value(forKey: "sftp") == nil {
                        result.setValue(true, forKey: "sftp")
                    }
                }
                
                try? DataManager.shared.coreDataContext.save()
            } catch let error {
                print("Error retrieving connections: \(error.localizedDescription)")
            }
            
            UserDefaults.standard.setValue(true, forKey: "addedSftpAttribute")
            UserDefaults.standard.synchronize()
        }
        
        // Set default terminal theme
        if UserDefaults.standard.string(forKey: "terminalTheme") == nil || !UserDefaults.standard.bool(forKey: "terminalThemesPurchased") {
            UserDefaults.standard.set("Pisth", forKey: "terminalTheme")
            UserDefaults.standard.synchronize()
        }
        
        // Setup 3D touch shortcuts
        AppDelegate.shared.update3DTouchShortucts()
        
        // Blink cursor by default
        if UserDefaults.standard.value(forKey: "blink") == nil {
            UserDefaults.standard.set(true, forKey: "blink")
            UserDefaults.standard.synchronize()
        }
        
        // Use Xcode theme by default
        if UserDefaults.standard.value(forKey: "editorTheme") == nil {
            UserDefaults.standard.set("xcode", forKey: "editorTheme")
            UserDefaults.standard.synchronize()
        }
        
        // Set default terminal text size
        if UserDefaults.standard.value(forKey: "terminalTextSize") == nil || UserDefaults.standard.integer(forKey: "terminalTextSize") == 0 {
            UserDefaults.standard.set(15, forKey: "terminalTextSize")
            UserDefaults.standard.synchronize()
        }
        
        // Create plugins directory
        let pluginsDir = FileManager.default.library.appendingPathComponent("Plugins")
        if !FileManager.default.fileExists(atPath: pluginsDir.path) {
            try? FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: false, attributes: nil)
        }
        
        // Remove temporary files
        for file in (try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())) ?? [] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: NSTemporaryDirectory().nsString.appendingPathComponent(file)))
        }
        
        // Finish transactions
        SwiftyStoreKit.completeTransactions(atomically: false) { (purchases) in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    
                    if purchase.productId == ProductsID.themes.rawValue {
                        UserDefaults.standard.set(true, forKey: "terminalThemesPurchased")
                        UserDefaults.standard.synchronize()
                    }
                case .failed, .purchasing, .deferred:
                    break
                }
            }
        }
        
        // Unlock Terminal Themes with the `--iap` or `-i` argument
        if CommandLine.arguments.contains("--iap") || CommandLine.arguments.contains("-i") {
            UserDefaults.standard.set(true, forKey: "terminalThemesPurchased")
            UserDefaults.standard.synchronize()
        }
        
        // Buy themes from App Store
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            return (product.productIdentifier == ProductsID.themes.rawValue && !UserDefaults.standard.bool(forKey: "terminalThemesPurchased"))
        }
        
        // Initiliaze iAP products
        Product.initProducts()
        
        // Request app review
        ReviewHelper.shared.launches += 1
        ReviewHelper.shared.requestReview()
        
        return true
    }
    
    /// Open file, upload file or open connection.
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        /// Handle URL.
        func handle() {
            if url.absoluteString.hasPrefix("ssh:") || url.absoluteString.hasPrefix("sftp:") || url.absoluteString.hasPrefix("pisthssh:") || url.absoluteString.hasPrefix("pisthsftp:") { // Open connection.
                let connection = url.absoluteString.components(separatedBy: "://")[1]
                
                var host: String {
                    
                    let components = connection.components(separatedBy: "@")
                    
                    if components.indices.contains(1) {
                        return components[1].components(separatedBy: ":")[0]
                    }
                    
                    return components[0].components(separatedBy: ":")[0]
                }
                
                var user: String {
                    let user_ = connection.components(separatedBy: "@")[0].components(separatedBy: ":")[0]
                    
                    if user_ != host {
                        return user_
                    }
                    
                    return ""
                }
                
                var port: String {
                    
                    let components = connection.components(separatedBy: ":")
                    
                    if components.indices.contains(1) {
                        return components[1]
                    }
                    
                    return ""
                }
                
                let alert = UIAlertController(title: "Open SSH connection", message: "Authenticate as \(user) user.", preferredStyle: .alert)
                
                var userTextField: UITextField? {
                    if alert.textFields?.count == 2 {
                        return alert.textFields?[0]
                    } else {
                        return nil
                    }
                }
                
                var passwordTextField: UITextField? {
                    if alert.textFields?.count == 2 {
                        return alert.textFields?[1]
                    } else {
                        return alert.textFields?[0]
                    }
                }
                
                if user.isEmpty {
                    alert.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = "Username"
                    })
                }
                
                func connect(withPassword password: String) {
                    let activityVC = ActivityViewController(message: "Loading...")
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: {
                        let connection = RemoteConnection(host: host, username: userTextField?.text ?? user, password: password, publicKey: options[.init("publicKey")] as? String, privateKey: options[.init("privateKey")] as? String, name: "", path: (options[.init("path")] as? String) ?? "~", port: UInt64(port) ?? 22, useSFTP: (url.absoluteString.hasPrefix("sftp:") || url.absoluteString.hasPrefix("pisthsftp:")), os: nil)
                        
                        ConnectionManager.shared.session = nil
                        ConnectionManager.shared.filesSession = nil
                        ConnectionManager.shared.result = .notConnected
                        
                        if !connection.useSFTP { // SSH
                            
                            ConnectionManager.shared.connection = connection
                            ConnectionManager.shared.connect()
                            
                            let terminalVC = TerminalViewController()
                            terminalVC.pureMode = true
                            
                            activityVC.dismiss(animated: true, completion: {
                                
                                self.splitViewController.setDisplayMode()
                                
                                self.navigationController.setViewControllers([terminalVC], animated: true)
                            })
                        } else {
                            
                            let dirVC = DirectoryCollectionViewController(connection: connection)
                            
                            activityVC.dismiss(animated: true, completion: {
                                
                                self.splitViewController.setDisplayMode()
                                
                                self.navigationController.setViewControllers([dirVC], animated: true)
                            })
                        }
                    })
                }
                
                if let password = options[.init("password")] as? String {
                    connect(withPassword: password)
                } else {
                    alert.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = "Password"
                        textField.isSecureTextEntry = true
                    })
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "Connect", style: .default, handler: { (_) in
                        connect(withPassword: passwordTextField?.text ?? "")
                    }))
                    alert.addAction(UIAlertAction(title: "Connect and remember", style: .default, handler: { (_) in
                        let connection = RemoteConnection(host: host, username: userTextField?.text ?? user, password: passwordTextField?.text ?? "", publicKey: options[.init("publicKey")] as? String, privateKey: options[.init("privateKey")] as? String, name: "", path: (options[.init("path")] as? String) ?? "~", port: UInt64(port) ?? 22, useSFTP: (url.absoluteString.hasPrefix("sftp:") || url.absoluteString.hasPrefix("pisthsftp:")), os: nil)
                        DataManager.shared.addNew(connection: connection)
                        connect(withPassword: connection.password)
                    }))
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            } else if url.absoluteString.hasPrefix("file:") { // Upload file or import plugin or theme.
                
                if url.pathExtension.lowercased() == "termplugin" { // Import plugin
                    
                    let alert = UIAlertController(title: "Use plugin?", message: "Do you want to use this terminal plugin? This plugin will have access to all the content of the terminal, I recommend to view the content of the plugin in the settings before using it. You can disable it from settings.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Use plugin", style: .destructive, handler: { (_) in
                        var pluginURL = FileManager.default.library.appendingPathComponent("Plugins").appendingPathComponent(url.lastPathComponent)
                        
                        var i = 1
                        while FileManager.default.fileExists(atPath: pluginURL.path) {
                            pluginURL = pluginURL.deletingLastPathComponent().appendingPathComponent("\(url.lastPathComponent)-\(i).\(url.pathExtension)")
                            
                            i += 1
                        }
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: pluginURL)
                        } catch {
                            let alert = UIAlertController(title: "Error copying file!", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                            
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    
                }
                
                // Upload file
                
                action = .upload
                
                openedFile = url
                
                // Open a BookmarksTableViewController to select where upload the file
                
                let bookmarksVC = BookmarksTableViewController()
                let navVC = UINavigationController(rootViewController: bookmarksVC)
                navVC.navigationBar.prefersLargeTitles = true
                navigationController.present(navVC, animated: true, completion: {
                    bookmarksVC.delegate = self
                    bookmarksVC.navigationItem.largeTitleDisplayMode = .never
                    bookmarksVC.navigationItem.setLeftBarButtonItems([], animated: true)
                    bookmarksVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.close))], animated: true)
                    bookmarksVC.navigationItem.prompt = "Select connection where upload file"
                })
            } else if url.absoluteString.hasPrefix("pisth-import:") { // Export file with the API
                
                LocalDirectoryCollectionViewController.delegate = self
                
                action = .apiImport
                
                if let scheme = url.queryParameters?["scheme"]?.removingPercentEncoding {
                    dataReceiverAppURLScheme = URL(string: scheme)
                }
                
                importReason = url.queryParameters?["message"]?.removingPercentEncoding
                
                // Open a BookmarksTableViewController to select file to export
                
                let bookmarksVC = BookmarksTableViewController()
                
                if let backgroundImage = UIPasteboard.general.image {
                    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                    let imageView = UIImageView(image: backgroundImage)
                    imageView.ignoresInvertColors = true
                    let containerView = UIView()
                    containerView.addSubview(imageView)
                    containerView.addSubview(blurView)
                    
                    bookmarksVC.tableView.backgroundView = containerView
                    
                    blurView.frame.size = bookmarksVC.tableView.frame.size
                    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageView.frame.size = bookmarksVC.tableView.frame.size
                    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    
                    bookmarksVC.tableView.backgroundColor = .clear
                }
                
                let navVC = UINavigationController(rootViewController: bookmarksVC)
                navVC.navigationBar.prefersLargeTitles = true
                navigationController.present(navVC, animated: true, completion: {
                    bookmarksVC.delegate = self
                    bookmarksVC.navigationItem.largeTitleDisplayMode = .never
                    bookmarksVC.navigationItem.setLeftBarButtonItems([], animated: true)
                    bookmarksVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goToPreviousApp))], animated: true)
                    bookmarksVC.navigationItem.prompt = "Select connection to export file"
                })
            }
        }
        
        var dismissed = false
        
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: {
            dismissed = true
            handle()
        })
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            if !dismissed {
                dismissed = true
                handle()
            }
        })
        
        return true
    }
    
    /// Open connection for shortcut.
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        navigationController.popToRootViewController(animated: true) {
            guard let bookmarksVC = self.navigationController.visibleViewController as? BookmarksTableViewController else {
                
                completionHandler(false)
                return
            }
            
            guard let index = Int(shortcutItem.type.components(separatedBy: " ")[1]) else {
                completionHandler(false)
                return
            }
            
            guard bookmarksVC.tableView.cellForRow(at: IndexPath(row: index, section: 0)) != nil else {
                completionHandler(false)
                return
            }
            
            bookmarksVC.tableView(bookmarksVC.tableView, didSelectRowAt: IndexPath(row: index, section: 0))
        }
    }
    
    /// Open connection from user activity.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
                
        guard let username = userActivity.userInfo?["username"] as? String else {
            return false
        }
        
        guard let host = userActivity.userInfo?["host"] as? String else {
            return false
        }
        
        guard let password = userActivity.userInfo?["password"] as? String else {
            return false
        }
        
        guard let port = userActivity.userInfo?["port"] as? UInt64 else {
            return false
        }
        
        let path = userActivity.userInfo?["directory"] as? String ?? "~"
        
        var options = [.init("path"):path, .init("password"):password] as [UIApplicationOpenURLOptionsKey : String]
        if let pubKey = userActivity.userInfo?["publicKey"] as? String {
            options[.init("publicKey")] = pubKey
        }
        if let privKey = userActivity.userInfo?["privateKey"] as? String {
            options[.init("privateKey")] = privKey
        }
        
        if userActivity.activityType == "ch.marcela.ada.Pisth.openDirectory" {
            
            guard let url = URL(string: "sftp://\(username)@\(host):\(port)") else {
                return false
            }
            
            return self.application(application, open: url, options: options)
        } else if userActivity.activityType == "ch.marcela.ada.Pisth.openTerminal" {
            
            guard let url = URL(string: "ssh://\(username)@\(host):\(port)") else {
                return false
            }
            
            return self.application(application, open: url, options: options)
        }
        
        return false
    }
    
    // MARK: - Directory collection view controller delegate
    
    /// `DirectoryCollectionViewControllerDelegate`'s` `directoryCollectionViewController(_:, didOpenDirectory:)``function.
    ///
    /// Upload file at selected directory.
    func directoryCollectionViewController(_ directoryCollectionViewController: DirectoryCollectionViewController, didOpenDirectory directory: String) {
        if action == .upload {
            directoryCollectionViewController.navigationItem.prompt = "Select folder where upload file"
        } else if action == .apiImport {
            directoryCollectionViewController.navigationItem.prompt = importReason ?? "Select file to import"
        }
        directoryCollectionViewController.delegate = self
        directoryCollectionViewController.closeAfterSending = true
        self.directoryCollectionViewController = directoryCollectionViewController
        
        (navigationController.presentedViewController as? UINavigationController)?.pushViewController(directoryCollectionViewController, animated: true) {
            if self.action == .upload {
                directoryCollectionViewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "cloud-upload"), style: .done, target: self, action: #selector(self.uploadFile))]
            } else {
                directoryCollectionViewController.navigationItem.rightBarButtonItems = []
            }
            
        }
    }
    
    // MARK: - Bookmarks table view controller delegate
    
    /// Upload file at selected connection.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inDirectoryCollectionViewController directoryCollectionViewController: DirectoryCollectionViewController) {
        
        if action == .upload {
            directoryCollectionViewController.navigationItem.prompt = "Select folder where upload file"
            directoryCollectionViewController.closeAfterSending = true
        } else if action == .apiImport {
            directoryCollectionViewController.navigationItem.prompt = importReason ?? "Select file to import"
        }
        directoryCollectionViewController.delegate = self
        
        self.directoryCollectionViewController = directoryCollectionViewController
        bookmarksTableViewController.navigationController?.pushViewController(directoryCollectionViewController, animated: true) {
            
            if self.action == .upload {
                directoryCollectionViewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "cloud-upload"), style: .done, target: self, action: #selector(self.uploadFile))]
            } else {
                directoryCollectionViewController.navigationItem.rightBarButtonItems = []
            }
        }
    }
    
    /// Show alert saying a file cannot be uploaded with SFTP disabled.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inTerminalViewController terminalViewController: TerminalViewController) {
        
        bookmarksTableViewController.viewDidAppear(true)
        
        let alert = UIAlertController(title: "Cannot upload file!", message: "SFTP must be enabled.\nIf you want to upload file here, press the \"info\" button and enable SFTP.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        bookmarksTableViewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Directory collection view controller static delegate
    
    /// Export file with API.
    func didOpenFile(_ file: URL, withData data: Data) {
        
        if action == .apiImport {
            try? FileManager.default.removeItem(at: file)
            LocalDirectoryCollectionViewController.delegate = nil
            
            UIPasteboard.general.setData(NSKeyedArchiver.archivedData(withRootObject: PisthFile(data: data, filename: file.lastPathComponent)), forPasteboardType: "public.data")
            
            navigationController.dismiss(animated: true, completion: {
                if let dataReceiverAppURLScheme = self.dataReceiverAppURLScheme {
                    UIApplication.shared.open(dataReceiverAppURLScheme, options: [:], completionHandler: nil)
                }
            })
        }
        
    }
    
    // MARK: - Split view controller delegate
    
    /// Change display mode and View controllers.
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        splitViewController.viewControllers = [secondaryViewController]
        if splitViewController.preferredDisplayMode == .primaryOverlay {
            splitViewController.preferredDisplayMode = .primaryHidden
        }
        
        return true
    }
    
    /// Change display mode.
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        splitViewController.viewControllers = [navigationController, self.splitViewController.detailNavigationController]
        
        if splitViewController.preferredDisplayMode == .primaryHidden && !(self.splitViewController.detailNavigationController.visibleViewController is BookmarksTableViewController) {
            splitViewController.preferredDisplayMode = .primaryOverlay
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                let button = splitViewController.displayModeButtonItem
                _ = button.target?.perform(button.action)
            })
        }
        
        return navigationController
    }
    
    // MARK: - Static
    
    /// The shared instance of the app's delegate set in `application(_:didFinishLaunchingWithOptions:)`.
    static var shared: AppDelegate!
}

