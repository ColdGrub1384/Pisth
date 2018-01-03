// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import CoreData
import GoogleMobileAds

class BookmarksTableViewController: UITableViewController, GADBannerViewDelegate {
    
    var delegate: BookmarksTableViewControllerDelegate?
    var bannerView: GADBannerView!
    
    @objc func openSettings() { // Open Settings
        navigationController?.pushViewController(UIStoryboard(name: "SettingsTableViewController", bundle: Bundle.main).instantiateInitialViewController()!, animated: true)
    }
    
    @objc func addConnection() { // Add connection
        showInfoAlert()
    }
    
    func showInfoAlert(editInfoAt index: Int? = nil) {
        
        var title: String {
            if index == nil {
                return "Add new connection"
            } else {
                return "Edit connection"
            }

        }
        
        var message: String {
            if index == nil {
                return "Fill fields to add a connection to bookmarks"
            } else {
                return "Fill fields to edit bookmark"
            }
            
        }
        
        let addNewAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        request.returnsObjectsAsFaults = false
        
        // Name
        addNewAlertController.addTextField { (name) in // Optional
            name.placeholder = "Nickname (Optional)"
        }
        
        // Host
        addNewAlertController.addTextField { (host) in // Requierd
            host.placeholder = "Hostname / IP address"
        }
        
        // Port
        addNewAlertController.addTextField { (port) in
            port.placeholder = "Port (22)"
            port.keyboardType = .numberPad
        }
        
        // Username
        addNewAlertController.addTextField { (username) in // Requierd
            username.placeholder = "Username"
        }
        
        // Password
        addNewAlertController.addTextField { (password) in
            password.placeholder = "Password"
            password.isSecureTextEntry = true
        }
        
        // Path
        addNewAlertController.addTextField { (path) in
            path.placeholder = "Path (~)"
        }
        
        if let index = index { // Fill info with given index
            let connection = DataManager.shared.connections[index]
            
            addNewAlertController.textFields![0].text = connection.name
            addNewAlertController.textFields![1].text = connection.host
            addNewAlertController.textFields![2].text = "\(connection.port)"
            addNewAlertController.textFields![3].text = connection.username
            addNewAlertController.textFields![4].text = connection.password
            addNewAlertController.textFields![5].text = connection.path
        }
        
        let addAction = UIAlertAction(title: "Save", style: .default) { (action) in // Create connection
            let name = addNewAlertController.textFields![0].text!
            let host = addNewAlertController.textFields![1].text!
            var port = addNewAlertController.textFields![2].text!
            let username = addNewAlertController.textFields![3].text!
            let password = addNewAlertController.textFields![4].text!
            var path = addNewAlertController.textFields![5].text!
            
            // Check for requierd fields
            if host == "" || username == "" {
                self.present(addNewAlertController, animated: true, completion: {
                    if host == "" {
                        addNewAlertController.textFields![0].backgroundColor = .red
                    } else {
                        addNewAlertController.textFields![0].backgroundColor = .white
                    }
                    
                    if username == "" {
                        addNewAlertController.textFields![2].backgroundColor = .red
                    } else {
                        addNewAlertController.textFields![2].backgroundColor = .white
                    }
                })
            } else {
                if port == "" { // Port is 22 by default
                    port = "22"
                }
                
                if path == "" { // Path is ~ by default
                    path = "~"
                }
                
                if let port = UInt64(port) {
                    DataManager.shared.addNew(connection: RemoteConnection(host: host, username: username, password: password, name: name, path: path, port: port))
                    
                    self.tableView.reloadData()
                    let indexPath = IndexPath(row: DataManager.shared.connections.count-1, section: 0)
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                    self.tableView(self.tableView, didSelectRowAt: indexPath)
                } else {
                    self.present(addNewAlertController, animated: true, completion: {
                        addNewAlertController.textFields![1].backgroundColor = .red
                    })
                }
            }
            
        }
        
        let editAction = UIAlertAction(title: "Save", style: .default) { (action) in // Edit selected connection
            let name = addNewAlertController.textFields![0].text!
            let host = addNewAlertController.textFields![1].text!
            var port = addNewAlertController.textFields![2].text!
            let username = addNewAlertController.textFields![3].text!
            let password = addNewAlertController.textFields![4].text!
            var path = addNewAlertController.textFields![5].text!
            
            // Check for requierd fields
            if host == "" || username == "" {
                self.present(addNewAlertController, animated: true, completion: {
                    if host == "" {
                        addNewAlertController.textFields![0].backgroundColor = .red
                    } else {
                        addNewAlertController.textFields![0].backgroundColor = .white
                    }
                    
                    if username == "" {
                        addNewAlertController.textFields![2].backgroundColor = .red
                    } else {
                        addNewAlertController.textFields![2].backgroundColor = .white
                    }
                })
            } else {
                if port == "" { // Port is 22 by default
                    port = "22"
                }
                
                if path == "" { // Path is ~ by default
                    path = "~"
                }
                
                if let port = UInt64(port) {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
                    request.returnsObjectsAsFaults = false
                    
                    do {
                        let result = try (AppDelegate.shared.coreDataContext.fetch(request) as! [NSManagedObject])[index!]
                        result.setValue(name, forKey: "name")
                        result.setValue(host, forKey: "host")
                        result.setValue(port, forKey: "port")
                        result.setValue(username, forKey: "username")
                        result.setValue(password, forKey: "password")
                        result.setValue(path, forKey: "path")
                        
                        try? AppDelegate.shared.coreDataContext.save()
                    } catch let error {
                        print("Error retrieving connections: \(error.localizedDescription)")
                    }
                    
                    self.tableView.reloadData()
                    let indexPath = IndexPath(row: DataManager.shared.connections.count-1, section: 0)
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                    self.tableView(self.tableView, didSelectRowAt: indexPath)
                } else {
                    self.present(addNewAlertController, animated: true, completion: {
                        addNewAlertController.textFields![1].backgroundColor = .red
                    })
                }
            }
            
        }
        
        if index != nil { // Edit connection
            addNewAlertController.addAction(editAction)
        } else { // Add connection
            addNewAlertController.addAction(addAction)
        }
        
        addNewAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(addNewAlertController, animated: true, completion: nil)
    }
    
