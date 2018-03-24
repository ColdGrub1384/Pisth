//
//  ConnectionsTableViewController.swift
//  Pisth APT
//
//  Created by Adrian on 24.03.18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import UIKit

/// View controller used to manage connections.
class ConnectionsTableViewController: UITableViewController {

    /// Add new connection
    @IBAction func add(_ sender: Any) {
        if let vc = UIStoryboard(name: "Connection Info", bundle: Bundle.main).instantiateInitialViewController() {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
