//
//  FilesOutlineView.swift
//  Pisth Mac
//
//  Created by Adrian Labbe on 6/17/18.
//  Copyright © 2018 ADA. All rights reserved.
//

import Cocoa

/// An `NSOutlineView` showing remote files.
class FilesOutlineView: NSOutlineView {
    
    /// The `DirectoryViewController` using this view.
    var directoryViewController: DirectoryViewController?
    
    // MARK: - Dragging destination
    
    /// - Returns: `.copy`.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        
    }
    
    /// Upload files.
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        guard let dirVC = directoryViewController else {
            return false
        }
        
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                dirVC.upload(url.path, to: dirVC.directory.nsString.appendingPathComponent(url.lastPathComponent))
            }
            return true
        }
        return false
    }
}
