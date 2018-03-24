// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
import UIKit
import CoreData

/// Table view controller containing information about a connection.
public class ConnectionInformationTableViewController: UITableViewController {
    
    /// Init with given style.
    ///
    /// - Parameters:
    ///     - style: Style to use.
    public override init(style: UITableViewStyle) {
        super.init(style: style)
    }
    
    /// Init.
    public init() {
        super.init(style: .plain)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Existing connection to edit.
    public var connection: RemoteConnection?
    
    /// Index of connection to edit.
    public var index: Int?
    
    // MARK: - View controller
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        textFields = [name, host, port, username, password, path]
        
        for field in textFields {
            field?.autocorrectionType = .no
            
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            toolbar.barStyle = .black
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Done", style: .done, target: field, action: #selector(field?.resignFirstResponder))]
            field?.inputAccessoryView = toolbar
        }
        
        if let connection = connection {
            name?.text = connection.name
            host?.text = connection.host
            port?.text = "\(connection.port)"
            username?.text = connection.username
            password?.text = connection.password
            useSFTP?.isOn = connection.useSFTP
            path?.text = connection.path
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    /// Save connection.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func save(_ sender: Any) {
        let name = self.name?.text ?? ""
        let host = self.host?.text ?? ""
        var port = self.port?.text ?? ""
        let username = self.username?.text ?? ""
        let password = self.password?.text ?? ""
        var path = self.path?.text ?? ""
        let useSFTP = self.useSFTP?.isOn ?? false
        
        // Check for requierd fields
        if host == "" || username == "" {
            if host == "" {
                self.host?.backgroundColor = .red
            } else {
                self.host?.backgroundColor = .clear
            }
            
            if username == "" {
                self.username?.backgroundColor = .red
            } else {
                self.username?.backgroundColor = .clear
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
                        KeychainWrapper.standard.set(password, forKey: passKey)
                        
                        DataManager.shared.saveContext()
                    } catch let error {
                        print("Error retrieving connections: \(error.localizedDescription)")
                    }
                    
                    navigationController?.popViewController(animated: true)
                } else {
                    DataManager.shared.addNew(connection: RemoteConnection(host: host, username: username, password: password, name: name, path: path, port: port, useSFTP: useSFTP, os: nil))
                    
                    navigationController?.popViewController(animated: true)
                }
                
            } else {
                self.port?.backgroundColor = .red
            }
        }
    }
    
    // MARK: - Fields
    
    /// Name field.
    @IBOutlet weak var name: UITextField?
    
    /// Host field.
    @IBOutlet weak var host: UITextField?
    
    /// Port field.
    @IBOutlet weak var port: UITextField?
    
    /// Username field.
    @IBOutlet weak var username: UITextField?
    
    /// Password field.
    @IBOutlet weak var password: UITextField?
    
    /// Use SFTP field.
    @IBOutlet weak var useSFTP: UISwitch?
    
    /// Path field.
    @IBOutlet weak var path: UITextField?
    
    /// All text fields
    var textFields: [UITextField?]!
    
}
#endif
