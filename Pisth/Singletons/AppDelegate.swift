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

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryTableViewControllerDelegate, BookmarksTableViewControllerDelegate, LocalDirectoryTableViewControllerStaticDelegate {
    
    /// The window used with app.
    var window: UIWindow?
    
    /// Action to do when opening the app with an URL scheme.
    var action: AppAction?
    
    /// The shared Navigation controller used in the app.
    var navigationController = UINavigationController()
    
    /// An instance of DirectoryTableViewController to be used to upload files from the share menu.
    var directoryTableViewController: DirectoryTableViewController?
    
    /// The file opened from share menu.
    var openedFile: URL?
    
    /// Returns: `persistentContainer.viewContext`.
    var coreDataContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// URL scheme of app that is using Pisth API and opened the URL scheme.
    var dataReceiverAppURLScheme: URL?
    
    /// Go back to app that opened the URL scheme.
    @objc func goToPreviousApp() {
        window?.rootViewController?.dismiss(animated: true, completion: {
            
            if self.dataReceiverAppURLScheme != nil {
                UIApplication.shared.open(self.dataReceiverAppURLScheme!, options: [:], completionHandler: nil)
            }
        })
    }
    
    /// Upload file at directory opened in `directoryTableViewController`.
    @objc func uploadFile() {
        if let directoryTableViewController = directoryTableViewController {
            if let file = openedFile {
                directoryTableViewController.localDirectoryTableViewController(LocalDirectoryTableViewController(directory: FileManager.default.documents), didOpenFile: file)
            }
        }
    }
    
    /// Dismiss app's Root View Controller and cancel file upload.
    /// Called did close the BookmarksTableViewController opened when upload a file.
    @objc func close() {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.dismiss(animated: true, completion: {
                self.openedFile = nil
                self.directoryTableViewController = nil
            })
        }
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
    
    /// `UIApplicationDelegate`'s `application(_:, didFinishLaunchingWithOptions:)` function.
    ///
    /// Initialize app's window, and setup / repair saved data.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIMenuController.shared.menuItems = [UIMenuItem(title: "Move", action: #selector(FileTableViewCell.moveFile(_:))), UIMenuItem(title: "Rename", action: #selector(FileTableViewCell.renameFile(_:)))]
        UIMenuController.shared.update()
        
        AppDelegate.shared = self
        
        // Setup Navigation Controller
        let bookmarksVC = BookmarksTableViewController()
        navigationController = UINavigationController(rootViewController: bookmarksVC)
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.isTranslucent = true
        navigationController.toolbar.barStyle = .black
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        
        // Setup window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
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
                let results = try (AppDelegate.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                
                for result in results {
                    let passKey = String.random(length: 100)
                    if let password = result.value(forKey: "password") as? String {
                        KeychainWrapper.standard.set(password, forKey: passKey)
                    }
                    result.setValue(passKey, forKey: "password")
                }
                
                try? coreDataContext.save()
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
                let results = try (AppDelegate.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                
                for result in results {
                    if result.value(forKey: "sftp") == nil {
                        result.setValue(true, forKey: "sftp")
                    }
                }
                
                try? coreDataContext.save()
            } catch let error {
                print("Error retrieving connections: \(error.localizedDescription)")
            }
            
            UserDefaults.standard.setValue(true, forKey: "addedSftpAttribute")
            UserDefaults.standard.synchronize()
        }
        
        // Set default terminal theme
        if UserDefaults.standard.string(forKey: "terminalTheme") == nil {
            UserDefaults.standard.set("Pro", forKey: "terminalTheme")
            UserDefaults.standard.synchronize()
        }
        
        // Setup 3D touch shortcuts
        AppDelegate.shared.update3DTouchShortucts()
        
        // Blink cursor by default
        if UserDefaults.standard.value(forKey: "blink") == nil {
            UserDefaults.standard.set(true, forKey: "blink")
            UserDefaults.standard.synchronize()
        }
        
        // Use paraiso-dark by default
        if UserDefaults.standard.value(forKey: "editorTheme") == nil {
            UserDefaults.standard.set("paraiso-dark", forKey: "editorTheme")
            UserDefaults.standard.synchronize()
        }
        
        // Set default terminal text size
        if UserDefaults.standard.value(forKey: "terminalTextSize") == nil || UserDefaults.standard.integer(forKey: "terminalTextSize") == 0 {
            UserDefaults.standard.set(15, forKey: "terminalTextSize")
            UserDefaults.standard.synchronize()
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
    
    /// `UIApplicationDelegate`'s `application(_:, open:, options:)` function.
    ///
    /// Open and upload file.
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.absoluteString.hasPrefix("file:") { // Upload file
            
            action = .upload
            
            openedFile = url
            
            // Open a BookmarksTableViewController to select where upload the file
            
            let bookmarksVC = BookmarksTableViewController()
            let navVC = UINavigationController(rootViewController: bookmarksVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            navVC.toolbar.barStyle = .black
            navVC.toolbar.isTranslucent = true
            if #available(iOS 11.0, *) {
                navVC.navigationBar.prefersLargeTitles = true
            }
            navigationController.present(navVC, animated: true, completion: {
                bookmarksVC.delegate = self
                if #available(iOS 11.0, *) {
                    bookmarksVC.navigationItem.largeTitleDisplayMode = .never
                }
                bookmarksVC.navigationItem.setLeftBarButtonItems([], animated: true)
                bookmarksVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.close))], animated: true)
                bookmarksVC.navigationItem.prompt = "Select connection where upload file"
            })
        } else if url.absoluteString.hasPrefix("pisth-import:") { // Export file with the API
            
            LocalDirectoryTableViewController.delegate = self
            
            action = .apiImport
            
            if let scheme = url.queryParameters?["scheme"]?.removingPercentEncoding {
                dataReceiverAppURLScheme = URL(string: scheme)
            }
            
            // Open a BookmarksTableViewController to select file to export
            
            let bookmarksVC = BookmarksTableViewController()
            
            if let backgroundImage = UIPasteboard(name: .init("pisth-import"), create: false)?.image {
                let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
                let imageView = UIImageView(image: backgroundImage)
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
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            navVC.toolbar.barStyle = .black
            navVC.toolbar.isTranslucent = true
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
                bookmarksVC.navigationItem.prompt = "Select connection to export file"
            })
        }
        
        return false
    }
    
    /// `UIApplicationDelegate`'s `application(_:, performActionFor:, completionHandler:)` function.
    ///
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
    
    // MARK: - Core Data stack
    
    /// The persistent container for the application. This implementation
    /// creates and returns a container, having loaded the store for the
    /// application to it. This property is optional since there are legitimate
    /// error conditions that could cause the creation of the store to fail.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pisth")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    /// Save core data and update 3D touch shortcuts.
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                update3DTouchShortucts()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Directory table view controller delegate
    
    /// `DirectoryTableViewControllerDelegate`'s` `directoryTableViewController(_:, didOpenDirectory:)``function.
    ///
    /// Upload file at selected directory.
    func directoryTableViewController(_ directoryTableViewController: DirectoryTableViewController, didOpenDirectory directory: String) {
        if action == .upload {
            directoryTableViewController.navigationItem.prompt = "Select folder where upload file"
        } else if action == .apiImport {
            directoryTableViewController.navigationItem.prompt = "Select file to import"
        }
        directoryTableViewController.delegate = self
        directoryTableViewController.closeAfterSending = true
        self.directoryTableViewController = directoryTableViewController
        
        (navigationController.presentedViewController as? UINavigationController)?.pushViewController(directoryTableViewController, animated: true) {
            if self.action == .upload {
                directoryTableViewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "cloud-upload"), style: .done, target: self, action: #selector(self.uploadFile))]
            } else {
                directoryTableViewController.navigationItem.rightBarButtonItems = []
            }
            
        }
    }
    
    // MARK: - Bookmarks table view controller delegate
    
    /// `BookmarksTableViewControllerDelegate`'s `bookmarksTableViewController(_:, didOpenConnection:, inDirectoryTableViewController:)` function.
    ///
    /// Upload file at selected connection.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inDirectoryTableViewController directoryTableViewController: DirectoryTableViewController) {
        
        if action == .upload {
            directoryTableViewController.navigationItem.prompt = "Select folder where upload file"
            directoryTableViewController.closeAfterSending = true
        } else if action == .apiImport {
            directoryTableViewController.navigationItem.prompt = "Select file to import"
        }
        directoryTableViewController.delegate = self
        
        self.directoryTableViewController = directoryTableViewController
        bookmarksTableViewController.navigationController?.pushViewController(directoryTableViewController, animated: true) {
            
            if self.action == .upload {
                directoryTableViewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "cloud-upload"), style: .done, target: self, action: #selector(self.uploadFile))]
            } else {
                directoryTableViewController.navigationItem.rightBarButtonItems = []
            }
        }
    }
    
    /// `BookmarksTableViewControllerDelegate`'s `bookmarksTableViewController(_:, didOpenConnection:, inTerminalViewController:)` function.
    ///
    /// Show alert saying a file cannot be uploaded with SFTP disabled.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inTerminalViewController terminalViewController: TerminalViewController) {
        
        bookmarksTableViewController.viewDidAppear(true)
        
        let alert = UIAlertController(title: "Cannot upload file!", message: "SFTP must be enabled.\nIf you want to upload file here, press the \"info\" button and enable SFTP.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        bookmarksTableViewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Directory table view controller static delegate
    
    func didOpenFile(_ file: URL, withData data: Data) {
        
        if action == .apiImport {
            try? FileManager.default.removeItem(at: file)
            LocalDirectoryTableViewController.delegate = nil
            
            UIPasteboard(name: .init("pisth-import"), create: true)?.setData(data, forPasteboardType: "public.data")
            
            navigationController.dismiss(animated: true, completion: {
                if let dataReceiverAppURLScheme = self.dataReceiverAppURLScheme {
                    UIApplication.shared.open(URL(string: dataReceiverAppURLScheme.absoluteString+"?filename=\(file.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!, options: [:], completionHandler: nil)
                }
            })
        }
        
    }
    
    // MARK: - Static
    
    /// The shared instance of the app's delegate set in `application(_: , didFinishLaunchingWithOptions:)`.
    static var shared: AppDelegate!
}

