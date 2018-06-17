// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import Pisth_Shared

/// A View controller showing information about a connection.
class ConnectionInfoViewController: NSViewController {
    
    /// Index of existing connection in `RemoteConnection.shared.connections`.
    var index: Int?
    
    /// Create or modify connection.
    @IBAction func saveConnection(_ sender: Any) {
        let name = nameTextField.stringValue
        let host = hostTextField.stringValue
        var port = portTextField.stringValue
        let username = usernameTextField.stringValue
        let password = passwordTextField.stringValue
        var path = pathTextField.stringValue
        let useSFTP = (useSFTPCheck.state == .on)
        
        // Check for requierd fields
        if host == "" || username == "" {
            if host == "" {
                hostTextField.backgroundColor = .red
            } else {
                hostTextField.backgroundColor = .clear
            }
            
            if username == "" {
                usernameTextField.backgroundColor = .red
            } else {
                usernameTextField.backgroundColor = .clear
            }
        } else {
            if port == "" { // Port is 22 by default
                port = "22"
            }
            
            if path == "" { // Path is ~ by default
                path = "~"
            }
            
            if let port = UInt64(port) {
                
                if let index = index {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
                    request.returnsObjectsAsFaults = false
                    
                    do {
                        let result = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])[index]
                        let passKey = String.random(length: 100)
                        result.setValue(name, forKey: "name")
                        result.setValue(host, forKey: "host")
                        result.setValue(port, forKey: "port")
                        result.setValue(username, forKey: "username")
                        result.setValue(passKey, forKey: "password")
                        result.setValue(path, forKey: "path")
                        result.setValue(useSFTP, forKey: "sftp")
                        KeychainSwift().set(password, forKey: passKey)
                        
                        DataManager.shared.saveContext()
                    } catch let error {
                        print("Error retrieving connections: \(error.localizedDescription)")
                    }
                    
                    dismiss(self)
                } else {
                    DataManager.shared.addNew(connection: RemoteConnection(host: host, username: username, password: password, name: name, path: path, port: port, useSFTP: useSFTP, os: nil))
                    
                    dismiss(self)
                }
                
            } else {
                portTextField.backgroundColor = .red
            }
        }
    }
    
    // MARK: - Values
    
    /// The Text field containing the connection's name.
    @IBOutlet weak var nameTextField: NSTextField!
    
    /// The Text field containing the username.
    @IBOutlet weak var usernameTextField: NSTextField!
    
    /// The Text field containing the host.
    @IBOutlet weak var hostTextField: NSTextField!
    
    /// The Text field containing the port.
    @IBOutlet weak var portTextField: NSTextField!
    
    /// The Text field containing the password.
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    
    /// The Text field containing the path.
    @IBOutlet weak var pathTextField: NSTextField!
    
    /// The button for toggling SFTP.
    @IBOutlet weak var useSFTPCheck: NSButton!
    
    // MARK: - View controller
    
    /// Fill info.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let i = index, DataManager.shared.connections.indices.contains(i) {
            let connection = DataManager.shared.connections[i]
            
            nameTextField.stringValue = connection.name
            usernameTextField.stringValue = connection.username
            hostTextField.stringValue = connection.host
            portTextField.stringValue = "\(connection.port)"
            passwordTextField.stringValue = connection.password
            pathTextField.stringValue = connection.path
            if !connection.useSFTP {
                useSFTPCheck.state = .off
            }
        }
    }
}
