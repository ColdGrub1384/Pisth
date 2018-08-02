// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Split view controller used on the window.
class SplitViewController: UISplitViewController {
    
    /// App Navigation view controller.
    var navigationController_: UINavigationController!
    
    /// App Detail Navigation view controller.
    var detailNavigationController: UINavigationController!
    
    /// A detail view controller. If it's set, you must set `detailNavigationController`. This View controller will be displayed and `detailNavigationController` will be passed to `AppDelegate.shared`.
    var detailViewController: UIViewController?
    
    private var presentedBetaAlert = false
    
    /// Show given view controllers and pass them to `AppDelegate.shared`.
    func load() {
        preferredDisplayMode = .primaryHidden
        if let detailViewController = detailViewController {
            viewControllers = [navigationController_, detailViewController]
        } else {
            viewControllers = [navigationController_, detailNavigationController]
        }
    }
    
    /// Set display mode for opening a connection.
    func setDisplayMode() {
        if isCollapsed {
            preferredDisplayMode = .primaryHidden
        } else {
            preferredDisplayMode = .primaryOverlay
            if let action = displayModeButtonItem.action {
                UIApplication.shared.sendAction(action, to: displayModeButtonItem.target, from: nil, for: nil)
            }
        }
    }
    
    /// Toggle the master view.
    func toggleMasterView() {
        guard displayModeButtonItem.action != nil else {
            return
        }
        UIApplication.shared.sendAction(displayModeButtonItem.action!, to: displayModeButtonItem.target, from: nil, for: nil)
    }
    
    /// Set preferred display mode.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        preferredDisplayMode = .primaryHidden
        
        let betaAlert = UIAlertController(title: "Thanks for using Pisth beta!", message: "Don't forget to report any issue you see.", preferredStyle: .alert)
        betaAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        if (Bundle.main.infoDictionary?["Is Beta"] as? String) == "YES" && !presentedBetaAlert {
            present(betaAlert, animated: true, completion: nil)
            presentedBetaAlert = true
        }
    }
    
    // MARK: - Split view controller
    
    /// Search for the `preferredStatusBarStyle` of the visible view controller or returns `.default`.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.navigationController.visibleViewController?.preferredStatusBarStyle ?? .default
    }
}
