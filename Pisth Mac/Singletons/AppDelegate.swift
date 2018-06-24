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
}

