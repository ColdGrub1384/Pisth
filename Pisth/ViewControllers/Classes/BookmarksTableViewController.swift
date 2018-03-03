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
import BiometricAuthentication

/// `TableViewController` used to list, connections.
class BookmarksTableViewController: UITableViewController, GADBannerViewDelegate, UISearchBarDelegate {
    
    /// Delegate used.
    var delegate: BookmarksTableViewControllerDelegate?
    
    /// Ad banner view displayed as header of Table view.
    var bannerView: GADBannerView!
    
    /// Search controller used to filter connections.
    var searchController: UISearchController!
    
    /// Fetched connections by `searchController` to display.
    var fetched = [RemoteConnection]()
    
    /// Open app's settings.
    @objc func openSettings() {
        navigationController?.pushViewController(UIStoryboard(name: "Settings", bundle: Bundle.main).instantiateInitialViewController()!, animated: true)
    }
    
    /// Open local documents.
    @objc func openDocuments() {
        navigationController?.pushViewController(LocalDirectoryTableViewController(directory: FileManager.default.documents), animated: true)
    }
    
    /// Add connection.
    @objc func addConnection() {
        showInfoAlert()
    }
    
    /// Edit connection or create connnection.
    ///
    /// If `index` is nil, a connection will be created, else, the connection at given index will be edited.
    ///
    /// - Parameters:
    ///     - index: Index of connection to edit.
    func showInfoAlert(editInfoAt index: Int? = nil) {
        
        guard let editConnectionVC = UIStoryboard(name: "ConnectionInfoTableViewController", bundle: Bundle.main).instantiateInitialViewController() as? ConnectionInformationTableViewController else {
            return
        }
        
        if let index = index {
            editConnectionVC.connection = DataManager.shared.connections[index]
            editConnectionVC.index = index
        }
        
        navigationController?.pushViewController(editConnectionVC, animated: true)
    }
    
    
    // MARK: - View controller
    
    /// `UIViewController`s `viewDidLoad` function.
    ///
    /// Setup views.
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
        if !UserDefaults.standard.bool(forKey: "terminalThemesPurchased") {
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.rootViewController = self
            bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
            bannerView.delegate = self
            bannerView.load(GADRequest())
        }
        
