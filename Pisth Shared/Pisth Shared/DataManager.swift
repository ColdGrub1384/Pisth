// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import CoreData

/// A class for managing saved connections.
public class DataManager {
    
    /// Shared and unique instance of DataManager.
    public static let shared = DataManager()
    private init() {}
    
    /// Code to execute after saving context.
    public var saveCompletion: (() -> Void)?
    
    /// Returns: `persistentContainer.viewContext`.
    public var coreDataContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Create and save connection.
    /// - Parameters:
    ///     - connection: Representation of the connection to add.
    public func addNew(connection: RemoteConnection) {
        
        let newConnection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: coreDataContext)
        newConnection.setValue(connection.host, forKey: "host")
        newConnection.setValue(connection.username, forKey: "username")
        newConnection.setValue(connection.name, forKey: "name")
        newConnection.setValue(connection.path, forKey: "path")
        newConnection.setValue(connection.port, forKey: "port")
        newConnection.setValue(connection.useSFTP, forKey: "sftp")
        newConnection.setValue(connection.os, forKey: "os")
        newConnection.setValue(connection.publicKey, forKey: "publicKey")
        newConnection.setValue(connection.privateKey, forKey: "privateKey")
        
        // Set password
        // The password in database is a random string, a password is saved to the keychain with key the random string
        let key = String.random(length: 100)
        newConnection.setValue(key, forKey: "password")
        #if os(iOS)
        KeychainWrapper.standard.set(connection.password, forKey: key)
        #else
        KeychainSwift().set(connection.password, forKey: key)
        #endif
        
        saveContext()
    }
    
    /// Remove connection at given index.
    /// - Parameters:
    ///     - index: Index of connection to remove.
    public func removeConnection(at index: Int) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try coreDataContext.fetch(request) as! [NSManagedObject]
            if let passKey = results[index].value(forKey: "password") as? String {
                #if os(iOS)
                KeychainWrapper.standard.removeObject(forKey: passKey)
                #else
                KeychainSwift().delete(passKey)
                #endif
            }
            coreDataContext.delete(results[index])
            saveContext()
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
        }
    }
    
    /// Remove all saved connections.
    public func removeAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coreDataContext.execute(deleteRequest)
            saveContext()
            #if os(iOS)
            _ = KeychainWrapper.standard.removeAllKeys()
            #else
            KeychainSwift().clear()
            #endif
        } catch let error {
            print("Error removing all: \(error.localizedDescription)")
        }
    }
    
    /// Returns an array of representation of saved connections.
    public var connections: [RemoteConnection] {
        
        var fetchedConnections = [RemoteConnection]()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try coreDataContext.fetch(request)
            
            for result in results as! [NSManagedObject] {
                
                guard let host = result.value(forKey: "host") as? String else { return fetchedConnections }
                guard let username = result.value(forKey: "username") as? String else { return fetchedConnections }
                guard let passKey = result.value(forKey: "password") as? String else { return fetchedConnections }
                guard let name = result.value(forKey: "name") as? String else { return fetchedConnections }
                guard let port = result.value(forKey: "port") as? UInt64 else { return fetchedConnections }
                guard let path = result.value(forKey: "path") as? String else { return fetchedConnections }
                #if os(iOS)
                guard let password = KeychainWrapper.standard.string(forKey: passKey) else { return fetchedConnections }
                #else
                guard let password = KeychainSwift().get(passKey) else { return fetchedConnections }
                #endif
                guard let useSFTP = result.value(forKey: "sftp") as? Bool else { return fetchedConnections }
                
                fetchedConnections.append(RemoteConnection(host: host, username: username, password: password, publicKey: (result.value(forKey: "publicKey") as? String), privateKey: (result.value(forKey: "privateKey") as? String), name: name, path: path, port: port, useSFTP: useSFTP, os: result.value(forKey: "os") as? String))
            }
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
            return fetchedConnections
        }
        
        return fetchedConnections
    }
    
    // MARK: - Core Data stack
    
    /// The persistent container for the application. This implementation
    /// creates and returns a container, having loaded the store for the
    /// application to it. This property is optional since there are legitimate
    /// error conditions that could cause the creation of the store to fail.
    public lazy var persistentContainer: NSPersistentContainer = {
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
    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                
                saveCompletion?()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
