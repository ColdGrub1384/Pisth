// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller used to manage connections.
class ConnectionsTableViewController: UITableViewController {
    
    /// Add new connection
    @IBAction func add(_ sender: Any) {
        if let vc = UIStoryboard(name: "Connection Info", bundle: Bundle.main).instantiateInitialViewController() {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - View controller
    
    /// Add `editButtonItem`.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems?.append(editButtonItem)
    }
    
    /// Reload data.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    /// - Returns: `1`.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// - Returns: number of connections or number of fetched connections with `searchController`.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return DataManager.shared.connections.count
    }
    
    /// - Returns: A cell with with title as the connection's nickname and subtitle as connection's details.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "connection") else {
            return UITableViewCell()
        }
        
        if indexPath.row == UserDefaults.standard.integer(forKey: "connection") {
            cell.accessoryType = .checkmark
        }
        
        let connection = DataManager.shared.connections[indexPath.row]
            
        // Configure the cell...
            
        cell.textLabel?.text = connection.name
        cell.detailTextLabel?.text = "\(connection.username)@\(connection.host):\(connection.port):\(connection.path)"
            
        // If the connection has no name, set the title as username@host
        if cell.textLabel?.text == "" {
            cell.textLabel?.text = cell.detailTextLabel?.text
            cell.detailTextLabel?.text = ""
        }

        return cell
    }
    
    /// - Returns: `true` for first section.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
    }
    
    /// - Returns: A button to delete the connection and one to edit it.
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            DataManager.shared.removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (_, indexPath) in
            if let vc = UIStoryboard(name: "Connection Info", bundle: Bundle.main).instantiateInitialViewController() as? ConnectionInformationTableViewController {
                vc.index = indexPath.row
                vc.connection = DataManager.shared.connections[indexPath.row]
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        return [delete, edit]
    }
    
    /// Move connections.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        var connections = DataManager.shared.connections
        
        let connectionToMove = connections[fromIndexPath.row]
        connections.remove(at: fromIndexPath.row)
        connections.insert(connectionToMove, at: to.row)
        
        DataManager.shared.removeAll()
        
        for connection in connections {
            DataManager.shared.addNew(connection: connection)
        }
    }
    
    /// `UITableViewController`'s `tableView(_:, canMoveRowAt:)` function.
    ///
    /// Allow moving rows for first section.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
    }
    
    // MARK: - Table view delegate
    
    /// Select connection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefaults.standard.set(indexPath.row, forKey: "connection")
        UserDefaults.standard.synchronize()
        
        tableView.reloadData()
    }
}