        // Search
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        }
    }
    
    /// `UIViewController`'s `viewDidAppear(_:)` function.
    ///
    /// Close opened connections did back here.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Close session when coming back here
        
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
        
        tableView.reloadData()
        
        ConnectionManager.shared.session = nil
        ConnectionManager.shared.filesSession = nil
        ConnectionManager.shared.result = .notConnected
        if let task = ConnectionManager.shared.backgroundTask {
            UIApplication.shared.endBackgroundTask(task)
            ConnectionManager.shared.backgroundTask = nil
        }
    }
    
    
    // MARK: - Table view data source

    /// `UITableViewController`'s `numberOfSections(in:)` function.
    ///
    /// - Returns: `1`.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// `UITableViewController`'s `tableView(_:, numberOfRowsInSection:)` function.
    ///
    /// - Returns: number of connections or number of fetched connections with `searchController`.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            return fetched.count
        }
        
        return DataManager.shared.connections.count
    }

    /// `UITableViewController`'s `tableView(_:, cellForRowAt:)` function.
    ///
    /// - Returns: A cell with with title as the connection's nickname and subtitle as connection's details.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "bookmark")
        cell.backgroundColor = .clear
        cell.accessoryType = .detailButton
        
        var connection = DataManager.shared.connections[indexPath.row]
        
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
           connection = fetched[indexPath.row]
        }
        
        // Configure the cell...
        
        cell.textLabel?.text = connection.name
        cell.detailTextLabel?.text = "\(connection.username)@\(connection.host):\(connection.port):\(connection.path)"
        if let os = connection.os?.lowercased() {
            cell.imageView?.image = UIImage(named: (os.slice(from: " id=", to: " ")?.replacingOccurrences(of: "\"", with: "") ?? os).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: ""))
        }
        
        // If the connection has no name, set the title as username@host
        if cell.textLabel?.text == "" {
            cell.textLabel?.text = cell.detailTextLabel?.text
            cell.detailTextLabel?.text = ""
        }
        
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        
        return cell
    }
    
    /// `UITableViewController`'s `tableView(_:, canEditRowAt:)` function.
    ///
    /// - Returns: `true` to allow editing.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// `UITableViewController`'s `tableView(_:, commit:, forRowAt:)` function.
    ///
    /// Remove connection.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DataManager.shared.removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    /// `UITableViewController`'s `tableView(_:, moveRowAt:, to:)` function.
    ///
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
    /// Allow moving rows.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // MARK: - Table view delegate
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// Connect to selected connection.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var connection = DataManager.shared.connections[indexPath.row]
        
        /// Open connection.
        func connect() {
            let activityVC = ActivityViewController(message: "Connecting")
            self.present(activityVC, animated: true) {
                if DataManager.shared.connections[indexPath.row].useSFTP {
                    let dirVC = DirectoryTableViewController(connection: connection)
                    
                    activityVC.dismiss(animated: true, completion: {
                        tableView.deselectRow(at: indexPath, animated: true)
                        
                        if let delegate = self.delegate {
                            delegate.bookmarksTableViewController(self, didOpenConnection: connection, inDirectoryTableViewController: dirVC)
                        } else {
                            self.navigationController?.pushViewController(dirVC, animated: true)
                        }
                    })
                } else {
                    ConnectionManager.shared.connection = connection
                    ConnectionManager.shared.connect()
                    
                    var termVC = TerminalViewController()
                    
                    if #available(iOS 11, *) {
                        termVC = TerminalViewControllerIOS11()
                    }
                    
                    termVC.pureMode = true
                                        
                    activityVC.dismiss(animated: true, completion: {
                        tableView.deselectRow(at: indexPath, animated: true)
                        
                        if let delegate = self.delegate {
                            delegate.bookmarksTableViewController(self, didOpenConnection: connection, inTerminalViewController: termVC)
                        } else {
                            self.navigationController?.pushViewController(termVC, animated: true)
                        }
                    })
                }
            }
        }
        
        /// Ask for password if biometric auth failed.
        func askForPassword() {
            let passwordAlert = UIAlertController(title: "Enter Password", message: "Enter Password for user '\(connection.username)'", preferredStyle: .alert)
            passwordAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
            })
            passwordAlert.addAction(UIAlertAction(title: "Connect", style: .default, handler: { (_) in
                connection.password = passwordAlert.textFields![0].text!
                connect()
            }))
            passwordAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                tableView.deselectRow(at: indexPath, animated: true)
            }))
            self.present(passwordAlert, animated: true, completion: nil)
        }
        
        /// Open connection or ask for biometric authentication.
        func open() {
            if UserDefaults.standard.bool(forKey: "biometricAuth") {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "Authenticate to connect", fallbackTitle: "Enter Password", cancelTitle: nil, success: {
                    connect()
                }, failure: { (error) in
                    if error != .canceledByUser && error != .canceledBySystem {
                        askForPassword()
                    } else {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                })
            } else {
                connect()
            }
        }
        
        if searchController.isActive {
            if searchController.searchBar.text != "" {
                connection = fetched[indexPath.row]
            }
            
            searchController.dismiss(animated: true, completion: {
                open()
            })
        } else {
            open()
        }
    }
    
    /// `UITableViewController`'s `tableView(_:, accessoryButtonTappedForRowWith:)`
    ///
    /// Show connection information.
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if searchController.isActive {
            searchController.dismiss(animated: true, completion: {
                self.showInfoAlert(editInfoAt: indexPath.row)
            })
        } else {
            showInfoAlert(editInfoAt: indexPath.row)
        }
    }
    
    
    // MARK: - Banner view delegate
    
    /// `GADBannerViewDelegate`'s `adViewDidReceiveAd(_:)` function.
    /// Show ad did it's received.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        tableView.tableHeaderView = bannerView
    }
    
    // MARK: Search bar delegate
    
    /// `UISearchBarDelegate`'s `searchBar(_:, textDidChange:)` function.
    ///
    /// Search for connection.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        fetched = []
        
        if !searchText.isEmpty {
            
            for connection in DataManager.shared.connections {
                if connection.name.lowercased().contains(searchText.lowercased()) || connection.host.lowercased().contains(searchText.lowercased()) || connection.username.lowercased().contains(searchText.lowercased()) || connection.path.lowercased().contains(searchText.lowercased()) || "\(connection.port)".contains(searchText) {
                    
                    fetched.append(connection)
                    
                }
                
            }
        }
        
        tableView.reloadData()
    }
    
    /// `UISearchBarDelegate`'s `searchBarCancelButtonClicked(_:)` function.
    ///
    /// Reset connections.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            self.tableView.reloadData()
        })
    }
}
