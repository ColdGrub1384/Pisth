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
import MultipeerConnectivity

/// `TableViewController` used to list, connections.
class BookmarksTableViewController: UITableViewController, GADBannerViewDelegate, UISearchBarDelegate, MCNearbyServiceBrowserDelegate {
    
    /// Delegate used.
    var delegate: BookmarksTableViewControllerDelegate?
    
    /// Ad banner view displayed as header of Table view.
    var bannerView: GADBannerView!
    
    /// Search controller used to filter connections.
    var searchController: UISearchController!
    
    /// Fetched connections by `searchController` to display.
    var fetchedConnections = [RemoteConnection]()
    
    /// Fetched nearby devices by `searchController` to display.
    var fetchedNearby = [MCPeerID]()
    
    /// Open app's settings.
    @objc func openSettings() {
        navigationController?.pushViewController(UIViewController.settings, animated: true)
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
        
        let editConnectionVC = UIViewController.connectionInfo
        
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
        
        // Multipeer connectivity
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "terminal")
        mcNearbyServiceBrowser.delegate = self
        mcNearbyServiceBrowser.startBrowsingForPeers()
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
    /// - Returns: `2`.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    /// `UITableViewController`'s `tableView(_:, titleForHeaderInSection:)` function.
    ///
    /// - Returns: ``"Connections"` or `"Nearby Devices"` if there are nearby devices.
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard (devices.count > 0) else {
            return nil
        }
        
        if section == 0 {
            return "Connections"
        } else if section == 1 {
            return "Nearby Devices"
        }
        
        return nil
    }

    /// `UITableViewController`'s `tableView(_:, numberOfRowsInSection:)` function.
    ///
    /// - Returns: number of connections or number of fetched connections with `searchController`.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                return fetchedConnections.count
            }
            
            return DataManager.shared.connections.count
        } else if section == 1 {
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                return fetchedNearby.count
            }
            
            return devices.count
        }
        
        return 0
    }

    /// `UITableViewController`'s `tableView(_:, cellForRowAt:)` function.
    ///
    /// - Returns: A cell with with title as the connection's nickname and subtitle as connection's details.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "bookmark")
        cell.backgroundColor = .clear
        
        // Connections
        if indexPath.section == 0 {
            
            cell.accessoryType = .detailButton
            
            var connection = DataManager.shared.connections[indexPath.row]
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                connection = fetchedConnections[indexPath.row]
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
            
        // Near devices
        } else if indexPath.section == 1 {
            
            var devices = self.devices
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                devices = fetchedNearby
            }
            
            cell.textLabel?.text = devices[indexPath.row].displayName
            cell.textLabel?.textColor = .white
        }
        
        return cell
    }
    
    /// `UITableViewController`'s `tableView(_:, canEditRowAt:)` function.
    ///
    /// - Returns: `true` for first section.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
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
    /// Allow moving rows for first section.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 0)
    }
    
    
    // MARK: - Table view delegate
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// Connect to selected connection.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 { // Open connection
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
                    connection = fetchedConnections[indexPath.row]
                }
                
                searchController.dismiss(animated: true, completion: {
                    open()
                })
            } else {
                open()
            }
        } else if indexPath.section == 1 { // Multipeer connectivity
            
            ConnectionManager.shared.connection = nil
            
            var termVC: TerminalViewController
            
            if #available(iOS 11, *) {
                termVC = TerminalViewControllerIOS11()
            } else {
                termVC = TerminalViewController()
            }
            
            termVC.pureMode = true
            termVC.viewer = true
            termVC.peerID = peerID
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            self.navigationController?.pushViewController(termVC, animated: true, completion: {
                self.mcNearbyServiceBrowser.invitePeer(self.devices[indexPath.row], to: termVC.mcSession, withContext: nil, timeout: 10)
            })
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
        
        fetchedConnections = []
        fetchedNearby = []
        
        if !searchText.isEmpty {
            
            for connection in DataManager.shared.connections {
                if connection.name.lowercased().contains(searchText.lowercased()) || connection.host.lowercased().contains(searchText.lowercased()) || connection.username.lowercased().contains(searchText.lowercased()) || connection.path.lowercased().contains(searchText.lowercased()) || "\(connection.port)".contains(searchText) {
                    
                    fetchedConnections.append(connection)
                    
                }
                
            }
            
            for device in devices {
                if device.displayName.lowercased().contains(searchText.lowercased()) {
                    fetchedNearby.append(device)
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
    
    // MARK: - Multipeer connectivity
    
    /// Near devices.
    var devices = [MCPeerID]()
    
    /// Current device ID.
    var peerID: MCPeerID!
    
    /// Browser for near devices.
    var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    
    /// `MCNearbyServiceBrowserDelegate`'s `browser(_:, foundPeer:, withDiscoveryInfo:)` function.
    ///
    /// Display found peer.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        if !devices.contains(peerID) {
            devices.append(peerID)
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: devices.count-1, section: 1)], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    /// `MCNearbyServiceBrowserDelegate`'s `browser(_:, lostPeer:)` function.
    ///
    /// Hide lost peer.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        if let i = devices.index(of: peerID) {
            devices.remove(at: i)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: i, section: 1)], with: .automatic)
            tableView.endUpdates()
        }
    }
}
