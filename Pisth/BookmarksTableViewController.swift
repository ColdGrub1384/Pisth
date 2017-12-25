//
//  BookmarksTableViewController.swift
//  Pisth
//
//  Created by Adrian on 25.12.17.
//  Copyright © 2017 ADA. All rights reserved.
//

import UIKit
import CoreData

class BookmarksTableViewController: UITableViewController {
    
    // MARK: - BookmarksTableViewController
    
    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConnection))
    
    @objc func addConnection() { // Add connection
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Bookmarks"
        
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.leftBarButtonItem = addButton
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "bookmark")
        cell.backgroundColor = .clear
        
        // Configure the cell...
        
        cell.textLabel?.text = connections[indexPath.row].name
        cell.detailTextLabel?.text = "\(connections[indexPath.row].username)@\(connections[indexPath.row].host)"
        
        // If the connection has no name, set the title as username@host
        if cell.textLabel?.text == "" {
            cell.textLabel?.text = cell.detailTextLabel?.text
            cell.detailTextLabel?.text = ""
        }
        
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        var connections = self.connections
        
        let connectionToMove = connections[fromIndexPath.row]
        connections.remove(at: fromIndexPath.row)
        connections.insert(connectionToMove, at: to.row)
        
        removeAll()
        
        for connection in connections {
            addNew(connection: connection)
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Mark: Core Data
    
    func addNew(connection: RemoteConnection) { // Create and save connection
        
        let newConnection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: AppDelegate.shared.coreDataContext)
        newConnection.setValue(connection.host, forKey: "host")
        newConnection.setValue(connection.username, forKey: "username")
        newConnection.setValue(connection.password, forKey: "password")
        newConnection.setValue(connection.name, forKey: "name")
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
                
                fetchedConnections.append(RemoteConnection(host: host, username: username, password: password, name: name))
            }
        } catch let error {
            print("Error retrieving connections: \(error.localizedDescription)")
            return fetchedConnections
        }
        
        return fetchedConnections
    }
    
}
