// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import Pisth_Shared

/// The app's delegate.
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    /// The "File" menu.
    @IBOutlet weak var fileMenu: NSMenu!
    
    /// The "Theme" menu.
    @IBOutlet weak var themesMenu: NSMenu!
    
    /// The "Text size" menu.
    @IBOutlet weak var textSizeMenu: NSMenu!
    
    /// Open Pisth Viewer.
    @IBAction func openPisthViewer(_ sender: Any) {
        if let pisthViewer = Bundle.main.path(forResource: "Pisth Viewer", ofType: "app") {
            NSWorkspace.shared.openFile(pisthViewer)
        }
    }
    
    // MARK: - "Connection" menu
    
    // MARK: - Menu delegate
    
    func menuWillOpen(_ menu: NSMenu) {
        
        // Enable items if the selected row is a `RemoteConnection`.
        
        guard let bookmarksVC = NSApp.keyWindow?.contentViewController as? BookmarksViewController else {
            for item in menu.items {
                item.isEnabled = false
            }
            return
        }
        
        for item in menu.items {
            if item.title != "New" {
                item.isEnabled = (bookmarksVC.outlineView.item(atRow: bookmarksVC.outlineView.selectedRow) is RemoteConnection)
            } else {
                item.isEnabled = true
            }
        }
    }
    
    // MARK: - Menu actions
    
    /// Open the connection represented by the clicked row.
    @IBAction func openConnection(_ sender: Any) {
        guard let bookmarksVC = NSApp.keyWindow?.contentViewController as? BookmarksViewController else {
            return
        }
        
        bookmarksVC.openConnection(sender)
    }
    
    /// Edit the connection represented by the clicked row.
    @IBAction func editConnection(_ sender: Any) {
        guard let sheet = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "connectionInfo") as? ConnectionInfoViewController else {
            return
        }
        
        guard let bookmarksVC = NSApp.keyWindow?.contentViewController as? BookmarksViewController else {
            return
        }
        
        sheet.index = bookmarksVC.outlineView.selectedRow-1
        
        NSApp.keyWindow?.contentViewController?.presentAsSheet(sheet)
    }
    
    /// Delete the connection represented by the clicked row.
    @IBAction func deleteConnection(_ sender: Any) {
        
        guard let bookmarksVC = NSApp.keyWindow?.contentViewController as? BookmarksViewController else {
            return
        }
        
        DataManager.shared.removeConnection(at: bookmarksVC.outlineView.selectedRow-1)
    }
    
    /// Create a new connection.
    @IBAction func newConnection(_ sender: Any) {
        guard let sheet = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "connectionInfo") as? ConnectionInfoViewController else {
            return
        }
        
        guard NSApp.keyWindow?.contentViewController is BookmarksViewController else {
            return
        }
        NSApp.keyWindow?.contentViewController?.presentAsSheet(sheet)
    }
    
    /// Set theme from clicked item.
    @objc func setTheme(_ sender: NSMenuItem) {
        UserKeys.terminalTheme.stringValue = sender.title
        setupThemeMenu()
        
        for window in NSApp.windows {
            if let term = window.contentViewController as? TerminalViewController {
                term.theme = TerminalTheme.themes[UserKeys.terminalTheme.stringValue ?? "Basic"]!
                term.webView.reload()
            }
        }
    }
    
    /// Set text size from clicked item.
    @objc func setTextSize(_ sender: NSMenuItem) {
        UserKeys.terminalTextSize.integerValue = sender.tag
        setupTextSizeMenu()
        
        for window in NSApp.windows {
            if let term = window.contentViewController as? TerminalViewController {
                term.webView.reload()
            }
        }
    }
    
    /// Setup `themesMenu`.
    func setupThemeMenu() {
        
        themesMenu.items = []
        
        for (name, value) in TerminalTheme.themes {
            let item = NSMenuItem(title: name, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.isEnabled = true
            if UserKeys.terminalTheme.stringValue == item.title {
                item.state = .on
            }
            
            let size = NSSize(width: 50, height: 50)
            let image = NSImage(size: size)
            image.lockFocus()
            value.backgroundColor?.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
            let attrString = NSAttributedString(string: "$", attributes: [.foregroundColor : value.foregroundColor as Any, .font : NSFont(name: "courier", size: 25) as Any])
            attrString.draw(in: NSMakeRect(0, 0, size.width, size.height))
            image.unlockFocus()
            
            item.image = image
            
            themesMenu.items.append(item)
        }
    }
    
    /// Setup `textSizeMenu`.
    func setupTextSizeMenu() {
        
        textSizeMenu.items = []
        
        for size in 12...18 {
            var item: NSMenuItem
            if size == 12 {
                item = NSMenuItem(title: "\(size)px (Default)", action: #selector(setTextSize(_:)), keyEquivalent: "")
            } else {
                item = NSMenuItem(title: "\(size)px", action: #selector(setTextSize(_:)), keyEquivalent: "")
            }
            item.isEnabled = true
            if UserKeys.terminalTextSize.integerValue == size {
                item.state = .on
            }
            item.tag = size
            textSizeMenu.items.append(item)
        }
    }
    
    // MARK: - Application delegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if UserKeys.terminalTheme.stringValue == nil {
            UserKeys.terminalTheme.stringValue = "Basic"
        }
        
        if UserKeys.terminalTextSize.value == nil {
            UserKeys.terminalTextSize.integerValue = 12
        }
        
        setupTextSizeMenu()
        setupThemeMenu()
    }
}

