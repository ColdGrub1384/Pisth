// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// A `BookmarksTableViewController` for being presented on compact windows on the top of a connection.
class CompactBookmarksTableViewController: BookmarksTableViewController {
    
    // MARK: - Bookmarks table view controller
    
    override func openShell() {
        dismiss(animated: true) {
            super.openShell()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.backgroundColor = .clear
        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) { }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ContentViewController.shared.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        
        return cell
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Ask to the user for restarting the current session.
        
        if indexPath.section == 1, let connection = ConnectionManager.shared.connection, DataManager.shared.connections[indexPath.row] == connection {
            let alert = UIAlertController(title: Localizable.BookmarksTableViewController.sessionAlreadyActiveTitle, message: Localizable.BookmarksTableViewController.sessionAlreadyActiveMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localizable.BookmarksTableViewController.resume, style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: Localizable.BookmarksTableViewController.restart, style: .destructive, handler: { (_) in
                self.dismiss(animated: true, completion: {
                    super.tableView(tableView, didSelectRowAt: indexPath)
                })
            }))
            alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        } else if indexPath.section == 1 {
            dismiss(animated: true) {
                super.tableView(tableView, didSelectRowAt: indexPath)
            }
        } else if indexPath.section == 0 {
            openShell()
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
