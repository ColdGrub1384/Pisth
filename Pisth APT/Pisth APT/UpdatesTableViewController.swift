// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller for updating packages.
class UpdatesTableViewController: UITableViewController {
    
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
        navVC.view.backgroundColor = .clear
        navVC.modalPresentationStyle = .overCurrentContext
        
        UIApplication.shared.keyWindow?.rootViewController?.present(navVC, animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = .clear
        refreshControl?.tintColor = .gray
        refreshControl?.addTarget(self, action: #selector(update(_:)), for: .valueChanged)
    }
    
    // MARK: - Table view data source
    
    /// - Returns: Count of available updates.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppDelegate.shared.updates.count
    }
    
    /// - Returns: A cell with the title as the package for current index.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "package") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = AppDelegate.shared.updates[indexPath.row]
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Show package.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let installer = UIStoryboard(name: "Installer", bundle: Bundle.main).instantiateInitialViewController() as? InstallerViewController {
            installer.package = AppDelegate.shared.updates[indexPath.row]
            present(UINavigationController(rootViewController: installer), animated: true, completion: nil)
        }
    }
}
