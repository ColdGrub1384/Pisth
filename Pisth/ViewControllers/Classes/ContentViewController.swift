// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import PanelKit

/// A View controller for showing connection content.
class ContentViewController: UIViewController, PanelManager {
    
    /// The panel containing the current terminal.
    var terminalPanel: PanelViewController!
    
    private var directoryPanels = [PanelViewController]()
    
    /// The wrapper view for using with `PanelKit`
    @IBOutlet weak var wrapperView: UIView!
    
    /// The content view.
    @IBOutlet weak var contentView: UIView!
    
    /// Present the terminal in given directory from given sender. This view controller must be visible.
    func presentTerminal(inDirectory directory: String, from sender: UIBarButtonItem?) {
        
        if let terminal = terminalPanel?.contentViewController as? TerminalViewController, terminal.view.window != nil {
            terminal.console = ""
            terminal.pwd = directory
            terminal.reload()
        } else {
            
            let terminal = TerminalViewController()
            terminal.pwd = directory
            terminal.console = ""
            
            terminalPanel = PanelViewController(with: terminal, in: self)
            terminalPanel.modalPresentationStyle = .popover
            terminalPanel.popoverPresentationController?.barButtonItem = sender
            
            var vc: UIViewController? = self
            if view.window == nil {
                vc = UIApplication.shared.keyWindow?.rootViewController
            }
            
            vc?.present(terminalPanel, animated: true) {
                if self.terminalPanel.canFloat {
                    self.toggleFloatStatus(for: self.terminalPanel)
                }
                terminal.panelNavigationController?.navigationBar.tintColor = UIColor(named: "Purple")
            }
        }
    }
    
    /// Present the given remote directory. This view controller must be visible.
    func presentBrowser(inDirectory directory: String, from sender: UIView?) {
        
        guard let connection = ConnectionManager.shared.connection else {
            return
        }
        
        let browser = DirectoryCollectionViewController(connection: connection, directory: directory)
        
        let directoryPanel = PanelViewController(with: browser, in: self)
        directoryPanel.modalPresentationStyle = .popover
        directoryPanel.popoverPresentationController?.sourceView = sender
        directoryPanel.popoverPresentationController?.sourceRect = sender?.frame ?? CGRect.zero
        
        directoryPanels.append(directoryPanel)
        
        var vc: UIViewController? = self
        if view.window == nil {
            vc = UIApplication.shared.keyWindow?.rootViewController
        }
        
        vc?.present(directoryPanel, animated: true) {
            if directoryPanel.canFloat {
                self.toggleFloatStatus(for: directoryPanel)
            }
            browser.panelNavigationController?.navigationBar.tintColor = UIColor(named: "Purple")
        }
    }
    
    // MARK: - View controller
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        // Search for the `preferredStatusBarStyle` of the visible view controller or returns `.default`.
        
        var defaultStyle: UIStatusBarStyle
        if !isShell {
            defaultStyle = .default
        } else {
            defaultStyle = .lightContent
            
            guard !(presentedViewController is UIAlertController) else {
                return defaultStyle
            }
        }
        
        return presentedViewController?.preferredStatusBarStyle ?? AppDelegate.shared.navigationController.visibleViewController?.preferredStatusBarStyle ?? defaultStyle
    }
    
    // MARK: - Panel manager
    
    var panelContentWrapperView: UIView {
        return wrapperView
    }
    
    var panelContentView: UIView {
        return contentView
    }
    
    var panels: [PanelViewController] {
        var panels_ = directoryPanels
        if let term = terminalPanel {
            panels_.append(term)
        }
        return panels_
    }
    
    func maximumNumberOfPanelsPinned(at side: PanelPinSide) -> Int {
        return 2
    }
    
    var allowPanelPinning: Bool {
        return true
    }
    
    var allowFloatingPanels: Bool {
        return true
    }
    
    func didUpdatePinnedPanels() {
        
        // Update `DirectoryCollectionViewController`s layouts.
        
        var viewControllers = [DirectoryCollectionViewController]()
        for panel in panels {
            if let dirVC = panel.contentViewController as? DirectoryCollectionViewController {
                viewControllers.append(dirVC)
            }
        }
        for vc in AppDelegate.shared.navigationController.viewControllers {
            if let dirVC = vc as? DirectoryCollectionViewController {
                viewControllers.append(dirVC)
            }
        }
        
        for dirVC in viewControllers {
            if let layout = dirVC.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != DirectoryCollectionViewController.gridLayout.itemSize {
                layout.itemSize.width = dirVC.view.frame.width
            }
        }
    }
    
    // MARK: - Static
    
    /// Last visible instance.
    static var shared: ContentViewController!
}
