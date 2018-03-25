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
    
    /// Launch command in a terminal with given title.
    ///
    /// - Parameters:
    ///     - command: Command to launch.
    ///     - title: Title of the view controller.
    func launch(command: String, withTitle title: String) {
        guard let termVC = Bundle.main.loadNibNamed("Terminal", owner: nil, options: nil)?[0] as? TerminalViewController else {
            return
        }
        
        termVC.command = "clear; \(command); echo -e \"\\033[CLOSE\""
        termVC.title = title
        
        let navVC = UINavigationController(rootViewController: termVC)
        navVC.view.backgroundColor = .clear
        navVC.modalPresentationStyle = .overCurrentContext
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Install package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func install(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes install '\(package ?? "")'", withTitle: "Installing \(package ?? "")...")
    }
    
    /// Update package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func update(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes install --only-upgrade '\(package ?? "")'", withTitle: "Upgrading \(package ?? "")...")
    }
    
    /// Remove package.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func remove(_ sender: Any) {
        launch(command: "sudo apt-get --assume-yes purge --auto-remove '\(package ?? "")'", withTitle: "Removing \(package ?? "")...")
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
