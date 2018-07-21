// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information


import UIKit

/// Local directory table view controller for managing terminal plugins.
class PluginsLocalDirectoryCollectionViewController: LocalDirectoryCollectionViewController {
    
    /// Not supported.
    @available(*, unavailable, message:"PluginsLocalDirectoryCollectionViewController cannot init from given directory, it init from default plugins directory.")
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
    
    /// Disable files that are not plugins.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if !isDir.boolValue || files[indexPath.row].pathExtension.lowercased() != "termplugin" {
                (cell as? FileCollectionViewCell)?.iconView.alpha = 0.5
                (cell as? FileCollectionViewCell)?.filename.alpha = 0.5
                (cell as? FileCollectionViewCell)?.more?.alpha = 0.5
            } else {
                (cell as? FileCollectionViewCell)?.iconView.alpha = 1
                (cell as? FileCollectionViewCell)?.filename.alpha = 1
                (cell as? FileCollectionViewCell)?.more?.alpha = 1
            }
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// Do nothing if the selected file is not a plugin.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if isDir.boolValue && files[indexPath.row].pathExtension.lowercased() == "termplugin" {
                super.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
}
