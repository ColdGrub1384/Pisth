// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller displaying an error at top and a `TabBarController` at bottom.
class ErrorViewController: UIViewController {
    
    /// Button to go to settings.
    @IBOutlet weak var goToSettingsButton: UIButton!
    
    /// Button to retry connection.
    @IBOutlet weak var retryButton: UIButton!
    
    /// Label containing the title of the error.
    @IBOutlet weak var errorTitleLabel: UILabel!
    
    /// Label containing the description of the error.
    @IBOutlet weak var errorLabel: UILabel!
    
    /// View showing the error.
    @IBOutlet weak var errorView: UIView!
    
    /// Go to connections settings.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func goToSettings(_ sender: Any) {
        let settings = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "connections settings")
        let navVC = UINavigationController(rootViewController: settings)
        settings.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeTopViewController))
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Retry to open the session.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func retry(_ sender: Any) {
        
        if let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() {
            UIApplication.shared.keyWindow?.rootViewController = vc
            
            let activityVC = ActivityViewController(message: "Loading...")
            vc.present(activityVC, animated: true) {
                AppDelegate.shared.connect()
                activityVC.dismiss(animated: true, completion: {
                    
                    // Search for updates
                    let activityVC = ActivityViewController(message: "Loading...")
                        vc.present(activityVC, animated: true) {
                        AppDelegate.shared.searchForUpdates()
                        activityVC.dismiss(animated: true, completion: nil)
                    }
                    
                })
            }
        }
    }
    
    @objc private func closeTopViewController() {
        (UIApplication.shared.keyWindow?.topViewController() ?? self).dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorView.clipsToBounds = true
        errorView.layer.cornerRadius = 20
        errorView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let session = AppDelegate.shared.session {
            if session.isConnected && session.isAuthorized {
                if let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() {
                    UIApplication.shared.keyWindow?.rootViewController = vc
                }
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
