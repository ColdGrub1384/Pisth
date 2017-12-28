//
//  SettingsTableViewController.swift
//  Pisth
//
//  Created by Adrian on 28.12.17.
//  Copyright © 2017 ADA. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    enum Index: Int {
        case acknowledgements = 0
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case Index.acknowledgements.rawValue:
            // Open acknowledgements
            let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            navigationController?.pushViewController(webVC, animated: true)
        default:
            break
        }
    }
}
