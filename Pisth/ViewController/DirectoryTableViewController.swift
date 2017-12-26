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
            
            // Check if path is directory for each file
            if let files = files {
                for file in files {
                    if let isDir = ConnectionManager.shared.isDirectory(path: file) {
                        self.isDir.append(isDir)
                    }
                }
                
                if self.directory != "/" { // Add '..' if dir is not '/'
                    self.files?.append((self.directory as NSString).deletingLastPathComponent)
                    self.isDir.append(true)
                }
            }
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
                cell.filename.text = files[indexPath.row].components(separatedBy: "/").last
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
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell else { return }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                
            if cell.iconView.image == #imageLiteral(resourceName: "folder") { // Open folder
                self.navigationController?.pushViewController(DirectoryTableViewController(connection: self.connection, directory: self.files?[indexPath.row]), animated: true)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                tableView.deselectRow(at: indexPath, animated: true)
            } else { // Download file
                let directory = FileManager.default.documents.appendingPathComponent("\(self.connection.username)@\(self.connection.host):\(self.connection.port)").appendingPathComponent(self.directory)
                
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    
                    guard let session = ConnectionManager.shared.session else {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        tableView.deselectRow(at: indexPath, animated: true)
                        return
                    }
                    
                    if session.channel.downloadFile(self.files![indexPath.row], to: directory.appendingPathComponent(cell.filename.text!).path) {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.navigationController?.pushViewController(LocalDirectoryTableViewController(directory: directory), animated: true)
                    }
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                } catch _ {}
            }
                
        })
    }
    
}

