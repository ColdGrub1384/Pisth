// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// View controller for displaying a package.
class InstallerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// The package to show.
    var package: String?
    
    /// Package description to parse and show.
    private var packageProperties: [String]?
    
    /// Table view containing properties.
    @IBOutlet weak var propertiesTableView: UITableView!
    
    /// Activity view.
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    /// Label containing package name.
    @IBOutlet weak var packageNameLabel: UILabel!
    
    /// Button for removing the package.
    @IBOutlet weak var removeButton: UIBarButtonItem!
    
    /// Button for updating the package.
    @IBOutlet weak var updateButton: UIBarButtonItem!
    
    /// Button for installing the package.
    @IBOutlet weak var installButton: UIBarButtonItem!
    
    /// Close this view controller.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /// Launch command in a terminal with given title.
    ///
    /// - Parameters:
    ///     - command: Command to launch.
    ///     - title: Title of the view controller.
    func launch(command: String, withTitle title: String) {
        guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
            return
        }
        
        termVC.command = "clear; \(command); echo -e \"\\033[CLOSE\""
        termVC.title = title
        
        let navVC = UINavigationController(rootViewController: termVC)
        navVC.modalPresentationStyle = .formSheet
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Install package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func install(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes install '\(package ?? "")'", withTitle: "Installing \(package ?? "")...")
    }
    
    /// Update package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func update(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes install --only-upgrade '\(package ?? "")'", withTitle: "Upgrading \(package ?? "")...")
    }
    
    /// Remove package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func remove(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes purge --auto-remove '\(package ?? "")'", withTitle: "Removing \(package ?? "")...")
    }
    
    
    // MARK: - View controller
    
    /// Setup views
    override func viewDidLoad() {
        super.viewDidLoad()
        
        propertiesTableView.dataSource = self
        propertiesTableView.delegate = self
        propertiesTableView.rowHeight = UITableViewAutomaticDimension
        propertiesTableView.estimatedRowHeight = 200
        packageNameLabel.text = ""
    }
    
    /// Fetch info.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        packageNameLabel.text = package
        
        activityView.isHidden = false
        
        if let package = package {
            if let session = AppDelegate.shared.session {
                if session.isConnected && session.isAuthorized {
                    if let description = try? session.channel.execute("aptitude show '\(package)'") {
                        
                        var properties = [String]()
                        for property in description.components(separatedBy: "\n") {
                            if property.contains(": ") {
                                properties.append(property)
                            } else {
                                if let last = properties.last {
                                    properties.remove(at: properties.count-1)
                                    properties.append(last+"\n"+property)
                                }
                            }
                        }
                        
                        self.packageProperties = properties
                        self.propertiesTableView.reloadData()
                    }
                }
            }
            
            
            updateButton.isEnabled = AppDelegate.shared.updates.contains(package)
            installButton.isEnabled = !AppDelegate.shared.installed.contains(package)
            removeButton.isEnabled = AppDelegate.shared.installed.contains(package)
            
            activityView.isHidden = true
        }
    }
    
    // MARK: - Table view data source
    
    /// - Returns: The number of properties.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packageProperties?.count ?? 0
    }
    
    /// - Returns: A cell with the name and the value of the property.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "property") as? PackagePropertyTableViewCell else {
            return UITableViewCell()
        }
        
        guard let properties = packageProperties else {
            return cell
        }
        
        cell.nameLabel.text = properties[indexPath.row].components(separatedBy: ": ")[0]
        
        if properties[indexPath.row].components(separatedBy: ": ").count >= 2 {
            cell.contentTextView.text = properties[indexPath.row].components(separatedBy: ": ")[1]
        }
        
        return cell
    }
    
    /// - Returns: `200`.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Static
    
    /// Get a Navigation controller containing an `InstallerViewController` from given package.
    ///
    /// - Parameters:
    ///     - package: Package to show.
    ///
    /// - Returns: A Navigation controller containing an `InstallerViewController`.
    static func forPackage(_ package: String) -> UINavigationController {
        let vc = (UIStoryboard(name: "Installer", bundle: Bundle.main).instantiateInitialViewController() as? InstallerViewController) ?? InstallerViewController()
        vc.package = package
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        
        return navVC
    }
}
