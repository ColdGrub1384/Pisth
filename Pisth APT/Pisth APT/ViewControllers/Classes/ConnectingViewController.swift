// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// A View controller for loading a connection.
class ConnectingViewController: UIViewController {
    
    /// Image view containing the OS logo.
    @IBOutlet weak var osLogo: UIImageView!
    
    /// Label containing the text.
    @IBOutlet weak var label: UILabel!
    
    /// Connection to fetch its information
    var connection: RemoteConnection?
    
    // MARK: - View controller
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            osLogo.accessibilityIgnoresInvertColors = true
        }
        
        if let connection = connection {
            if let os = connection.os?.lowercased() {
                osLogo.image = UIImage(named: (os.slice(from: " id=", to: " ")?.replacingOccurrences(of: "\"", with: "") ?? os).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: ""))
            }
            
            var description: String
            
            if connection.name.isEmpty {
                description = "\(connection.username)@\(connection.host)"
            } else {
                description = connection.name
            }
            
            label.text = "Connecting to \(description)..."
        }
    }
}
