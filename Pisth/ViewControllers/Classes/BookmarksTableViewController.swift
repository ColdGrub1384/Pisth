// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import CoreData
import SwiftKeychainWrapper
import BiometricAuthentication
import MultipeerConnectivity
import Pisth_Shared
import LibTermCore
import ios_system

/// `TableViewController` used to list, connections.
class BookmarksTableViewController: UITableViewController, UISearchBarDelegate, MCNearbyServiceBrowserDelegate, NetServiceBrowserDelegate, NetServiceDelegate {
    
    /// Delegate used.
    var delegate: BookmarksTableViewControllerDelegate?
    
    /// Search controller used to filter connections.
    var searchController: UISearchController!
    
    private var localTermFound = true
    
    /// Fetched connections by `searchController` to display.
    var fetchedConnections = [RemoteConnection]()
    
    /// Fetched nearby devices by `searchController` to display.
    var fetchedNearby = [MCPeerID]()
    
    /// Fetched nearby bonjour servers by `searchController` to display.
    var fetchedServices = [NetService]()
    
    /// Browser used to find services trough Bonjour.
    let serviceBrowser = NetServiceBrowser()
    
    /// Returns `true` if the view saying that there is no bookmarks should be shown.
    var shouldShowBackgroundView: Bool {
        return (DataManager.shared.connections.count == 0 && devices.count == 0 && services.count == 0 || tableView.backgroundView is UIVisualEffectView || tableView.backgroundView?.tag == 1)
    }
    
