// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import SafariServices

/// View controller for inviting people to contribute to this project.
class ContributeViewController: UIViewController {
    
    @IBAction func showSourceCode(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string:"https://github.com/ColdGrub1384/Pisth")!)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
