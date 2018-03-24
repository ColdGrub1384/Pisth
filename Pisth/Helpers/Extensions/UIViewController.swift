// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

extension UIViewController {
    
    /// Returns the code editor initialised from nib.
    static var codeEditor: EditTextViewController {
        return (Bundle.main.loadNibNamed("Code Editor", owner: nil, options: nil)?[0] as? EditTextViewController) ?? EditTextViewController()
    }
    
    /// Returns the Web view controller initialised from nib.
    static var webViewController: WebViewController {
        return (Bundle.main.loadNibNamed("Web", owner: nil, options: nil)?[0] as? WebViewController) ?? WebViewController()
    }
    
    /// Returns the image viewer initialised from nib.
    static var imageViewer: ImageViewController {
        return (Bundle.main.loadNibNamed("Image", owner: nil, options: nil)?[0] as? ImageViewController) ?? ImageViewController()
    }
    
    /// Returns settings initialised from storyboard.
    static var settings: SettingsTableViewController {
        return (UIStoryboard(name: "Settings", bundle: Bundle.main).instantiateInitialViewController() as? SettingsTableViewController) ?? SettingsTableViewController()
    }
    
    /// Returns the themes store initialised from nib.
    static var themesStore: ThemesStoreViewController {
        return (Bundle.main.loadNibNamed("Themes Store", owner: nil, options: nil)?[0] as? ThemesStoreViewController) ?? ThemesStoreViewController()
    }
    
    /// Returns the navigation controller with `SourceControlTableViewController` initialised from storyboard.
    static var gitNavigationController: UINavigationController {
        return (UIStoryboard(name: "Git", bundle: Bundle.main).instantiateInitialViewController() as? UINavigationController) ?? UINavigationController()
    }
    
    /// Returns the `GitRemotesTableViewController` from storyboard.
    static var gitRemoteBranches: GitRemotesTableViewController {
        return (UIStoryboard(name: "Git", bundle: Bundle.main).instantiateViewController(withIdentifier: "remoteBranches") as? GitRemotesTableViewController) ?? GitRemotesTableViewController()
    }
    
    /// Returns the `GitBranchesTableViewController` from storyboard.
    static var gitBranches: GitBranchesTableViewController {
        return (UIStoryboard(name: "Git", bundle: Bundle.main).instantiateViewController(withIdentifier: "localBranches") as? GitBranchesTableViewController) ?? GitBranchesTableViewController()
    }
    
    /// Returns the `ConnectionInformationTableViewController` from storyboard.
    static var connectionInfo: ConnectionInformationTableViewController {
        return (UIStoryboard(name: "Connection Info", bundle: Bundle(for: ConnectionInformationTableViewController.self)).instantiateInitialViewController() as? ConnectionInformationTableViewController) ?? ConnectionInformationTableViewController(style: .plain)
    }
    
    /// Returns the View controller to invite people to contribute.
    static var contribute: ContributeViewController {
        return (Bundle.main.loadNibNamed("Contribute", owner: nil, options: nil)?[0] as? ContributeViewController) ?? ContributeViewController()
    }
    
    /// Returns the View controller to invite people to participate in beta testing.
    static var beta: BetaViewController {
        return (Bundle.main.loadNibNamed("Beta", owner: nil, options: nil)?[0] as? BetaViewController) ?? BetaViewController()
    }
}
