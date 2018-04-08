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
    
    /// Setup view controllers.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isCollapsed {
            viewControllers = [navigationController_]
            AppDelegate.shared.navigationController = navigationController_
        } else {
            preferredDisplayMode = .allVisible
            viewControllers = [navigationController_, detailNavigationController]
            AppDelegate.shared.navigationController = detailNavigationController
        }
    }
    
}
