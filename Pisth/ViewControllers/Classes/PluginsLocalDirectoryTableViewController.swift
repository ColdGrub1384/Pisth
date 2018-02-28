// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information


import UIKit

/// Local directory table view controller for managing terminal plugins.
class PluginsLocalDirectoryTableViewController: LocalDirectoryTableViewController {
    
    /// `PluginsLocalDirectoryTableViewController`'s `init(directory:)` function.
    ///
    /// Not supported.
    @available(*, unavailable, message:"PluginsLocalDirectoryTableViewController cannot init from given directory, it init from default plugins directory.")
    override init(directory: URL) {
        super.init(directory: directory)
    }
    
    /// Init from plugins directory.
    init() {
        super.init(directory: FileManager.default.library.appendingPathComponent("Plugins"))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Table view data source
    
    /// `LocalDirectoryTableViewController`'s `tableView(_:, cellForRowAt:)` function.
    ///
    /// Disable files that are not plugins.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if !isDir.boolValue || files[indexPath.row].pathExtension.lowercased() != "termplugin" {
                (cell as? FileTableViewCell)?.iconView.alpha = 0.5
                (cell as? FileTableViewCell)?.filename.alpha = 0.5
            }
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// `LocalDirectoryTableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// Do nothing if the selected file is not a plugin.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if isDir.boolValue && files[indexPath.row].pathExtension.lowercased() == "termplugin" {
                super.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
