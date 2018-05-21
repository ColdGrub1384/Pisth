// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller containing packages.
class PackagesTableViewController: UITableViewController, UISearchBarDelegate {
    
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
    
    /// Launch `apt-get update`
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func aptUpdate(_ sender: Any) {
        guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
            return
        }
        
        termVC.command = "clear; sudo apt-get -y update; echo -e \"\\033[CLOSE\""
        termVC.title = title
        
        let navVC = UINavigationController(rootViewController: termVC)
        navVC.modalPresentationStyle = .formSheet
        
        present(navVC, animated: true, completion: nil)
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
    
    /// - Returns: Count of available packages.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            return fetchedPackages.count
        }
        
        return AppDelegate.shared.allPackages.count
    }
    
    /// - Returns: A cell with the title as the package for current index.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "package") else {
            return UITableViewCell()
        }
        
        var packages: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            packages = fetchedPackages
        } else {
            packages = AppDelegate.shared.allPackages
        }
        
        let components = packages[indexPath.row].components(separatedBy: " - ")
        if components.count >= 2 {
            cell.textLabel?.text = components[0]
            cell.detailTextLabel?.text = components[1]
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Show package.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var packages: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            packages = fetchedPackages
        } else {
            packages = AppDelegate.shared.allPackages
        }
        
        let vc = InstallerViewController.forPackage(packages[indexPath.row].components(separatedBy: " - ")[0])
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Search bar delegate
    
    /// Search for package.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        fetchedPackages = []
        
        if !searchText.isEmpty {
            
            for package in AppDelegate.shared.allPackages {
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
