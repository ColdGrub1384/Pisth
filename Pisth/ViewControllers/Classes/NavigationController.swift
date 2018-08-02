// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// The main `UINavigationController`.
class NavigationController: UINavigationController {
    
    private var isSet = false
    
    /// Setup app window.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !isSet else {
            return
        }
        
        isSet = true
        
        AppDelegate.shared.navigationController = self
        
        // Setup Navigation Controller
        let bookmarksVC = BookmarksTableViewController()
        bookmarksVC.modalPresentationStyle = .overCurrentContext
        bookmarksVC.view.backgroundColor = .clear
        bookmarksVC.tableView.backgroundColor = .clear
        bookmarksVC.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        let navigationController = UINavigationController(rootViewController: bookmarksVC)
        navigationController.navigationBar.prefersLargeTitles = true
        
        // Setup Split view controller
        let splitViewController = SplitViewController()
        splitViewController.preferredDisplayMode = .primaryHidden
        splitViewController.navigationController_ = navigationController
        splitViewController.detailViewController = ContentViewController.shared
        splitViewController.detailNavigationController = self
        AppDelegate.shared.window?.rootViewController = UIViewController()
        splitViewController.load()
        splitViewController.view.backgroundColor = .white
        splitViewController.delegate = AppDelegate.shared
        AppDelegate.shared.splitViewController = splitViewController
        
        // Setup window
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.tintColor = UIApplication.shared.keyWindow?.tintColor
        window.backgroundColor = .white
        window.rootViewController = splitViewController
        window.makeKeyAndVisible()
        AppDelegate.shared.window = window
    }
}
