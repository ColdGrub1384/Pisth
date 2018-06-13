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
    
    private var terminalPanel: PanelViewController!
    
    private var directoryPanel: PanelViewController!
    
    /// The wrapper view for using with `PanelKit`
    @IBOutlet weak var wrapperView: UIView!
    
    /// The content view.
    @IBOutlet weak var contentView: UIView!
    
    /// Present the terminal in given directory from given sender. This view controller must be visible.
    func presentTerminal(inDirectory directory: String, from sender: UIBarButtonItem?) {
        
        let terminal = TerminalViewController()
        terminal.pwd = directory
        terminal.console = ""
        
        terminalPanel = PanelViewController(with: terminal, in: self)
        terminalPanel.modalPresentationStyle = .popover
        terminalPanel.popoverPresentationController?.barButtonItem = sender
        
        present(terminalPanel, animated: true)
    }
    
    /// Present the given remote directory. This view controller must be visible.
    func presentBrowser(inDirectory directory: String, from sender: UIView?) {
        
        guard let connection = ConnectionManager.shared.connection else {
            return
        }
        
        let browser = DirectoryTableViewController(connection: connection, directory: directory)
        
        directoryPanel = PanelViewController(with: browser, in: self)
        directoryPanel.modalPresentationStyle = .popover
        directoryPanel.popoverPresentationController?.sourceView = sender
        directoryPanel.popoverPresentationController?.sourceRect = sender?.frame ?? CGRect.zero
        
        present(directoryPanel, animated: true)
    }
    
    // MARK: - View controller
    
    /// Setup singleton
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ContentViewController.shared = self
    }
    
    // MARK: - Panel manager
    
    /// Returns `ContentViewController.shared.wrapperView`.
    var panelContentWrapperView: UIView {
        return wrapperView
    }
    
    /// Returns `ContentViewController.shared.contentView`.
    var panelContentView: UIView {
        return contentView
    }
    
    /// Returns `[terminal]`.
    var panels: [PanelViewController] {
        var panels_ = [PanelViewController]()
        
        if let terminalPanel = terminalPanel {
            panels_.append(terminalPanel)
        }
        
        if let directoryPanel = directoryPanel {
            panels_.append(directoryPanel)
        }
        
        return panels_
    }
    
    /// Returns `2`.
    func maximumNumberOfPanelsPinned(at side: PanelPinSide) -> Int {
        return 2
    }
    
    /// Returns `true`.
    var allowPanelPinning: Bool {
        return true
    }
    
    /// Returns `true`.
    var allowFloatingPanels: Bool {
        return true
    }
    
    // MARK: - Static
    
    /// Last visible instance.
    static var shared: ContentViewController!
}
