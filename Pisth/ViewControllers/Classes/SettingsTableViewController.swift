// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

class SettingsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    enum Index: Int {
        case licenses = 0
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case Index.licenses.rawValue:
            // Open Licenses
            let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            navigationController?.pushViewController(webVC, animated: true)
        default:
            break
        }
    }
}
