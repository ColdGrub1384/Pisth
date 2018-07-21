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
    
    /// Show given view controllers and pass them to `AppDelegate.shared`.
    func load() {
        preferredDisplayMode = .primaryHidden
        viewControllers = [navigationController_, detailNavigationController]
    }
    
    /// Set display mode for opening a connection.
    func setDisplayMode() {
        if AppDelegate.shared.splitViewController.isCollapsed {
            AppDelegate.shared.splitViewController.preferredDisplayMode = .primaryHidden
        } else {
            AppDelegate.shared.splitViewController.preferredDisplayMode = .primaryOverlay
            let button = AppDelegate.shared.splitViewController.displayModeButtonItem
            _ = button.target?.perform(button.action)
        }
    }
    
    /// Set preferred display mode.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        preferredDisplayMode = .primaryHidden
    }
    
    // MARK: - Split view controller
    
    /// Search for the `preferredStatusBarStyle` of the visible view controller or returns `.default`.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.navigationController.visibleViewController?.preferredStatusBarStyle ?? .default
    }
}
