// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// Main tab controller.
class TabBarController: UITabBarController {

    /// Main instance.
    static var shared: TabBarController!
    
    /// Custom connection to use.
    var customConnection: RemoteConnection?
    
    // MARK: - View controller
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        TabBarController.shared = self
    }
}
