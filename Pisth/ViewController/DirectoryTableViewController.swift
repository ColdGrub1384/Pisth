//
//  DirectoryTableViewController.swift
//  
//
//  Created by Adrian on 25.12.17.
//

import UIKit

class DirectoryTableViewController: UITableViewController {
    
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
        } else {
            continue_ = ConnectionManager.shared.session!.isConnected && ConnectionManager.shared.session!.isAuthorized
        }
        
        if continue_ {
            if self.directory == "~" { // Get absolute path from ~
                if let path = try? ConnectionManager.shared.session?.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "") {
                    self.directory = path!
                }
            }
            
            files = ConnectionManager.shared.files(inDirectory: self.directory)
            
            if files! == [self.directory+"/*"] { // The content of files is ["*"] when there is no file
                files = []
            }
            
            // Check if path is directory or not
            for file in files! {
                isDir.append(file.hasSuffix("/"))
            }
            
            files?.append((self.directory as NSString).deletingLastPathComponent) // Append parent directory
            isDir.append(true)
        }
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let session = ConnectionManager.shared.session {
            if !session.isConnected || !session.isAuthorized {
                navigationController?.popToRootViewController(animated: true)
            }
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
        
        title = directory.components(separatedBy: "/").last
        
        navigationItem.largeTitleDisplayMode = .never
        
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "file")
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
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
        
        let activityVC = ActivityViewController(message: "Loading")
        
        self.present(activityVC, animated: true) {
            if cell.iconView.image == #imageLiteral(resourceName: "folder") { // Open folder
                let dirVC = DirectoryTableViewController(connection: self.connection, directory: self.files?[indexPath.row])
                activityVC.dismiss(animated: true, completion: {
                    self.navigationController?.pushViewController(dirVC, animated: true)
                    tableView.deselectRow(at: indexPath, animated: true)
                })
            } else { // Download file
                let directory = FileManager.default.documents.appendingPathComponent("\(self.connection.username)@\(self.connection.host):\(self.connection.port)").appendingPathComponent(self.directory)
                
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    
                    guard let session = ConnectionManager.shared.session else {
                        tableView.deselectRow(at: indexPath, animated: true)
                        activityVC.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    let newFile = directory.appendingPathComponent(cell.filename.text!)
                    
                    if session.channel.downloadFile(self.files![indexPath.row], to: newFile.path) {
                        tableView.deselectRow(at: indexPath, animated: true)
                        activityVC.dismiss(animated: true, completion: {
                            let dirVC = LocalDirectoryTableViewController(directory: directory)
                            dirVC.openFile = newFile
                            self.navigationController?.pushViewController(dirVC, animated: true)
                        })
                        
                    }
                } catch _ {}
            }
        }
                
    }
    
}

