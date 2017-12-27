//
//  DirectoryTableViewController.swift
//  
//
//  Created by Adrian on 25.12.17.
//

import UIKit

class DirectoryTableViewController: UITableViewController, LocalDirectoryTableViewControllerDelegate {
    
    // MARK: - DirectoryTableViewController
    
    var directory: String
    var connection: RemoteConnection
    var files: [String]?
    var isDir = [Bool]()
    
    init(connection: RemoteConnection, directory: String? = nil) {
        self.connection = connection
        if directory == nil {
            self.directory = connection.path
        } else {
            self.directory = directory!
        }
        
        var continue_ = false
        
        if ConnectionManager.shared.session == nil {
            continue_ = ConnectionManager.shared.connect(to: connection)
        } else if !ConnectionManager.shared.session!.isConnected || !ConnectionManager.shared.session!.isAuthorized {
            continue_ = ConnectionManager.shared.connect(to: connection)
        } else {
            continue_ = ConnectionManager.shared.session!.isConnected && ConnectionManager.shared.session!.isAuthorized
        }
        
        if continue_ {
            if self.directory == "~" { // Get absolute path from ~
                if let path = try? ConnectionManager.shared.session?.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "") {
                    self.directory = path!
                }
            }
            
            if let files = ConnectionManager.shared.files(inDirectory: self.directory) {
                self.files = files
                
                if files == [self.directory+"/*"] { // The content of files is ["*"] when there is no file
                    self.files = []
                }
                
                // Check if path is directory or not
                for file in files {
                    isDir.append(file.hasSuffix("/"))
                }
                
                self.files!.append((self.directory as NSString).deletingLastPathComponent) // Append parent directory
                isDir.append(true)
            }
        }
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func reload() {
        files = nil
        isDir = []
        
        if let files = ConnectionManager.shared.files(inDirectory: self.directory) {
            self.files = files
            
            if files == [self.directory+"/*"] { // The content of files is ["*"] when there is no file
                self.files = []
            }
            
            // Check if path is directory or not
            for file in files {
                isDir.append(file.hasSuffix("/"))
            }
            
            self.files!.append((self.directory as NSString).deletingLastPathComponent) // Append parent directory
            isDir.append(true)
        } else {
            self.files = nil
        }
        
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    
    @objc func uploadFile(_ sender: UIBarButtonItem) { // Upload file
        let localDirVC = LocalDirectoryTableViewController(directory: FileManager.default.documents)
        localDirVC.delegate = self
        
        navigationController?.pushViewController(localDirVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = directory.components(separatedBy: "/").last
        
        navigationItem.largeTitleDisplayMode = .never
        
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
        navigationItem.setRightBarButtonItems([uploadFile], animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Go back if there is an error connecting to session
        if let session = ConnectionManager.shared.session{
            if !session.isConnected || !session.isAuthorized {
                navigationController?.popToRootViewController(animated: true)
            }
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
        if files == nil {
            navigationController?.popToRootViewController(animated: true)
        }
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
        
        if let files = files {
            if files[indexPath.row] != (directory as NSString).deletingLastPathComponent {
                if isDir[indexPath.row] {
                    let components = files[indexPath.row].components(separatedBy: "/")
                    cell.filename.text = components[components.count-2]
                } else {
                    cell.filename.text = files[indexPath.row].components(separatedBy: "/").last
                }
            } else {
                cell.filename.text = ".."
            }
        }
        
        if isDir.indices.contains(indexPath.row) {
            if isDir[indexPath.row] {
                cell.iconView.image = #imageLiteral(resourceName: "folder")
            } else {
                cell.iconView.image = #imageLiteral(resourceName: "file")
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove file
            do {
                let result = try ConnectionManager.shared.session?.channel.execute("rm -rf '\(files![indexPath.row])' 2>&1")
                
                if result?.replacingOccurrences(of: "\n", with: "") != "" { // Error
                    let errorAlert = UIAlertController(title: nil, message: result, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                } else {
                    files!.remove(at: indexPath.row)
                    isDir.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } catch let error {
                let errorAlert = UIAlertController(title: "Error removing file!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell else { return }
        
        // Don't continue if session is innactive
        guard let session = ConnectionManager.shared.session else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        if !session.isConnected || !session.isAuthorized {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        
        let activityVC = ActivityViewController(message: "Loading")
        
        self.present(activityVC, animated: true) {
            if cell.iconView.image == #imageLiteral(resourceName: "folder") { // Open folder
                let dirVC = DirectoryTableViewController(connection: self.connection, directory: self.files?[indexPath.row])
                activityVC.dismiss(animated: true, completion: {
                    
                    if dirVC.files != nil {
                        self.navigationController?.pushViewController(dirVC, animated: true)
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                })
            } else { // Download file
                guard let session = ConnectionManager.shared.session else {
                    tableView.deselectRow(at: indexPath, animated: true)
                    activityVC.dismiss(animated: true, completion: nil)
                    return
                }
                
                let newFile = FileManager.default.documents.appendingPathComponent(cell.filename.text!)
                
                if let data = session.sftp.contents(atPath: self.files![indexPath.row]) {
                    do {
                        try data.write(to: newFile)
                        
                        activityVC.dismiss(animated: true, completion: {
                            ConnectionManager.shared.saveFile = SaveFile(localFile: newFile.path, remoteFile: self.files![indexPath.row])
                            LocalDirectoryTableViewController.openFile(newFile, from: tableView.cellForRow(at: indexPath)!.frame, in: tableView, navigationController: self.navigationController, showActivityViewControllerInside: self)
                        })
                    } catch let error {
                        activityVC.dismiss(animated: true, completion: {
                            let errorAlert = UIAlertController(title: "Error downloading file!", message: error.localizedDescription, preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(errorAlert, animated: true, completion: nil)
                        })
                    }
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                } else {
                    activityVC.dismiss(animated: true, completion: {
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        }
                
    }
    
    // MARK: - LocalDirectoryTableViewControllerDelegate
    
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL) { // Send file
        
        // Upload file
        func sendFile() {
            
            let activityVC = ActivityViewController(message: "Uploading")
            self.present(activityVC, animated: true) {
                do {
                    let dataToSend = try Data(contentsOf: file)
                    
                    ConnectionManager.shared.session?.sftp.writeContents(dataToSend, toFileAtPath: (self.directory as NSString).appendingPathComponent(file.lastPathComponent))
                    
                    activityVC.dismiss(animated: true, completion: {
                        self.reload()
                    })
                    
                } catch let error {
                    let errorAlert = UIAlertController(title: "Error reading file data!", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }
        }
        
        // Ask user to send file
        let confirmAlert = UIAlertController(title: file.lastPathComponent, message: "Do you want to send \(file.lastPathComponent) to \((directory as NSString).lastPathComponent)?", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            sendFile()
        }))
        
        // Go back here
        navigationController?.popToViewController(self, animated: true, completion: {
            self.present(confirmAlert, animated: true, completion: nil)
        })
    }
}

