// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import CoreData
import SwiftKeychainWrapper

class DataManager {
    
    static let shared = DataManager()
    private init() {}
    
    func addNew(connection: RemoteConnection) { // Create and save connection
        
        let newConnection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: AppDelegate.shared.coreDataContext)
        newConnection.setValue(connection.host, forKey: "host")
        newConnection.setValue(connection.username, forKey: "username")
        newConnection.setValue(connection.name, forKey: "name")
        newConnection.setValue(connection.path, forKey: "path")
        newConnection.setValue(connection.port, forKey: "port")
        
        // Set password
        // The password in database is a random string, a password is saved to the keychain with key the random string
        let key = String.random(length: 100)
        newConnection.setValue(key, forKey: "password")
        KeychainWrapper.standard.set(connection.password, forKey: key)
        
        do {
            try AppDelegate.shared.coreDataContext.save()
        } catch let error {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    func removeConnection(at index: Int) { // Remove connection at given index
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try AppDelegate.shared.coreDataContext.fetch(request) as! [NSManagedObject]
            if let passKey = results[index].value(forKey: "password") as? String {
                KeychainWrapper.standard.removeObject(forKey: passKey)
            }
            AppDelegate.shared.coreDataContext.delete(results[index])
            AppDelegate.shared.saveContext()
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
        }
    }
    
    func removeAll() { // Remove all connections
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try AppDelegate.shared.coreDataContext.execute(deleteRequest)
            AppDelegate.shared.saveContext()
            _ = KeychainWrapper.standard.removeAllKeys()
        } catch let error {
            print("Error removing all: \(error.localizedDescription)")
        }
    }
    
    var connections: [RemoteConnection] { // Return connections saved to disk
        
        var fetchedConnections = [RemoteConnection]()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try AppDelegate.shared.coreDataContext.fetch(request)
            
            for result in results as! [NSManagedObject] {
                
                guard let host = result.value(forKey: "host") as? String else { return fetchedConnections }
                guard let username = result.value(forKey: "username") as? String else { return fetchedConnections }
                guard let passKey = result.value(forKey: "password") as? String else { return fetchedConnections }
                guard let name = result.value(forKey: "name") as? String else { return fetchedConnections }
                guard let port = result.value(forKey: "port") as? UInt64 else { return fetchedConnections }
                guard let path = result.value(forKey: "path") as? String else { return fetchedConnections }
                guard let password = KeychainWrapper.standard.string(forKey: passKey) else { return fetchedConnections }
                
                fetchedConnections.append(RemoteConnection(host: host, username: username, password: password, name: name, path: path, port: port))
            }
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
            return fetchedConnections
        }
        
        return fetchedConnections
    }
}