    @objc func openDocuments() { // Open local documents
        navigationController?.pushViewController(LocalDirectoryTableViewController(directory: FileManager.default.documents), animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Bookmarks"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConnection))
        let viewDocumentsButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(openDocuments))
        let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.setLeftBarButtonItems([addButton, settingsButton, viewDocumentsButton], animated: true)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        // Banner ad
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.rootViewController = self
        bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Close session when coming back here
        if !DirectoryTableViewController.disconnected {
            
            ConnectionManager.shared.timer?.invalidate()
            
            if let session = ConnectionManager.shared.session {
                if session.isConnected {
                    session.disconnect()
                }
            }
            
            if let session = ConnectionManager.shared.filesSession {
                if session.isConnected {
                    session.disconnect()
                }
            }
            DirectoryTableViewController.disconnected = false
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
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "bookmark")
        cell.backgroundColor = .clear
        cell.accessoryType = .detailButton
        
        let connection = DataManager.shared.connections[indexPath.row]
        
        // Configure the cell...
        
        cell.textLabel?.text = DataManager.shared.connections[indexPath.row].name
        cell.detailTextLabel?.text = "\(connection.username)@\(connection.host):\(connection.port):\(connection.path)"
        
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
            DataManager.shared.removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
        return true
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let activityVC = ActivityViewController(message: "Connecting")
        
        self.present(activityVC, animated: true) {
            let dirVC = DirectoryTableViewController(connection: DataManager.shared.connections[indexPath.row])
            
            activityVC.dismiss(animated: true, completion: {
                tableView.deselectRow(at: indexPath, animated: true)
                
                UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    print("Expired")
                })
                
                if let delegate = self.delegate {
                    delegate.bookmarksTableViewController(self, didOpenConnection: DataManager.shared.connections[indexPath.row], inDirectoryTableViewController: dirVC)
                } else {
                    self.navigationController?.pushViewController(dirVC, animated: true)
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        showInfoAlert(editInfoAt: indexPath.row)
    }
    
    // MARK: - GADBannerViewDelegate
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Show ad only when it received
        tableView.tableHeaderView = bannerView
    }
}
