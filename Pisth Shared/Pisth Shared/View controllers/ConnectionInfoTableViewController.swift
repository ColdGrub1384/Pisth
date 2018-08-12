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
open class ConnectionInformationTableViewController: UITableViewController, NetServiceDelegate {
    
    /// Table view to reload after making changes.
    open var rootTableView: UITableView?
    
    /// Root view controller.
    open var rootViewController: UIViewController?
        
    var bonjourDomainsTableView: UITableView!
    
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
    
    /// Content of the public key.
    public var publicKey: String?
    
    /// Content of the private key.
    public var privateKey: String?
    
    // MARK: - View controller
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        bonjourDomainsTableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        
        bonjourDomainsTableView.delegate = self
        bonjourDomainsTableView.dataSource = self
        
        _ = Bonjour().findDomains({ (domains) in
            for domain in domains {
                _ = Bonjour().findService(Bonjour.Services.Secure_Shell, domain: domain, found: { (services) in
                    for service in services {
                        self.services.append(service)
                    }
                    
                    if self.services.count > 0 {
                        self.tableView.tableHeaderView = self.bonjourDomainsTableView
                    } else {
                        self.tableView.tableHeaderView = nil
                    }
                    self.bonjourDomainsTableView.reloadData()
                })
            }
        })
        
        textFields = [name, host, port, username, password, path]
        
        for field in textFields {
            field?.autocorrectionType = .no
            
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
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
            publicKey = connection.publicKey
            privateKey = connection.privateKey
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    /// Save connection.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction open func save(_ sender: Any) {
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
                        result.setValue(publicKey, forKey: "publicKey")
                        result.setValue(privateKey, forKey: "privateKey")
                        KeychainWrapper.standard.set(password, forKey: passKey)
                        
                        DataManager.shared.saveContext()
                    } catch let error {
                        print("Error retrieving connections: \(error.localizedDescription)")
                    }
                    
                    cancel(self)
                } else {
                    DataManager.shared.addNew(connection: RemoteConnection(host: host, username: username, password: password, publicKey: publicKey, privateKey: privateKey, name: name, path: path, port: port, useSFTP: useSFTP, os: nil))
                    
                    cancel(self)
                }
                
            } else {
                self.port?.backgroundColor = .red
            }
        }
    }
    
    /// Dismiss without saving changes.
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: {
            self.rootViewController?.viewDidAppear(true)
            self.rootTableView?.reloadData()
        })
    }
    
    // MARK: - Bonjour
    
    var services = [NetService]()
    
    // MARK: - Table view data source
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard tableView == bonjourDomainsTableView else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        
        return services.count
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard tableView == bonjourDomainsTableView else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = services[indexPath.row].name
        
        return cell
    }
    
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard tableView == bonjourDomainsTableView else {
            return super.tableView(tableView, titleForHeaderInSection: section)
        }
        
        if services.count > 0 {
            return Bundle(for: ConnectionInformationTableViewController.self).localizedString(forKey: "nearby", value: nil, table: nil)
        } else {
            return nil
        }
    }
    
    // MARK: - Table view delegate
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard tableView == bonjourDomainsTableView else {
            return
        }
        
        let service = services[indexPath.row]
        service.delegate = self
        service.resolve(withTimeout: 0)
    }
    
    // MARK: Net service delegate
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        host?.text = sender.hostName
        port?.text = "\(sender.port)"
    }
    
    // MARK: - Fields
    
    /// Name field.
    @IBOutlet weak public var name: UITextField?
    
    /// Host field.
    @IBOutlet weak public var host: UITextField?
    
    /// Port field.
    @IBOutlet weak public var port: UITextField?
    
    /// Username field.
    @IBOutlet weak public var username: UITextField?
    
    /// Password field.
    @IBOutlet weak public var password: UITextField?
    
    /// Use SFTP field.
    @IBOutlet weak public var useSFTP: UISwitch?
    
    /// Path field.
    @IBOutlet weak public var path: UITextField?
    
    /// All text fields
    var textFields: [UITextField?]!
    
}
#endif
