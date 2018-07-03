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
    
    /// Setup view controllers.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isCollapsed {
            viewControllers = [navigationController_]
            AppDelegate.shared.navigationController = navigationController_
        } else {
            preferredDisplayMode = .allVisible
            if let detailViewController = detailViewController {
                viewControllers = [navigationController_, detailViewController]
            } else {
                viewControllers = [navigationController_, detailNavigationController]
            }
            AppDelegate.shared.navigationController = detailNavigationController
        }
    }
    
    /// Search for the `preferredStatusBarStyle` for the visible view controller or returns `.default`.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.navigationController.visibleViewController?.preferredStatusBarStyle ?? .default
    }
}