    /// Open app's settings.
    @objc func openSettings() {
        let navVC = UINavigationController(rootViewController: UIViewController.settings)
        navVC.modalPresentationStyle = .formSheet
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Open local documents.
    @objc func openDocuments() {
        navigationController?.pushViewController(LocalDirectoryCollectionViewController(directory: FileManager.default.documents), animated: true)
    }
    
    /// Add connection.
    @objc func addConnection() {
        showInfoAlert()
    }
    
    /// Open the shell.
    func openShell() {
        
        if ConnectionManager.shared.session?.isConnected == true {
            ConnectionManager.shared.session?.disconnect()
        }
        if ConnectionManager.shared.filesSession?.isConnected == true {
            ConnectionManager.shared.filesSession?.disconnect()
        }
        ConnectionManager.shared.session = nil
        ConnectionManager.shared.filesSession = nil
        
        let theme = TerminalTheme.themes[UserKeys.terminalTheme.stringValue ?? "Pisth"] ?? ProTheme()
        
        var preferences = LTTerminalViewController.Preferences()
        if let foreground = theme.foregroundColor {
            print(foreground.hexString)
            preferences.foregroundColor = foreground
            print(preferences.foregroundColor.hexString)
        }
        if let background = theme.backgroundColor {
            preferences.backgroundColor = background
        }
        preferences.keyboardAppearance = theme.keyboardAppearance
        preferences.barStyle = theme.toolbarStyle
        preferences.caretStyle = .block
        
        let term = LTTerminalViewController.makeTerminal(preferences: preferences)
        
        initializeEnvironment()
        AppDelegate.shared.navigationController.setViewControllers([term], animated: true)
        
        term.navigationItem.leftBarButtonItem = AppDelegate.shared.showBookmarksBarButtonItem
    }
    
    /// Edit connection or create connnection.
    ///
    /// If `index` is nil, a connection will be created, else, the connection at given index will be edited.
    ///
    /// - Parameters:
    ///     - index: Index of connection to edit.
    func showInfoAlert(editInfoAt index: Int? = nil) {
        
        let editConnectionVC = UIViewController.connectionInfo
        editConnectionVC.rootTableView = tableView
        
        if let index = index {
            editConnectionVC.connection = DataManager.shared.connections[index]
            editConnectionVC.index = index
        }
        
        let navVC = UINavigationController(rootViewController: editConnectionVC)
        navVC.modalPresentationStyle = .formSheet
        
        present(navVC, animated: true, completion: nil)
    }
    
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizable.BookmarksTableViewController.bookmarksTitle
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConnection))
        let viewDocumentsButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(openDocuments))
        let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        
        clearsSelectionOnViewWillAppear = false
        navigationItem.rightBarButtonItem = editButtonItem
        if !isShell {
            navigationItem.setLeftBarButtonItems([addButton, settingsButton, viewDocumentsButton], animated: true)
        } else {
            navigationItem.setLeftBarButtonItems([addButton], animated: true)
        }
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.backgroundView = Bundle.main.loadNibNamed("No Connections", owner: nil, options: nil)?.first as? UIView
        if isShell {
            if #available(iOS 11.0, *) {
                tableView.backgroundColor = shellBackgroundColor
            }
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
        
        // Bonjour
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_ssh._tcp.", inDomain: "local.")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AppDelegate.shared.splitViewController.isCollapsed, let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
        
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if !isShell {
            return .default
        } else {
            return .lightContent
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if delegate is AppDelegate || AppDelegate.shared.action != nil {
            return 1
        }
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard (devices.count > 0 || services.count > 0) else {
            return nil
        }
        
        if section == 1 {
            return Localizable.BookmarksTableViewController.connectionsTitle
        } else if section == 2 {
            return Localizable.BookmarksTableViewController.devicesTitle
        }
        
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        tableView.backgroundView?.isHidden = !shouldShowBackgroundView
        
        if section == 0 {
            return 1
        } else if section == 1 {
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                return fetchedConnections.count
            }
            
            return DataManager.shared.connections.count
        } else if section == 2 {
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                return fetchedNearby.count+fetchedServices.count
            }
            
            return devices.count+services.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "bookmark")
        cell.backgroundColor = .clear
        if isShell {
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .white
        }
        
        // Local
        if indexPath.section == 0 {
            
            cell.textLabel?.text = UIDevice.current.name
            cell.detailTextLabel?.text = "mobile@localhost/Documents"
            if UIDevice.current.userInterfaceIdiom == .pad {
                cell.imageView?.image = UIImage(named: "OnMyiPad_Normal")
            } else if UIDevice.current.userInterfaceIdiom == .phone {
                cell.imageView?.image = UIImage(named: "OnMyiPhone_Normal")
            }
            
            cell.isHidden = !localTermFound
            
            return cell
            
        // Connections
        } else if indexPath.section == 1 {
            
            cell.accessoryType = .detailButton
            
            var connection = DataManager.shared.connections[indexPath.row]
            
            if delegate is AppDelegate && !connection.useSFTP {
                cell.contentView.alpha = 0.5
            }
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                connection = fetchedConnections[indexPath.row]
            }
            
            // Configure the cell...
            
            cell.textLabel?.text = connection.name
            var username: String? {
                if connection.username.isEmpty {
                    return nil
                } else {
                    return connection.username+"@"
                }
            }
            cell.detailTextLabel?.text = "\(username ?? "")\(connection.host):\(connection.port):\(connection.path)"
            if let os = connection.os?.lowercased() {
                cell.imageView?.ignoresInvertColors = true
                cell.imageView?.image = UIImage(named: (os.slice(from: " id=", to: " ")?.replacingOccurrences(of: "\"", with: "") ?? os).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: ""))
            }
            
            // If the connection has no name, set the title as username@host
            if cell.textLabel?.text == "" {
                cell.textLabel?.text = cell.detailTextLabel?.text
                cell.detailTextLabel?.text = ""
            }
                        
        // Near devices
        } else if indexPath.section == 2 {
            
            var devices = self.devices
            var services = self.services
            
            if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
                devices = fetchedNearby
                services = fetchedServices
            }
            
            var all = [Any]()
            for device in devices {
                all.append(device)
            }
            for service in services {
                all.append(service)
            }
            
            if let peer = all[indexPath.row] as? MCPeerID {
                cell.textLabel?.text = peer.displayName
            } else if let service = all[indexPath.row] as? NetService {
                cell.textLabel?.text = service.name
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.section == 1)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DataManager.shared.removeConnection(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.backgroundView?.isHidden = !shouldShowBackgroundView
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
        return (indexPath.section == 1)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        AppDelegate.shared.navigationController.setNavigationBarHidden(false, animated: true)
        if !isShell {
            AppDelegate.shared.navigationController.navigationBar.barStyle = .default
        } else {
            AppDelegate.shared.navigationController.navigationBar.barStyle = .black
        }
        AppDelegate.shared.navigationController.navigationBar.isTranslucent = true
        
        if indexPath.section == 0 { // Open local terminal
            openShell()
        } else if indexPath.section == 1 { // Open connection
            var connection = DataManager.shared.connections[indexPath.row]

            /// Open connection.
            func connect() {
                let activityVC = ActivityViewController(message: Localizable.BookmarksTableViewController.connecting)
                var vc: UIViewController
                if view.window != nil {
                    vc = self
                } else {
                    vc = UIApplication.shared.keyWindow?.rootViewController ?? self
                }
                vc.present(activityVC, animated: true) {
                    
                    ConnectionManager.shared.session = nil
                    ConnectionManager.shared.filesSession = nil
                    ConnectionManager.shared.result = .notConnected
                    
                    ContentViewController.shared.closeAllPinnedPanels()
                    ContentViewController.shared.closeAllFloatingPanels()
                    
                    if connection.useSFTP {
                        
                        let dirVC = DirectoryCollectionViewController(connection: connection)
                        
                        activityVC.dismiss(animated: true, completion: {
                            
                            AppDelegate.shared.splitViewController.setDisplayMode()
                            
                            if let delegate = self.delegate {
                                delegate.bookmarksTableViewController(self, didOpenConnection: connection, inDirectoryCollectionViewController: dirVC)
                            } else {
                                AppDelegate.shared.navigationController.setViewControllers([dirVC], animated: true)
                            }
                        })
                    } else {
                        ConnectionManager.shared.connection = connection
                        ConnectionManager.shared.connect()
                        
                        let termVC = TerminalViewController()
                        termVC.pureMode = true
                        
                        activityVC.dismiss(animated: true, completion: {
                            
                            AppDelegate.shared.splitViewController.setDisplayMode()
                            
                            if let delegate = self.delegate {
                                delegate.bookmarksTableViewController(self, didOpenConnection: connection, inTerminalViewController: termVC)
                            } else {
                                AppDelegate.shared.navigationController.setViewControllers([termVC], animated: true)
                                
                            }
                        })
                    }
                }
            }
            
            /// Ask for password if biometric auth failed.
            func askForPassword() {
                let passwordAlert = UIAlertController(title: Localizable.BookmarksTableViewController.enterPasswordTitle, message: Localizable.BookmarksTableViewController.enterPasswordMessage(for: connection.username), preferredStyle: .alert)
                passwordAlert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = Localizable.AppDelegate.passwordPlaceholder
                    textField.isSecureTextEntry = true
                })
                passwordAlert.addAction(UIAlertAction(title: Localizable.AppDelegate.connect, style: .default, handler: { (_) in
                    connection.password = passwordAlert.textFields![0].text!
                    connect()
                }))
                passwordAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: { (_) in
                    tableView.deselectRow(at: indexPath, animated: true)
                }))
                self.present(passwordAlert, animated: true, completion: nil)
            }
            
            func askForCredentials() {
                var name: String? {
                    if connection.name.isEmpty {
                        return nil
                    } else {
                        return connection.name
                    }
                }
                let alert = UIAlertController(title: Localizable.BookmarksTableViewController.enterCredentials, message: Localizable.BookmarksTableViewController.enterCredentials(for: name ?? connection.host), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localizable.connect, style: .default, handler: { (_) in
                    connection.username = alert.textFields?.first?.text ?? connection.name
                    connection.password = alert.textFields?.last?.text ?? connection.password
                    connect()
                }))
                alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: { _ in
                    tableView.deselectRow(at: indexPath, animated: true)
                }))
                alert.addTextField { (usernameTextField) in
                    usernameTextField.placeholder = Localizable.AppDelegate.usernamePlaceholder
                    usernameTextField.text = connection.username
                }
                alert.addTextField { (passwordTextField) in
                    passwordTextField.placeholder = Localizable.AppDelegate.passwordPlaceholder
                    passwordTextField.text = connection.password
                    passwordTextField.isSecureTextEntry = true
                }
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            
            /// Open connection or ask for biometric authentication.
            func open() {
                if UserKeys.isBiometricAuthenticationEnabled.boolValue {
                    BioMetricAuthenticator.authenticateWithBioMetrics(reason: Localizable.BookmarksTableViewController.authenticateToConnect, fallbackTitle: Localizable.BookmarksTableViewController.enterPassword, cancelTitle: nil, success: {
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
            
            func openConnection() {
                if connection.username.isEmpty || connection.host.isEmpty {
                    askForCredentials()
                } else {
                    open()
                }
            }
            
            if searchController.isActive {
                if searchController.searchBar.text != "" {
                    connection = fetchedConnections[indexPath.row]
                }
                
                searchController.dismiss(animated: true, completion: {
                    openConnection()
                })
            } else {
                openConnection()
            }
        } else if indexPath.section == 1 {
            var all = [Any]()
            for device in devices {
                all.append(device)
            }
            for service in services {
                all.append(service)
            }
            
            if let peer = all[indexPath.row] as? MCPeerID { // Multipeer connectivity
            
                ConnectionManager.shared.connection = nil
                
                let termVC = TerminalViewController()
                
                termVC.pureMode = true
                termVC.viewer = true
                termVC.peerID = peerID
                
                AppDelegate.shared.splitViewController.setDisplayMode()
                AppDelegate.shared.navigationController.setViewControllers([termVC], animated: true)
                
                _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                    self.mcNearbyServiceBrowser.invitePeer(peer, to: termVC.mcSession, withContext: nil, timeout: 10)
                })
            } else if let service = all[indexPath.row] as? NetService { // Bonjour
                tableView.deselectRow(at: indexPath, animated: true)
                if service.port == -1 {
                    service.delegate = self
                    service.resolve(withTimeout: 0)
                } else {
                    netServiceDidResolveAddress(service)
                }
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if searchController.isActive {
            searchController.dismiss(animated: true, completion: {
                self.showInfoAlert(editInfoAt: indexPath.row)
            })
        } else {
            showInfoAlert(editInfoAt: indexPath.row)
        }
    }
    
    // MARK: Search bar delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        fetchedConnections = []
        fetchedNearby = []
        fetchedServices = []
        
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
            
            for service in services {
                if service.name.lowercased().contains(searchText.lowercased()) {
                    fetchedServices.append(service)
                }
            }
            
            localTermFound = (UIDevice.current.name.lowercased().contains(searchText.lowercased()) || "mobile@localhost/documents".contains(searchText.lowercased()))
        }
        
        tableView.reloadData()
    }
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
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        if !devices.contains(peerID) && peerID.displayName != self.peerID.displayName {
            devices.append(peerID)
            
            tableView.reloadSections(IndexSet(arrayLiteral: 2), with: .automatic)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        guard peerID.displayName != self.peerID.displayName else {
            return
        }
        
        if let i = devices.index(of: peerID) {
            devices.remove(at: i)
            
            tableView.reloadSections(IndexSet(arrayLiteral: 2), with: .automatic)
        }
    }
    
    // MARK: - Bonjour
    
    /// Services found by Bonjour for SSH.
    var services = [NetService]()
    
    // MARK: - Net service browser delegate
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        guard !services.contains(service), tableView.numberOfSections > 1 else {
            return
        }
        
        services.append(service)
        tableView.reloadSections(IndexSet(arrayLiteral: 2), with: .automatic)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let i = services.firstIndex(of: service), tableView.numberOfSections > 1 {
            services.remove(at: i)
            tableView.reloadSections(IndexSet(arrayLiteral: 2), with: .automatic)
        }
    }
    
    // MARK: - Net service delegate
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        
        guard let hostname = sender.hostName else {
            return
        }
        
        var url_: URL?
        if !isShell {
             url_ = URL(string: "sftp://\(hostname):\(sender.port)")
        } else {
            url_ = URL(string: "ssh://\(hostname):\(sender.port)")
        }
        
        guard let url = url_ else {
            return
        }
        _ = AppDelegate.shared.application(UIApplication.shared, open: url, options: [:])
    }
}
