// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa

/// File browser sidebar.
class BrowserSidebarOutlineView: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    /// Item represented in the sidebar.
    struct Item {
        /// Title of the item.
        var title: String
        
        /// Value of the item.
        var value: String
    }
    
    /// `true` for ignoring the next selection.
    var ignoreSelection = false
    
    /// Items in the sidebar.
    var items = [Item]()
    
    // MARK: - View
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        delegate = self
        dataSource = self
    }
    
    // MARK: - Data source
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return items[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return items.count
    }
    
    // MARK: - Delegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Item else {
            return nil
        }
        
        guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) else {
            return nil
        }
        
        (cell.viewWithTag(1) as? NSTextField)?.stringValue = item.title
        if item.value == (window?.contentViewController as? DirectoryViewController)?.controller.home {
            (cell.viewWithTag(2) as? NSImageView)?.image = NSImage(named: NSImage.homeTemplateName)
        } else if item.value == "/" {
            (cell.viewWithTag(2) as? NSImageView)?.image = NSImage(named: NSImage.computerName)
        } else {
            (cell.viewWithTag(2) as? NSImageView)?.image = NSImage(named: NSImage.folderName)
        }
        
        return cell
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let dirVC = window?.contentViewController as? DirectoryViewController, !ignoreSelection {
            dirVC.go(to: items[selectedRow].value.replacingFirstOccurrence(of: "~", with: dirVC.controller.home ?? "~"))
        }
        ignoreSelection = false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return true
    }
}
