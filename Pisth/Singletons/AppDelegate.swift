// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import CoreData
import SwiftKeychainWrapper
import Pisth_Shared
import Firebase
import Pisth_API
import UserNotifications
import WhatsNew

/// Returns `true` if the app was built as the free version containing only the Shell. Use this boolean to limit functionalities.
var isShell: Bool {
    return ((Bundle.main.infoDictionary?["Is Shell"] as? Bool) == true)
}

/// The global theme color to use in Pisth Shell.
let shellBackgroundColor = UIColor(hexString: "#404040")

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
    
    /// An instance of `DirectoryCollectionViewController` to be used to upload files from the share menu.
    var directoryCollectionViewController: DirectoryCollectionViewController?
    
    /// An instance of `DirectoryCollectionViewController` to be used to upload a file from Pisth API.
    var pisthAPIDirectoryCollectionViewControllerSender: DirectoryCollectionViewController?
    
    /// The file opened from share menu.
    var openedFile: URL?
    
    /// URL scheme of app that is using Pisth API and opened the URL scheme.
    var dataReceiverAppURLScheme: URL!
    
    /// Go back to app that opened the URL scheme.
    @objc func goToPreviousApp() {
        action = nil
        window?.rootViewController?.dismiss(animated: true, completion: {
            
            if self.dataReceiverAppURLScheme != nil {
                UIApplication.shared.open(self.dataReceiverAppURLScheme!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
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
    /// Called when closing the BookmarksTableViewController opened when upload a file.
    @objc func close() {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.dismiss(animated: true, completion: {
                self.openedFile = nil
                self.action = nil
                self.directoryCollectionViewController = nil
            })
        }
    }
    
    /// Show a `CompactBookmarksTableViewController` from compact window or show it from the left.
    @objc func showBookmarks() {
        
        // Request app review
        if ReviewHelper.shared.launches != -1 {
            ReviewHelper.shared.launches += 1
        }
        ReviewHelper.shared.requestReview()
        
        if !splitViewController.isCollapsed {
            let button = AppDelegate.shared.splitViewController.displayModeButtonItem
            _ = button.target?.perform(button.action)
        } else {
            let navVC = BlackNavigationController(rootViewController: CompactBookmarksTableViewController())
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
        return UIBarButtonItem(title: Localizable.BookmarksTableViewController.bookmarksTitle, style: .done, target: self, action: #selector(showBookmarks))
    }
    
    /// Update 3D touch shortucts from connections.
    func update3DTouchShortucts() {
        
        var shortcuts = [UIApplicationShortcutItem]()
        
        var i = 0
        for connection in DataManager.shared.connections {
            var icon: UIApplicationShortcutIcon {
                if connection.useSFTP {
                    return UIApplicationShortcutIcon(templateImageName: "File icons/folder")
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        UIMenuController.shared.menuItems = [
            .init(title: Localizable.UIMenuItem.delete, action: #selector(FileCollectionViewCell.deleteFile(_:))),
            .init(title: Localizable.UIMenuItem.move, action: #selector(FileCollectionViewCell.moveFile(_:))),
            .init(title: Localizable.UIMenuItem.rename, action: #selector(FileCollectionViewCell.renameFile(_:))),
            .init(title: Localizable.UIMenuItem.info, action: #selector(FileCollectionViewCell.showFileInfo(_:))),
            .init(title: Localizable.UIMenuItem.share, action: #selector(FileCollectionViewCell.shareFile(_:))),
            .init(title: Localizable.UIMenuItem.openInNewPanel, action: #selector(FileCollectionViewCell.openInNewPanel(_:))),
            .init(title: Localizable.UIMenuItem.selectionMode, action: #selector(TerminalViewController.selectionMode)),
            .init(title: Localizable.UIMenuItem.insertMode, action: #selector(TerminalViewController.insertMode)),
            .init(title: Localizable.UIMenuItem.paste, action: #selector(TerminalViewController.pasteText)),
            .init(title: Localizable.UIMenuItem.toggleTopBar, action: #selector(TerminalViewController.showNavBar)),
            .init(title: Localizable.UIMenuItem.pasteSelection, action: #selector(TerminalViewController.pasteSelection))
        ]
        UIMenuController.shared.update()
        
        DataManager.shared.saveCompletion = update3DTouchShortucts
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let content = ContentViewController.makeViewController()
        window?.rootViewController = content
        ContentViewController.shared = content
        window?.makeKeyAndVisible()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }

        // Firebase analytics
        FirebaseApp.configure()
        
        // Save passwords to keychain if they are not
        // See how passwords are managed since 3.0 at 'Pisth Shared/DataManager.swift'
        if !UserKeys.savedToKeychain.boolValue {
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
            
            UserKeys.savedToKeychain.boolValue = true
        }
        
        UserKeys.wasWelcomeScreenShown.boolValue = UserKeys.isSFTPAttributeAdded.boolValue
        
        // Add 'sftp' attributes to saved connections if there are not
        // 'sftp' attribute was added in 5.1
        if !UserKeys.isSFTPAttributeAdded.boolValue {
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
            
            UserKeys.isSFTPAttributeAdded.boolValue = true
        }
        
        // Set default terminal theme
        if UserKeys.terminalTheme.value == nil {
            UserKeys.terminalTheme.stringValue = "Pisth"
        }
        
        // Setup 3D touch shortcuts
        AppDelegate.shared.update3DTouchShortucts()
        
        // Blink cursor by default
        if UserKeys.blink.value == nil {
            UserKeys.blink.boolValue = true
        }
        
        // Use Xcode theme by default
        if UserKeys.editorTheme.value == nil {
            UserKeys.editorTheme.stringValue = "xcode"
        }
        
        // Set default terminal text size
        
        if UserKeys.terminalTextSize.value == nil || UserKeys.terminalTextSize.integerValue == 0 {
            UserKeys.terminalTextSize.integerValue = 15
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
        
        // News
        var items: [WhatsNewItem]
        if UserKeys.wasWelcomeScreenShown.boolValue {
            items = Localizable.WhatsNewViewController.features
        } else {
            items = Localizable.WhatsNewViewController.mainFeatures
        }
        let whatsNew = WhatsNewViewController(items: items)
        whatsNew.buttonBackgroundColor = window?.tintColor ?? whatsNew.buttonBackgroundColor
        whatsNew.buttonTextColor = .white
        whatsNew.buttonText = Localizable.continue
        if UserKeys.wasWelcomeScreenShown.boolValue {
            whatsNew.titleText = Localizable.WhatsNewViewController.title
        } else {
            whatsNew.titleText = Localizable.welcome
        }
        func setContentMode(ofView view: UIView) {
            view.contentMode = .scaleAspectFit
            for subview in view.subviews {
                setContentMode(ofView: subview)
            }
        }
        setContentMode(ofView: whatsNew.view)
        if let vc = window?.rootViewController, !isShell, !NSLocalizedString("whatsNew.features", comment: "").isEmpty {
            #if DEBUG
            vc.present(whatsNew, animated: true, completion: nil)
            #else
            whatsNew.presentIfNeeded(on: vc)
            #endif
            UserKeys.wasWelcomeScreenShown.boolValue = true
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Open file, upload file or open connection.
        
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
                
                let alert = UIAlertController(title: Localizable.AppDelegate.openSSHConnection, message: Localizable.AppDelegate.authenticate(as: user), preferredStyle: .alert)
                
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
                        textField.placeholder = Localizable.AppDelegate.usernamePlaceholder
                    })
                }
                
                func connect(withPassword password: String) {
                    let activityVC = ActivityViewController(message: Localizable.loading)
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: {
                        let connection = RemoteConnection(host: host, username: userTextField?.text ?? user, password: password, publicKey: options[UIApplication.OpenURLOptionsKey.init(rawValue: "publicKey")] as? String, privateKey: options[UIApplication.OpenURLOptionsKey.init(rawValue: "privateKey")] as? String, name: "", path: (options[UIApplication.OpenURLOptionsKey.init(rawValue: "path")] as? String) ?? "~", port: UInt64(port) ?? 22, useSFTP: (url.absoluteString.hasPrefix("sftp:") || url.absoluteString.hasPrefix("pisthsftp:")), os: nil)
                        
                        ConnectionManager.shared.session = nil
                        ConnectionManager.shared.filesSession = nil
                        ConnectionManager.shared.result = .notConnected
                        
                        ContentViewController.shared.closeAllPinnedPanels()
                        ContentViewController.shared.closeAllFloatingPanels()
                        
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
                
                if let password = options[UIApplication.OpenURLOptionsKey.init(rawValue: "password")] as? String {
                    connect(withPassword: password)
                } else {
                    alert.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = Localizable.AppDelegate.passwordPlaceholder
                        textField.isSecureTextEntry = true
                    })
                    
                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: Localizable.AppDelegate.connect, style: .default, handler: { (_) in
                        connect(withPassword: passwordTextField?.text ?? "")
                    }))
                    alert.addAction(UIAlertAction(title: Localizable.AppDelegate.connectAndRemember, style: .default, handler: { (_) in
                        let connection = RemoteConnection(host: host, username: userTextField?.text ?? user, password: passwordTextField?.text ?? "", publicKey: options[UIApplication.OpenURLOptionsKey.init(rawValue: "publicKey")] as? String, privateKey: options[UIApplication.OpenURLOptionsKey.init(rawValue: "privateKey")] as? String, name: "", path: (options[UIApplication.OpenURLOptionsKey.init(rawValue: "path")] as? String) ?? "~", port: UInt64(port) ?? 22, useSFTP: (url.absoluteString.hasPrefix("sftp:") || url.absoluteString.hasPrefix("pisthsftp:")), os: nil)
                        DataManager.shared.addNew(connection: connection)
                        connect(withPassword: connection.password)
                    }))
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            } else if url.isFileURL { // Upload file or import plugin or theme.
                
                _ = url.startAccessingSecurityScopedResource()
                
                if url.pathExtension.lowercased() == "termplugin" { // Import plugin
                    
                    let alert = UIAlertController(title: Localizable.AppDelegate.usePluginTitle, message: Localizable.AppDelegate.usePluginMessage, preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: Localizable.AppDelegate.usePlugin, style: .destructive, handler: { (_) in
                        var pluginURL = FileManager.default.library.appendingPathComponent("Plugins").appendingPathComponent(url.lastPathComponent)
                        
                        var i = 1
                        while FileManager.default.fileExists(atPath: pluginURL.path) {
                            pluginURL = pluginURL.deletingLastPathComponent().appendingPathComponent("\(url.lastPathComponent)-\(i).\(url.pathExtension)")
                            
                            i += 1
                        }
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: pluginURL)
                        } catch {
                            let alert = UIAlertController(title: Localizable.Browsers.errorCopyingFile, message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                            
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    
                    return
                }
                
                // Upload file
                
                action = .upload
                
                openedFile = url
                
                // Open a BookmarksTableViewController to select where upload the file
                
                let bookmarksVC = BookmarksTableViewController()
                let navVC = UINavigationController(rootViewController: bookmarksVC)
                if #available(iOS 11.0, *) {
                    navVC.navigationBar.prefersLargeTitles = true
                }
                window?.rootViewController?.present(navVC, animated: true, completion: {
                    bookmarksVC.delegate = self
                    if #available(iOS 11.0, *) {
                        bookmarksVC.navigationItem.largeTitleDisplayMode = .never
                    }
                    bookmarksVC.navigationItem.setLeftBarButtonItems([], animated: true)
                    bookmarksVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.close))], animated: true)
                    bookmarksVC.navigationItem.prompt = Localizable.AppDelegate.selectConnectionToUploadFile
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
                    containerView.tag = 1
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
                if #available(iOS 11.0, *) {
                    navVC.navigationBar.prefersLargeTitles = true
                }
                navigationController.present(navVC, animated: true, completion: {
                    bookmarksVC.delegate = self
                    if #available(iOS 11.0, *) {
                        bookmarksVC.navigationItem.largeTitleDisplayMode = .never
                    }
                    bookmarksVC.navigationItem.setLeftBarButtonItems([], animated: true)
                    bookmarksVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goToPreviousApp))], animated: true)
                    bookmarksVC.navigationItem.prompt = Localizable.AppDelegate.selectConnectionToExportFile
                })
            } else if url.absoluteString.hasPrefix("pisth:") { // Send file from Pisth API
                
                let pisth = Pisth(message: nil, urlScheme: URL(string:"pisth://")!)
                
                if let file = pisth.receivedFile, let dirVC = pisthAPIDirectoryCollectionViewControllerSender {
                    pisthAPIDirectoryCollectionViewControllerSender = nil
                    
                    dirVC.sendFile(file: nil, data: file.data, filename: file.filename, toDirectory: dirVC.directory)
                }
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
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        // Open connection for shortcut.
        
        class AppBookmarksTableViewController: BookmarksTableViewController {
            
            override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
                
                ContentViewController.shared.present(viewControllerToPresent, animated: flag, completion: completion)
            }
        }
        
        let bookmarksVC = AppBookmarksTableViewController()
        bookmarksVC.loadViewIfNeeded()
        
        guard let index = Int(shortcutItem.type.components(separatedBy: " ")[1]) else {
            completionHandler(false)
            return
        }
        
        guard bookmarksVC.tableView.cellForRow(at: IndexPath(row: index, section: 1)) != nil else {
            completionHandler(false)
            return
        }
        
        bookmarksVC.tableView(bookmarksVC.tableView, didSelectRowAt: IndexPath(row: index, section: 1))
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // Open connection from user activity.
        
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
        
        var options = [.init("path"):path, .init("password"):password] as! [UIApplication.OpenURLOptionsKey : String]
        if let pubKey = userActivity.userInfo?["publicKey"] as? String {
            options[UIApplication.OpenURLOptionsKey.init(rawValue: "publicKey")] = pubKey
        }
        if let privKey = userActivity.userInfo?["privateKey"] as? String {
            options[UIApplication.OpenURLOptionsKey.init(rawValue: "privateKey")] = privKey
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
    
    func directoryCollectionViewController(_ directoryCollectionViewController: DirectoryCollectionViewController, didOpenDirectory directory: String) {
        
        // Upload file at selected directory.
        
        if action == .upload {
            directoryCollectionViewController.navigationItem.prompt = Localizable.AppDelegate.selectFolderWhereUploadFile
        } else if action == .apiImport {
            directoryCollectionViewController.navigationItem.prompt = importReason ?? Localizable.AppDelegate.selectFiletoImport
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
    
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inDirectoryCollectionViewController directoryCollectionViewController: DirectoryCollectionViewController) {
        
        // Upload file at selected connection.
        
        if action == .upload {
            directoryCollectionViewController.navigationItem.prompt = Localizable.AppDelegate.selectFolderWhereUploadFile
            directoryCollectionViewController.closeAfterSending = true
        } else if action == .apiImport {
            directoryCollectionViewController.navigationItem.prompt = importReason ?? Localizable.AppDelegate.selectFiletoImport
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
    
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inTerminalViewController terminalViewController: TerminalViewController) {
        
        if let indexPath = bookmarksTableViewController.tableView.indexPathForSelectedRow {
            
            bookmarksTableViewController.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Directory collection view controller static delegate
    
    func didOpenFile(_ file: URL, withData data: Data) {
    
        // Export file with API.
        
        if action == .apiImport {
            action = nil
            try? FileManager.default.removeItem(at: file)
            LocalDirectoryCollectionViewController.delegate = nil
            
            UIPasteboard.general.setData(NSKeyedArchiver.archivedData(withRootObject: PisthFile(data: data, filename: file.lastPathComponent)), forPasteboardType: "public.data")
            
            navigationController.dismiss(animated: true, completion: {
                if let dataReceiverAppURLScheme = self.dataReceiverAppURLScheme {
                    UIApplication.shared.open(dataReceiverAppURLScheme, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
            })
        }
        
    }
    
    // MARK: - Split view controller delegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        // Change display mode and View controllers.
        
        splitViewController.viewControllers = [secondaryViewController]
        if splitViewController.preferredDisplayMode == .primaryOverlay {
            splitViewController.preferredDisplayMode = .primaryHidden
        }
        
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        // Change display mode.
        
        splitViewController.viewControllers = [self.splitViewController.navigationController ?? self.navigationController, self.splitViewController.detailViewController ?? self.splitViewController.detailNavigationController]
        
        if splitViewController.preferredDisplayMode == .primaryHidden && !(self.splitViewController.detailNavigationController?.visibleViewController is BookmarksTableViewController) {
            splitViewController.preferredDisplayMode = .primaryOverlay
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                let button = splitViewController.displayModeButtonItem
                _ = button.target?.perform(button.action)
            })
        }
        
        return splitViewController.viewControllers.last
    }
    
    // MARK: - Static
    
    /// The shared instance of the app's delegate set in `application(_:didFinishLaunchingWithOptions:)`.
    static var shared: AppDelegate!
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
