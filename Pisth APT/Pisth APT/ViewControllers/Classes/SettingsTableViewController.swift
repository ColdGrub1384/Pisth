// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller to change settings.
class SettingsTableViewController: UITableViewController {
    
    /// Calls `dismiss(animated: true, completion: nil)`.
    @objc func closePresented() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view delegate
    
    /// Show licenses.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            
            // Open licenses
            if let webVC = Bundle.main.loadNibNamed("Web", owner: nil, options: nil)?[0] as? WebViewController {
                
                let navVC = UINavigationController(rootViewController: webVC)
                
                webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
                webVC.navigationItem.leftBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(closePresented))]
                
                present(navVC, animated: true, completion: nil)
            }
        }
    }
    
}
