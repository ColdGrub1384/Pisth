//
//  TerminalSplitViewController.swift
//  Pisth
//
//  Created by Adrian Labbé on 30-08-19.
//  Copyright © 2019 ADA. All rights reserved.
//

import UIKit

/// A Split view controller containing the terminal as primary and a Directory view controller as detail.
class TerminalSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        
        if let term = (viewControllers.last as? UINavigationController)?.viewControllers.first as? TerminalViewController {
            let wasFirstResponder = term.isFirstResponder
            if wasFirstResponder {
                _ = term.resignFirstResponder()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                term.reload()
                if wasFirstResponder {
                    _ = term.becomeFirstResponder()
                }
            }
        }
    }
}
