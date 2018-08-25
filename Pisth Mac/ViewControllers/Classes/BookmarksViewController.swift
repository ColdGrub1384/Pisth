// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import Pisth_Shared

/// A view controller showing saved bookmarks.
class BookmarksViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate {
    
    /// The outline view showing connections.
    @IBOutlet weak var outlineView: NSOutlineView!
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.shared.saveCompletion = {
            self.outlineView.reloadData()
        }
        
        outlineView.doubleAction = #selector(openConnection(_:))
    }
    
    // MARK: - Outline view data source
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return DataManager.shared.connections.count+1
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if index == 0 {
            return 0
        }
        
        return DataManager.shared.connections[index-1]
    }
    
    // MARK: - Outline view delegate
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return (item is RemoteConnection)
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if (item as? Int) == 0 {
            let header = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: self)
            return header
        } else if let connection = item as? RemoteConnection {
            guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) else {
                return nil
            }
            
            for view in cell.subviews {
                if let textField = view as? NSTextField {
                    if connection.name != "" {
                        textField.stringValue = connection.name
                    } else {
                        textField.stringValue = "\(connection.username)@\(connection.host):\(connection.port)"
                        if connection.useSFTP {
                            textField.stringValue += "/\(connection.path)"
                        }
                    }
                }
            }
            
            return cell
        }
        
        return nil
    }
    
    // MARK: - Menu delegate
    
    func menuWillOpen(_ menu: NSMenu) {
        for item in menu.items {
            item.isEnabled = (outlineView.item(atRow: outlineView.clickedRow) is RemoteConnection)
        }
    }

    // MARK: - Menu actions
    
    /// Open the connection represented by the clicked row.
    @objc @IBAction func openConnection(_ sender: Any) {
        
        guard let connection = outlineView.item(atRow: outlineView.clickedRow) as? RemoteConnection ?? outlineView.item(atRow: outlineView.selectedRow) as? RemoteConnection  else {
            return
        }
        
        do {
            let controller = try ConnectionController(connection: connection)
            controller.presentTerminal()
            if connection.useSFTP {
                controller.presentBrowser(atPath: connection.path)
            }
        } catch {
            NSApp.presentError(error)
        }
    }
    
    /// Edit the connection represented by the clicked row.
    @IBAction func editConnection(_ sender: Any) {
        guard let sheet = storyboard?.instantiateController(withIdentifier: "connectionInfo") as? ConnectionInfoViewController else {
            return
        }
        
        sheet.index = outlineView.clickedRow-1
        
        presentAsSheet(sheet)
    }
    
    /// Delete the connection represented by the clicked row.
    @IBAction func deleteConnection(_ sender: Any) {
        DataManager.shared.removeConnection(at: outlineView.clickedRow-1)
    }
}

