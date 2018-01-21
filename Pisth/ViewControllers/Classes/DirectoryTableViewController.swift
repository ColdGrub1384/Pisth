// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import GoogleMobileAds
import NMSSH

/// Table view controller to manage remote files.
class DirectoryTableViewController: UITableViewController, LocalDirectoryTableViewControllerDelegate, DirectoryTableViewControllerDelegate, GADBannerViewDelegate {
    
    /// Directory used to list files.
    var directory: String
    
    /// Connection to open if is not.
    var connection: RemoteConnection
    
    /// Fetched files.
    var files: [NMSFTPFile]?
    
    /// Delegate used.
    var delegate: DirectoryTableViewControllerDelegate?
    
    /// Close after sending file.
    var closeAfterSending = false
    
    /// Ad banner view displayed at top of table view.
    var bannerView: GADBannerView!
    
    /// Init with given connection and directory.
    ///
    /// - Parameters:
    ///     - connection: Connection to be opened if is not.
    ///     - directory: Directory to open, by default, is `connection`'s default path.
    ///
    /// - Returns: A Directory table view controller at given directory.
    init(connection: RemoteConnection, directory: String? = nil) {
        self.connection = connection
        ConnectionManager.shared.connection = connection
        
        if directory == nil {
            self.directory = connection.path
        } else {
            self.directory = directory!
        }
        
        if !Reachability.isConnectedToNetwork() {
            ConnectionManager.shared.result = .notConnected
        } else {
            if ConnectionManager.shared.session == nil && ConnectionManager.shared.filesSession == nil {
                ConnectionManager.shared.connect()
            }
        }
        
        if ConnectionManager.shared.result == .connectedAndAuthorized {
            if self.directory.contains("~") { // Get absolute path from ~
                if let path = try? ConnectionManager.shared.filesSession!.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "") {
                    self.directory = self.directory.replacingOccurrences(of: "~", with: path)
                }
            }
            
            let files = ConnectionManager.shared.files(inDirectory: self.directory)
            self.files = files
            
            guard self.files != nil else {
                super.init(style: .plain)
                return
            }
                
            if self.directory.removingUnnecessariesSlashes != "/" {
                // Append parent directory
                guard let parent = ConnectionManager.shared.filesSession!.sftp.infoForFile(atPath: self.directory.nsString.deletingLastPathComponent) else {
                    super.init(style: .plain)
                    return
                }
                self.files!.append(parent)
            }
            
            // TODO: - Make it compatible with only SFTP
            // Ignore files listed in ~/.pisthignore
            /*if let result = try? ConnectionManager.shared.filesSession!.channel.execute("cat ~/.pisthignore") {
                for file in result.components(separatedBy: "\n") {
                    if file != "" && !file.hasSuffix("#") {
                        
                        if let files = self.files {
                            var i = 0
                            for file_ in files {
                                if file_.filename == file {
                                    self.files!.remove(at: i)
                                    self.isDir.remove(at: i)
                                }
                                i += 1
                            }
                        }
                    }
                }
            }*/
        }
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleComponents = directory.components(separatedBy: "/")
        title = titleComponents.last
        if directory.hasSuffix("/") {
            title = titleComponents[titleComponents.count-2]
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // TableView cells
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "file")
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        // Initialize the refresh control.
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.white
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        
        // Bar buttons
        let uploadFile = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadFile(_:)))
        let terminal = UIBarButtonItem(image: #imageLiteral(resourceName: "terminal"), style: .plain, target: self, action: #selector(openShell))
        let git = UIBarButtonItem(title: "Git", style: .plain, target: self, action: #selector(self.git))
        var buttons: [UIBarButtonItem] {
            guard files != nil else { return [uploadFile, terminal] }
            guard let session = ConnectionManager.shared.filesSession else { return [uploadFile, terminal] }
            guard let result = try? session.channel.execute("ls -1a '\(directory)'").replacingOccurrences(of: "\r", with: "") else { return [] }
            let allFiles = result.components(separatedBy: "\n")
            if allFiles.contains(".git") {
                return [uploadFile, git, terminal]
            } else {
                return [uploadFile, terminal]
            }
        }
        navigationItem.setRightBarButtonItems(buttons, animated: true)
        
        // Banner ad
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.rootViewController = self
        bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Connection errors
        checkForConnectionError(errorHandler: {
            self.showError()
        }) {
            if self.files == nil {
                self.navigationController?.popViewController(animated: true, completion: {
                    let alert = UIAlertController(title: "Error opening directory!", message: "Check for permissions.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                })
            }
        }
    }

    // MARK: - Connection errors handling
    
    /// Go back and show error.
    func showError() {
        guard let navVC = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return }
        let result = ConnectionManager.shared.result
        
        var alert: UIAlertController!
        switch result {
        case .notConnected:
            alert = UIAlertController(title: "Error opening session!", message: "Unable to connect, check for your internet connection and the IP address or hostname.\nIf you can't connect with the IP address, try with the hostname.", preferredStyle: .alert)
        case .connected:
            alert = UIAlertController(title: "Error opening session!", message: "Unable to authenticate, check for username and password.", preferredStyle: .alert)
        default:
            alert = UIAlertController(title: "Error opening session!", message: "Unable to authenticate, check for username and password.", preferredStyle: .alert)
        }
        
        if alert != nil {
            navVC.popToRootViewController(animated: true, completion: {
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    /// Check for connection errors and run handler if there is an error.
    func checkForConnectionError(errorHandler: @escaping () -> Void, successHandler: (() -> Void)? = nil) {
        guard let session = ConnectionManager.shared.filesSession else {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        if !Reachability.isConnectedToNetwork() {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        if !session.isConnected || !session.isAuthorized {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        if let handler = successHandler {
            handler()
        }
    }
    
    
    // MARK: - Actions
    
    /// Dismiss `navigationController`.
    @objc func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    /// Open source control manager for Git repos.
    @objc func git() {
        guard let navVC = UIStoryboard(name: "Git", bundle: Bundle.main).instantiateInitialViewController() as? UINavigationController else { return }
        guard let branchesVC = navVC.topViewController as? SourceControlTableViewController else { return }
        
        branchesVC.repoPath = directory
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Reload content.
    @objc func reload() { // Reload current directory content
        
        self.files = nil
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        guard ConnectionManager.shared.filesSession != nil else { return }
        let files = ConnectionManager.shared.files(inDirectory: self.directory)
        self.files = files
            
        if self.directory.removingUnnecessariesSlashes != "/" {
            // Append parent directory
            guard let parent = ConnectionManager.shared.filesSession!.sftp.infoForFile(atPath: self.directory.nsString.deletingLastPathComponent) else { return }
            self.files!.append(parent)
        }
        
        // TODO: Make it compatible with SFTP only
        // Ignore files listed in ~/.pisthignore
        /*if let result = try? ConnectionManager.shared.filesSession!.channel.execute("cat ~/.pisthignore") {
            for file in result.components(separatedBy: "\n") {
                if file != "" && !file.hasSuffix("#") {
                    
                    if let indexOfFile = self.files?.index(of: self.directory.nsString.appendingPathComponent(file)) {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                    
                    if let indexOfFile = self.files?.index(of: self.directory.nsString.appendingPathComponent(file)+"/") {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                    
                    if let indexOfFile = self.files?.index(of: "."+self.directory.nsString.appendingPathComponent(file)) {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                }
            }
        }*/
        
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    
    /// Open shell in current directory.
    @objc func openShell() {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        let terminalVC = TerminalViewController()
        terminalVC.pwd = directory
        navigationController?.pushViewController(terminalVC, animated: true)
    }
    
    /// Show an alert to choose if import a file, create blank file, or create directory.
    ///
    /// - Parameters:
    ///     - sender: Send bar button item.
    @objc func uploadFile(_ sender: UIBarButtonItem) {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        let chooseAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        chooseAlert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in // Upload file
            let localDirVC = LocalDirectoryTableViewController(directory: FileManager.default.documents)
            localDirVC.delegate = self
            
            self.navigationController?.pushViewController(localDirVC, animated: true)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Create blank file", style: .default, handler: { (_) in // Create file
            
            let chooseName = UIAlertController(title: "Create blank file", message: "Choose new file name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                
                let newPath = self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)
                
                guard let result = ConnectionManager.shared.filesSession?.sftp.writeFile(atPath: Bundle.main.path(forResource: "empty", ofType: nil), toFileAtPath: newPath) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error creating file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
            }))
            
            self.present(chooseName, animated: true, completion: nil)
            
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Create folder", style: .default, handler: { (_) in // Create folder
            let chooseName = UIAlertController(title: "Create folder", message: "Choose new folder name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New folder name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error creating directory!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        chooseAlert.popoverPresentationController?.barButtonItem = sender
        
        self.present(chooseAlert, animated: true, completion: nil)
    }
    
    /// Copy file in current directory
    @objc func copyFile() {
        DirectoryTableViewController.action = .none
        navigationController?.dismiss(animated: true, completion: {
            
            self.checkForConnectionError(errorHandler: {
                self.showError()
            })
            
            let progress = UIAlertController(title: "Copying...", message: "", preferredStyle: .alert)
            
            UIApplication.shared.keyWindow?.rootViewController?.present(progress, animated: true, completion: {
                guard let result = ConnectionManager.shared.filesSession?.sftp.copyContents(ofPath: Pasteboard.local.filePath!, toFileAtPath: self.directory.nsString.appendingPathComponent(Pasteboard.local.filePath!.nsString.lastPathComponent), progress: { (receivedBytes, bytesToBeReceived) -> Bool in
                    
                    let received = ByteCountFormatter().string(fromByteCount: Int64(receivedBytes))
                    let toBeReceived = ByteCountFormatter().string(fromByteCount: Int64(bytesToBeReceived))
                    
                    DispatchQueue.main.async {
                        progress.message = "\(received) / \(toBeReceived)"
                    }
                    
                    return true
                }) else {
                    progress.dismiss(animated: true, completion: nil)
                    return
                }
                
                progress.dismiss(animated: true, completion: {
                    if !result {
                        let errorAlert = UIAlertController(title: "Error copying file!", message: nil, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                    }
                })
                
                if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
                    dirVC.reload()
                }
                
                Pasteboard.local.filePath = nil
            })
            
        })
    }
    
    /// Move file in current directory
    @objc func moveFile() {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        DirectoryTableViewController.action = .none
        navigationController?.dismiss(animated: true, completion: {
            
            self.checkForConnectionError(errorHandler: {
                self.showError()
            })
            
            guard let result =  ConnectionManager.shared.filesSession?.sftp.moveItem(atPath: Pasteboard.local.filePath!, toPath: self.directory.nsString.appendingPathComponent(Pasteboard.local.filePath!.nsString.lastPathComponent)) else { return }
                
            if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
                dirVC.reload()
            }
            
            if !result {
                let errorAlert = UIAlertController(title: "Error moving file!", message: nil, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
            }
                
            Pasteboard.local.filePath = nil
        })
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 87
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let files = files {
            return files.count
        }
        
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "file") as! FileTableViewCell
        
        // Configure the cell...
        
        guard let files = files else { return cell }
        
        cell.filename.text = files[indexPath.row].filename
        
        if files[indexPath.row].isDirectory {
            cell.iconView.image = #imageLiteral(resourceName: "folder")
        } else {
            cell.iconView.image = fileIcon(forExtension: files[indexPath.row].filename.nsString.pathExtension)
        }
        
        if files[indexPath.row].filename.nsString.lastPathComponent.hasPrefix(".") {
            cell.filename.isEnabled = false
            cell.iconView.alpha = 0.5
        } else {
            cell.filename.isEnabled = true
            cell.iconView.alpha = 1
        }
        
        if indexPath.row == files.count-1 && directory.removingUnnecessariesSlashes != "/" {
            cell.filename.text = ".."
        }
        
        cell.permssions.text = files[indexPath.row].permissions
        cell.permssions.isHidden = false
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Remove directory
            if files![indexPath.row].isDirectory {
                
                guard let sftp = ConnectionManager.shared.filesSession?.sftp else { return }
                
                func remove(directoryRecursively directory: String) -> Bool? {
                    while true {
                        guard let files = sftp.contentsOfDirectory(atPath: directory) as? [NMSFTPFile] else { return nil }
                        
                        if files.count > 0 {
                            for file in files {
                                if !file.isDirectory {
                                    sftp.removeFile(atPath: directory.nsString.appendingPathComponent(file.filename))
                                } else if files.count > 0 {
                                    _ = remove(directoryRecursively: directory.nsString.appendingPathComponent(file.filename))
                                } else {
                                    sftp.removeDirectory(atPath: directory.nsString.appendingPathComponent(file.filename))
                                }
                            }
                        } else {
                            return sftp.removeDirectory(atPath: directory)
                        }
                        
                    }
                }
                
                guard let result = remove(directoryRecursively: directory.nsString.appendingPathComponent(files![indexPath.row].filename)) else {
                    self.showError()
                    return
                }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error removing directory!", message: "Check for permissions", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                } else {
                    self.reload()
                }
            } else { // Remove file
                guard let result = ConnectionManager.shared.filesSession?.sftp.removeFile(atPath: directory.nsString.appendingPathComponent(files![indexPath.row].filename)) else {
                    self.showError()
                    return
                }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error removing file!", message: "Check for permissions", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                } else {
                    self.reload()
                }
            }

        }
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if files![indexPath.row].isDirectory {
            return false
        }
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) { // Copy file
            
            Pasteboard.local.filePath = directory.nsString.appendingPathComponent(files![indexPath.row].filename)
            
            let dirVC = DirectoryTableViewController(connection: connection, directory: directory)
            dirVC.navigationItem.prompt = "Select a directory where copy file"
            dirVC.delegate = dirVC
            DirectoryTableViewController.action = .copyFile
            
            
            let navVC = UINavigationController(rootViewController: dirVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: dirVC, action: #selector(dirVC.copyFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let files = files else { return }
        var path = self.directory.nsString.appendingPathComponent(files[indexPath.row].filename)
        
        if let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell {
            if cell.filename.text == ".." {
                path = self.directory.nsString.deletingLastPathComponent
            }
        }
        
        var continueDownload = true
        
        self.checkForConnectionError(errorHandler: { 
            self.showError()
        }) {
            if files[indexPath.row].isDirectory { // Open folder
                
                let activityVC = ActivityViewController(message: "Loading")
                self.present(activityVC, animated: true, completion: {
                    let dirVC = DirectoryTableViewController(connection: self.connection, directory: path)
                    if let delegate = self.delegate {
                        activityVC.dismiss(animated: true, completion: {
                            
                            delegate.directoryTableViewController(dirVC, didOpenDirectory: path)
                            
                            tableView.deselectRow(at: indexPath, animated: true)
                        })
                    } else {
                        activityVC.dismiss(animated: true, completion: {
                            
                            self.navigationController?.pushViewController(dirVC, animated: true)
                            
                            tableView.deselectRow(at: indexPath, animated: true)
                        })
                    }
                })
            } else { // Download file
                
                let activityVC = UIAlertController(title: "Downloading...", message: "", preferredStyle: .alert)
                activityVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    continueDownload = false
                    tableView.deselectRow(at: indexPath, animated: true)
                }))
                
                self.present(activityVC, animated: true, completion: {
                    
                    let newFile = FileManager.default.documents.appendingPathComponent(path.nsString.lastPathComponent)
                    
                    guard let session = ConnectionManager.shared.filesSession else { return }
                    
                    DispatchQueue.global(qos: .background).async {
                        if let data = session.sftp.contents(atPath: path, progress: { (receivedBytes, bytesToBeReceived) -> Bool in
                            
                            let received = ByteCountFormatter().string(fromByteCount: Int64(receivedBytes))
                            let toBeReceived = ByteCountFormatter().string(fromByteCount: Int64(bytesToBeReceived))
                            
                            DispatchQueue.main.async {
                                activityVC.message = "\(received) / \(toBeReceived)"
                            }
                            
                            return continueDownload
                        }) {
                            DispatchQueue.main.async {
                                do {
                                    try data.write(to: newFile)
                                    
                                    activityVC.dismiss(animated: true, completion: {
                                        ConnectionManager.shared.saveFile = SaveFile(localFile: newFile.path, remoteFile: path)
                                        LocalDirectoryTableViewController.openFile(newFile, from: tableView.cellForRow(at: indexPath)!.frame, in: tableView, navigationController: self.navigationController, showActivityViewControllerInside: self)
                                    })
                                } catch let error {
                                    activityVC.dismiss(animated: true, completion: {
                                        let errorAlert = UIAlertController(title: "Error saving file!", message: error.localizedDescription, preferredStyle: .alert)
                                        errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(errorAlert, animated: true, completion: nil)
                                    })
                                }
                                
                                tableView.deselectRow(at: indexPath, animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                activityVC.dismiss(animated: true, completion: {
                                    let alert = UIAlertController(title: "Error downloading file!", message: "Check for permissions.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                                    tableView.deselectRow(at: indexPath, animated: true)
                                })
                            }
                        }
                    }
                })
            }
        }
        
    }

    // MARK: - Local directory table view controller delegate
    
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL) { // Send file
        
        // Upload file
        func sendFile() {
            
            let activityVC = ActivityViewController(message: "Uploading")
            self.present(activityVC, animated: true) {
                do {
                    let dataToSend = try Data(contentsOf: file)
                    
                    ConnectionManager.shared.filesSession?.sftp.writeContents(dataToSend, toFileAtPath: self.directory.nsString.appendingPathComponent(file.lastPathComponent))
                    
                    if self.closeAfterSending {
                        activityVC.dismiss(animated: true, completion: {
                            AppDelegate.shared.close()
                        })
                    } else {
                        activityVC.dismiss(animated: true, completion: {
                            self.reload()
                        })
                    }
                    
                } catch let error {
                    let errorAlert = UIAlertController(title: "Error reading file data!", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }
        }
        
        // Ask user to send file
        let confirmAlert = UIAlertController(title: file.lastPathComponent, message: "Do you want to send \(file.lastPathComponent) to \(directory.nsString.lastPathComponent)?", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            sendFile()
        }))
        
        // Go back here
        navigationController?.popToViewController(self, animated: true, completion: {
            self.present(confirmAlert, animated: true, completion: nil)
        })
    }
    
    // MARK: - Directory table view controller delegate
    
    func directoryTableViewController(_ directoryTableViewController: DirectoryTableViewController, didOpenDirectory directory: String) {
        directoryTableViewController.delegate = directoryTableViewController
        
        if DirectoryTableViewController.action == .copyFile {
            directoryTableViewController.navigationItem.prompt = "Select a directory where copy file"
        }
        
        if DirectoryTableViewController.action == .moveFile {
            directoryTableViewController.navigationItem.prompt = "Select a directory where move file"
        }
        
        navigationController?.pushViewController(directoryTableViewController, animated: true, completion: {
            if DirectoryTableViewController.action == .copyFile {
                directoryTableViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: directoryTableViewController, action: #selector(directoryTableViewController.copyFile))], animated: true)
            }
            
            if DirectoryTableViewController.action == .moveFile {
                directoryTableViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: directoryTableViewController, action: #selector(directoryTableViewController.moveFile))], animated: true)
            }
        })
    }
    
    // MARK: - Banner view delegate
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Show ad only when it received
        tableView.tableHeaderView = bannerView
    }
    
    // MARK: - Static
    
    /// Action to do.
    static var action = RemoteDirectoryAction.none
}

