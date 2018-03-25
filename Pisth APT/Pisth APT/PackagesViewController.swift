// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller containing packages.
class PackagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// Table view containing available packages.
    @IBOutlet weak var tableView: UITableView!
    
    /// Refresh.
    ///
    /// - Parameters:
    ///     - sender: Sender refresh control.
    @objc func update(_ sender: UIRefreshControl) {
        
        let activityVC = ActivityViewController(message: "Loading...")
        present(activityVC, animated: true) {
            AppDelegate.shared.searchForUpdates()
            activityVC.dismiss(animated: true, completion: {
                sender.endRefreshing()
                self.tableView.reloadData()
            })
        }
        
    }
    
    // MARK: - View controller
    
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.backgroundColor = .clear
        tableView.refreshControl?.tintColor = .gray
        tableView.refreshControl?.addTarget(self, action: #selector(update(_:)), for: .valueChanged)
    }
    
    // MARK: - Table view data source
    
    /// - Returns: Count of available packages.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppDelegate.shared.allPackages.count
    }
    
    /// - Returns: A cell with the title as the package for current index.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "package") else {
            return UITableViewCell()
        }
        
        let components = AppDelegate.shared.allPackages[indexPath.row].components(separatedBy: " - ")
        if components.count >= 2 {
            cell.textLabel?.text = components[0]
            cell.detailTextLabel?.text = components[1]
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Show package.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let installer = Bundle.main.loadNibNamed("Installer", owner: nil, options: nil)?[0] as? InstallerViewController {
            installer.package = AppDelegate.shared.allPackages[indexPath.row].components(separatedBy: " - ")[0]
            present(UINavigationController(rootViewController: installer), animated: true, completion: nil)
        }
    }
}
