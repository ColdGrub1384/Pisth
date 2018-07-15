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
    
    // MARK: - "Connection" menu
    
    // MARK: - Menu delegate
    
    /// Enable items if the selected row is a `RemoteConnection`.
    func menuWillOpen(_ menu: NSMenu) {
        guard let bookmarksVC = NSApp.keyWindow?.contentViewController as? BookmarksViewController else {
            for item in menu.items {
                item.isEnabled = false
            }
            return
        }
        
        for item in menu.items {
            item.isEnabled = (bookmarksVC.outlineView.item(atRow: bookmarksVC.outlineView.selectedRow) is RemoteConnection)
        }
    }
    
    // MARK: - Menu actions
    
    /// Open the connection represented by the clicked row.
    @IBAction func openConnection(_ sender: Any) {
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
    
    /// Set theme from clicked item.
    @objc func setTheme(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "theme")
        UserDefaults.standard.synchronize()
        setupThemeMenu()
        
        for window in NSApp.windows {
            if let term = window.contentViewController as? TerminalViewController {
                term.theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "theme") ?? "Basic"]!
                term.webView.reload()
            }
        }
    }
    
    /// Set text size from clicked item.
    @objc func setTextSize(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag, forKey: "textSize")
        UserDefaults.standard.synchronize()
        setupTextSizeMenu()
        
        for window in NSApp.windows {
            if let term = window.contentViewController as? TerminalViewController {
                term.theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "theme") ?? "Basic"]!
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
            if UserDefaults.standard.string(forKey: "theme") == item.title {
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
            if UserDefaults.standard.integer(forKey: "textSize") == size {
                item.state = .on
            }
            item.tag = size
            textSizeMenu.items.append(item)
        }
    }
    
    // MARK: - Application delegate
    
    /// Setup menus.
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if UserDefaults.standard.string(forKey: "theme") == nil {
            UserDefaults.standard.set("Basic", forKey: "theme")
            UserDefaults.standard.synchronize()
        }
        
        if UserDefaults.standard.value(forKey: "textSize") == nil {
            UserDefaults.standard.set(12, forKey: "textSize")
            UserDefaults.standard.synchronize()
        }
        
        setupTextSizeMenu()
        setupThemeMenu()
    }
}

