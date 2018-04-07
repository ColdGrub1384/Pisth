// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared
import GoogleMobileAds

/// View controller for updating packages.
class UpdatesTableViewController: UITableViewController, UISearchBarDelegate, GADBannerViewDelegate {
    
    /// Search for updates.
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
    
    /// Run `apt-get upgrade`.
    @IBAction func upgrade(_ sender: Any) {
        guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
            return
        }
        
        termVC.command = "clear; sudo apt-get upgrade; echo -e \"\\033[CLOSE\""
        termVC.title = title
        
        let navVC = UINavigationController(rootViewController: termVC)
        navVC.modalPresentationStyle = .formSheet
        
        UIApplication.shared.keyWindow?.rootViewController?.present(navVC, animated: true, completion: nil)
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
        
        // Ads
        let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-9214899206650515/5188157128"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    // MARK: - Table view data source
    
    /// - Returns: Count of available updates or fetched updates.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            return fetchedPackages.count
        }
        
        return AppDelegate.shared.updates.count
    }
    
    /// - Returns: A cell with the title as the package for current index.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "package") else {
            return UITableViewCell()
        }
        
        var updates: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            updates = fetchedPackages
        } else {
            updates = AppDelegate.shared.updates
        }
        
        cell.textLabel?.text = updates[indexPath.row]
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Show package.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var updates: [String]
        if searchController != nil && searchController.isActive && searchController.searchBar.text != "" {
            updates = fetchedPackages
        } else {
            updates = AppDelegate.shared.updates
        }
        
        let vc = InstallerViewController.forPackage(updates[indexPath.row])
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Search bar delegate
    
    /// Search for package.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        fetchedPackages = []
        
        if !searchText.isEmpty {
            
            for package in AppDelegate.shared.updates {
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
    
    // MARK: - Banner view delegate
    
    /// Show ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        tableView.tableHeaderView = bannerView
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error)
    }
}
