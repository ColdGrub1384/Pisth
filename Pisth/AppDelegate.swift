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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryTableViewControllerDelegate, BookmarksTableViewControllerDelegate {

    static var shared: AppDelegate!

    var window: UIWindow?
    var navigationController = UINavigationController()
    var directoryTableViewController: DirectoryTableViewController?
    var openedFile: URL?
    var coreDataContext: NSManagedObjectContext {
        return AppDelegate.shared.persistentContainer.viewContext
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIMenuController.shared.menuItems = [UIMenuItem(title: "Move", action: #selector(FileTableViewCell.moveFile(_:))), UIMenuItem(title: "Rename", action: #selector(FileTableViewCell.renameFile(_:)))]
        UIMenuController.shared.update()
        
        AppDelegate.shared = self
        
        // Setup Navigation Controller
        let bookmarksVC = BookmarksTableViewController()
        navigationController = UINavigationController(rootViewController: bookmarksVC)
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.isTranslucent = true
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        
        // Setup window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9214899206650515~2846344793")
        
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
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.absoluteString.hasPrefix("file://") { // Upload file
            self.openedFile = url
            let bookmarksVC = BookmarksTableViewController()
            let navVC = UINavigationController(rootViewController: bookmarksVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
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
        }
        
        return false
    }
    
    @objc func uploadFile() {
        if let directoryTableViewController = directoryTableViewController {
            if let file = openedFile {
                directoryTableViewController.localDirectoryTableViewController(LocalDirectoryTableViewController(directory: FileManager.default.documents), didOpenFile: file)
            }
        }
    }
    
    @objc func close() {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.dismiss(animated: true, completion: {
                self.openedFile = nil
                self.directoryTableViewController = nil
            })
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
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
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - DirectoryTableViewControllerDelegate
    func directoryTableViewController(_ directoryTableViewController: DirectoryTableViewController, didOpenDirectory directory: String) {
        directoryTableViewController.navigationItem.prompt = "Select folder where upload file"
        directoryTableViewController.delegate = self
        directoryTableViewController.closeAfterSending = true
        self.directoryTableViewController = directoryTableViewController
        UIApplication.shared.keyWindow?.rootViewController?.navigationController?.pushViewController(directoryTableViewController, animated: true) {
            directoryTableViewController.navigationItem.rightBarButtonItems?.remove(at: 1)
        }
    }
    
    // MARK: - BookmarksTableViewControllerDelegate
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection: RemoteConnection, inDirectoryTableViewController directoryTableViewController: DirectoryTableViewController) {
        
        directoryTableViewController.navigationItem.prompt = "Select folder where upload file"
        directoryTableViewController.delegate = self
        directoryTableViewController.closeAfterSending = true
        self.directoryTableViewController = directoryTableViewController
        bookmarksTableViewController.navigationController?.pushViewController(directoryTableViewController, animated: true) {
            directoryTableViewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "cloud-upload"), style: .done, target: self, action: #selector(self.uploadFile))]
        }
    }
}

