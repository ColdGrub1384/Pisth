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
    
    /// - Returns: The sender's operation.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask
    }
    
    /// - Returns: The sender's operation.
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask
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
        }
        
        if let paths = sender.draggingPasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [NSString] {
            for path in paths {
                dirVC.controller.session.sftp.moveItem(atPath: path as String, toPath: dirVC.directory.nsString.appendingPathComponent(path.lastPathComponent))
                
                dirVC.go(to: dirVC.directory)
                
                if let sourceDirVC = (sender.draggingSource as? NSOutlineView)?.window?.contentViewController as? DirectoryViewController {
                    sourceDirVC.go(to: sourceDirVC.directory)
                }
            }
            return true
        }
        
        return false
    }
}
