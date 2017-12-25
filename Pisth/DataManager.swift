//
//  DataManager.swift
//  Pisth
//
//  Created by Adrian on 25.12.17.
//  Copyright © 2017 ADA. All rights reserved.
//

import CoreData

class DataManager {
    
    static let shared = DataManager()
    private init() {}
    
    func addNew(connection: RemoteConnection) { // Create and save connection
        
        let newConnection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: AppDelegate.shared.coreDataContext)
        newConnection.setValue(connection.host, forKey: "host")
        newConnection.setValue(connection.username, forKey: "username")
        newConnection.setValue(connection.password, forKey: "password")
        newConnection.setValue(connection.name, forKey: "name")
        newConnection.setValue(connection.path, forKey: "path")
        newConnection.setValue(connection.port, forKey: "port")
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
                guard let password = result.value(forKey: "password") as? String else { return fetchedConnections }
                guard let name = result.value(forKey: "name") as? String else { return fetchedConnections }
                guard let port = result.value(forKey: "port") as? UInt64 else { return fetchedConnections }
                guard let path = result.value(forKey: "path") as? String else { return fetchedConnections }
                
                fetchedConnections.append(RemoteConnection(host: host, username: username, password: password, name: name, path: path, port: port))
            }
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
            return fetchedConnections
        }
        
        return fetchedConnections
    }
}
