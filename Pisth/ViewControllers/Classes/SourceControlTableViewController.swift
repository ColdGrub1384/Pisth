// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Static table view controller to manage source control.
class SourceControlTableViewController: UITableViewController {
    
    /// Git repo path.
    var repoPath: String!
    
    /// Dismiss `navigationController`.
    @IBAction func done(sender: Any) {
        if let navVC = navigationController {
            navVC.dismiss(animated: true, completion: nil)
        }
    }
    
    /// MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = true
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            performSegue(withIdentifier: "local", sender: nil)
        } else if indexPath.row == 1 {
            performSegue(withIdentifier: "remote", sender: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let remotesVC = segue.destination as? GitRemotesTableViewController { // Open remotes
            remotesVC.repoPath = repoPath
        }
        
        if let remotesVC = segue.destination as? GitBranchesTableViewController { // Open branches
            remotesVC.repoPath = repoPath
        }
    }
}
