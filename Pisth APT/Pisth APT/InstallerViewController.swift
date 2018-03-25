// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// View controller for displaying a package.
class InstallerViewController: UIViewController {
    
    /// The package to show.
    var package: String?
    
    /// Activity view.
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    /// Label containing package name.
    @IBOutlet weak var packageNameLabel: UILabel!
    
    /// Text view containing package description.
    @IBOutlet weak var packageDescriptionTextView: UITextView!
    
    /// Button for removing the package.
    @IBOutlet weak var removeButton: UIBarButtonItem!
    
    /// Button for updating the package.
    @IBOutlet weak var updateButton: UIBarButtonItem!
    
    /// Button for installing the package.
    @IBOutlet weak var installButton: UIBarButtonItem!
    
    /// Close this view controller.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    /// Setup views
    override func viewDidLoad() {
        super.viewDidLoad()
        
        packageNameLabel.text = ""
        packageDescriptionTextView.text = ""
    }
    
    /// Fetch info.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        packageNameLabel.text = package
        
        if let package = package {
            if let session = AppDelegate.shared.session {
                if session.isConnected && session.isAuthorized {
                    if let description = try? session.channel.execute("aptitude show '\(package)'") {
                        packageDescriptionTextView.text = description
                    }
                }
            }
            
            
            updateButton.isEnabled = AppDelegate.shared.updates.contains(package)
            installButton.isEnabled = !AppDelegate.shared.installed.contains(package)
            removeButton.isEnabled = AppDelegate.shared.installed.contains(package)
            
            activityView.isHidden = true
        }
    }
}
