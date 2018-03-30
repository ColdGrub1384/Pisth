// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// Table view controller for listing installed packages.
class InstalledTableViewController: UITableViewController, UISearchBarDelegate {
    
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
            })
        }
        
    }
    
    /// Search controller used to search.
    var searchController: UISearchController!
    
    /// Fetched packages with `searchController`.
    var fetchedPackages = [String]()
    
    // MARK: - View controller
    
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = .clear
        refreshControl?.tintColor = .gray
        refreshControl?.addTarget(self, action: #selector(update(_:)), for: .valueChanged)
        
        // Search
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        }
    }
    
    // MARK: - Table view data source
    
    /// - Returns: Count of installed packages.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            return fetchedPackages.count
        }
        
        return AppDelegate.shared.installed.count
    }
    
    /// - Returns: A cell with the title as the package for current index.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "package") else {
            return UITableViewCell()
        }
        
        var installed: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            installed = fetchedPackages
        } else {
            installed = AppDelegate.shared.installed
        }
        
        cell.textLabel?.text = installed[indexPath.row]
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Show package.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var installed: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            installed = fetchedPackages
        } else {
            installed = AppDelegate.shared.installed
        }
        
        let vc = InstallerViewController.forPackage(installed[indexPath.row])
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Search bar delegate
    
    /// Search for package.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        fetchedPackages = []
        
        if !searchText.isEmpty {
            
            for package in AppDelegate.shared.installed {
                if package.lowercased().contains(searchText.lowercased()) {
                    fetchedPackages.append(package)
                }
                
            }
        }
        
        tableView.reloadData()
    }
    
    /// Reset packages.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            self.tableView.reloadData()
        })
    }
    
}
