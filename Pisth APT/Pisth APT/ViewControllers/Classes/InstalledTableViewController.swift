// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared
import Pisth_API
import StoreKit
import GoogleMobileAds

/// Table view controller for listing installed packages.
class InstalledTableViewController: UITableViewController, UISearchBarDelegate, UIDocumentPickerDelegate, SKStoreProductViewControllerDelegate, GADBannerViewDelegate {
    
    /// Header view containg `adBanner`.
    @IBOutlet weak var header: UIView!
    
    /// Admob banner.
    @IBOutlet weak var adBanner: GADBannerView!
    
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
    
    /// Install DEB package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func install(_ sender: Any) {
        let alert = UIAlertController(title: "Install DEB package", message: "Select where import a DEB package", preferredStyle: .actionSheet)
        
        // Import from Pisth
        alert.addAction(UIAlertAction(title: "Import from Pisth", style: .default, handler: { (_) in
            if pisth.canOpen {
                pisth.importFile()
            } else {
                let appStore = SKStoreProductViewController()
                appStore.delegate = self
                appStore.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: "1331070425"], completionBlock: nil)
                self.present(appStore, animated: true, completion: nil)
            }
        }))
        
        // Import from Files
        alert.addAction(UIAlertAction(title: "Import from Files", style: .default, handler: { (_) in
            let browser = UIDocumentPickerViewController(documentTypes: ["ch.marcela.ada.Pisth.APT.deb"], in: .import)
            browser.delegate = self
            self.present(browser, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let button = sender as? UIBarButtonItem {
            alert.popoverPresentationController?.barButtonItem = button
        }
        
        present(alert, animated: true, completion: nil)
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
        
        adBanner.adSize = kGADAdSizeBanner
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
    
    // MARK: - Document picker delegate
    
    /// Upload and install Debian package.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let activityVC = ActivityViewController(message: "Uploading...")
        
        var success = false
        
        present(activityVC, animated: true, completion: {
            success = AppDelegate.shared.session?.channel.uploadFile(url.path, to: "\(AppDelegate.shared.homeDirectory ?? "")/PisthDEBInstall.deb") ?? false
            
            activityVC.dismiss(animated: true, completion: {
                
                if success {
                    guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
                        return
                    }
                    
                    termVC.command = "clear; dpkg -i ~/PisthDEBInstall.deb; rm ~/PisthDEBInstall.deb; echo -e \"\\033[CLOSE\""
                    termVC.title = "Installing packages..."
                    
                    let navVC = UINavigationController(rootViewController: termVC)
                    navVC.modalPresentationStyle = .formSheet
                    
                    self.present(navVC, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Error uploading file!", message: "Make sure the file is not empty.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            })
        })
    }
    
    /// Dismiss.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Store product view controller delegate
    
    /// Dismiss.
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Banner view delegate
    
    /// Hide ad.
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        tableView.tableHeaderView = nil
    }
}
