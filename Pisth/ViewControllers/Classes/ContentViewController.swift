// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import PanelKit
import Pisth_Shared

/// A View controller for showing connection content.
class ContentViewController: UIViewController, PanelManager, Storyboard {
    
    /// The panel containing the current terminal.
    var terminalPanels = [PanelViewController]()
    
    private var directoryPanels = [PanelViewController]()
    
    /// The wrapper view for using with `PanelKit`
    @IBOutlet weak var wrapperView: UIView!
    
    /// The content view.
    @IBOutlet weak var contentView: UIView!
    
    /// Present the terminal. This view controller must be visible.
    ///
    /// - Parameters:
    ///     - directory: The directory to be the cwd.
    ///     - command: The command to execute.
    ///     - sender: The sender bar button item.
    ///     - view: The sender view.
    func presentTerminal(inDirectory directory: String? = nil, command: String? = nil, from sender: UIBarButtonItem? = nil, fromView sourceView: UIView? = nil) {
        
        let terminal = TerminalViewController()
        terminal.pwd = directory
        terminal.command = command
        terminal.console = ""
        
        let terminalPanel = PanelViewController(with: terminal, in: self)
        terminalPanel.modalPresentationStyle = .popover
        terminalPanel.popoverPresentationController?.barButtonItem = sender
        if let view = sourceView {
            terminalPanel.popoverPresentationController?.sourceView = view
            terminalPanel.popoverPresentationController?.sourceRect = view.bounds
        }
        
        var vc: UIViewController? = self
        if view.window == nil {
            vc = UIApplication.shared.keyWindow?.rootViewController
        }
        func present() {
            vc?.present(terminalPanel, animated: true) {
                if terminalPanel.canFloat {
                    self.toggleFloatStatus(for: terminalPanel)
                }
                if #available(iOS 11.0, *) {
                    terminal.panelNavigationController?.navigationBar.tintColor = UIColor(named: "Purple")
                }
            }
        }
        
        if terminalPanels.count > 0 {
            terminal.pureMode = true
            let connection = ConnectionManager.shared.connection
            connection?.useSFTP = false
            let connectionManager = ConnectionManager(connection: connection)
            terminal.connectionManager = connectionManager
            let activityVC = ActivityViewController(message: Localizable.BookmarksTableViewController.connecting)
            self.present(activityVC, animated: true) {
                connectionManager.connect()
                activityVC.dismiss(animated: true, completion: {
                    present()
                })
            }
        } else {
            present()
        }
        terminalPanels.append(terminalPanel)
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
            if #available(iOS 11.0, *) {
                browser.panelNavigationController?.navigationBar.tintColor = UIColor(named: "Purple")
            }
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
        var panels = directoryPanels
        panels.append(contentsOf: terminalPanels)
        return panels
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
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "Content", bundle: nil)
    }
    
    // MARK: - Static
    
    /// Last visible instance.
    static var shared: ContentViewController!
}
