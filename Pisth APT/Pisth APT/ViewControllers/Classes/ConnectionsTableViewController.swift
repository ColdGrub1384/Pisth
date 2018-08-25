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
    
    private var wasConnectionInformationTableViewControllerPushed = false
    
    private func connect() {
        let activityVC = ActivityViewController(message: "Loading...")
        UIApplication.shared.keyWindow?.topViewController()?.present(activityVC, animated: true) {
            AppDelegate.shared.connect()
            activityVC.dismiss(animated: true, completion: {
                
                // Search for updates
                let activityVC = ActivityViewController(message: "Loading...")
                UIApplication.shared.keyWindow?.topViewController()?.present(activityVC, animated: true) {
                    AppDelegate.shared.searchForUpdates()
                    activityVC.dismiss(animated: true, completion: nil)
                }
                
            })
        }
    }
    
    /// Add new connection
    @IBAction func add(_ sender: Any) {
        if let vc = UIStoryboard(name: "Connection Info", bundle: Bundle.main).instantiateInitialViewController() as? ConnectionInformationTableViewController {
            vc.rootTableView = tableView
            vc.rootViewController = self
            
            let navVC = UINavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .formSheet
            
            wasConnectionInformationTableViewControllerPushed = true
            present(navVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems?.append(editButtonItem)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
        
        if wasConnectionInformationTableViewControllerPushed {
            
            connect()
            
            wasConnectionInformationTableViewControllerPushed = false
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return DataManager.shared.connections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "connection") else {
            return UITableViewCell()
        }
        
        if indexPath.row == UserDefaults.standard.integer(forKey: "connection") {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            DataManager.shared.removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (_, indexPath) in
            if let vc = UIStoryboard(name: "Connection Info", bundle: Bundle.main).instantiateInitialViewController() as? ConnectionInformationTableViewController {
                vc.index = indexPath.row
                vc.connection = DataManager.shared.connections[indexPath.row]
                vc.rootTableView = tableView
                vc.rootViewController = self
                
                let navVC = UINavigationController(rootViewController: vc)
                navVC.modalPresentationStyle = .formSheet
                
                self.wasConnectionInformationTableViewControllerPushed = true
                self.present(navVC, animated: true, completion: nil)
            }
        }
        
        return [delete, edit]
    }
    
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
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row != UserDefaults.standard.integer(forKey: "connection") {
            connect()
        }
        
        UserDefaults.standard.set(indexPath.row, forKey: "connection")
        UserDefaults.standard.synchronize()
        
        tableView.reloadData()
    }
}
