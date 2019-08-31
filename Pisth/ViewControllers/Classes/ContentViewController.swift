// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// A View controller for showing connection content.
class ContentViewController: UIViewController, Storyboard {
    
    /// The panel containing the current terminal.
    var terminalPanels = [UINavigationController]()
    
    private var directoryPanels = [UINavigationController]()
    
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
        
        guard ConnectionManager.shared.connection != nil else {
            return
        }
        
        let terminal = TerminalViewController()
        terminal.pwd = directory
        terminal.command = command
        terminal.console = ""
        
        let terminalPanel = UINavigationController(rootViewController: terminal)
        terminalPanel.navigationBar.isTranslucent = false
        
        var vc: UIViewController? = self
        if view.window == nil {
            vc = UIApplication.shared.keyWindow?.rootViewController
        }
        func present() {
            
            let splitVC = TerminalSplitViewController()
            
            let browser = DirectoryCollectionViewController(connection: ConnectionManager.shared.connection!, directory: directory)
            let directoryPanel = UINavigationController(rootViewController: browser)
            
            splitVC.viewControllers = [directoryPanel, terminalPanel]
            splitVC.preferredDisplayMode = .allVisible
            splitVC.modalPresentationStyle = .fullScreen
            
            vc?.present(splitVC, animated: true) {
                if #available(iOS 11.0, *) {
                    terminalPanel.navigationBar.tintColor = UIColor(named: "Purple")
                }
            }
        }
        
        if terminalPanels.count > 0 {
            terminal.pureMode = true
            let connection = ConnectionManager.shared.connection
            connection?.useSFTP = false
            let connectionManager = ConnectionManager(connection: connection)
            terminal.connectionManager = connectionManager
            connectionManager.runTask {
                connectionManager.connect()
            }
            present()
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
        
        let directoryPanel = UINavigationController(rootViewController: browser)
        directoryPanels.append(directoryPanel)
        
        var vc: UIViewController? = self
        if view.window == nil {
            vc = UIApplication.shared.keyWindow?.rootViewController
        }
        
        vc?.present(directoryPanel, animated: true) {
            if #available(iOS 11.0, *) {
                directoryPanel.navigationBar.tintColor = UIColor(named: "Purple")
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        // Search for the `preferredStatusBarStyle` of the visible view controller or returns `.default`.
        
        return presentedViewController?.preferredStatusBarStyle ?? AppDelegate.shared.navigationController.visibleViewController?.preferredStatusBarStyle ?? .default
    }
    
    override var keyCommands: [UIKeyCommand]? {
        if TerminalViewController.current != nil {
            return terminalKeyCommands
        } else {
            return nil
        }
    }
    
    // MARK: - Terminal commands
    
    /// Pastes text into the terminal
    @objc func pasteText() {
        TerminalViewController.current?.pasteText()
    }
    
    /// Writes to the terminal.
    ///
    /// - Parameters:
    ///     - command: The command to be sent.
    @objc func write(fromCommand command: UIKeyCommand) {
        TerminalViewController.current?.write(fromCommand: command)
    }
    
    /// The Key commands used on the terminal.
    var terminalKeyCommands: [UIKeyCommand] {
        var commands =  [
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(pasteText), discoverabilityTitle: Localizable.TerminalViewController.paste),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendUpArrow),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendDownArrow),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendLeftArrow),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendRightArrow),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendEsc),
            ]
        
        let ctrlKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_"] // All CTRL keys
        for ctrlKey in ctrlKeys {
            commands.append(UIKeyCommand(input: ctrlKey, modifierFlags: .control, action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendCtrl(ctrlKey)))
        }
        
        return commands
    }
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "Content", bundle: nil)
    }
    
    // MARK: - Static
    
    /// Last visible instance.
    static var shared: ContentViewController!
}
