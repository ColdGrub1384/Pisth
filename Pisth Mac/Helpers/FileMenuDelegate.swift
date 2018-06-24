// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa

/// Delegate for managing the "File" menu.
class FileMenuDelegate: NSObject, NSMenuDelegate {
    
    /// Rows passed to the menu for given Outline view.
    ///
    /// - Parameters:
    ///     - outlineView: Outline view used with this menu.
    ///
    /// - Returns: Selected rows or clicked row.
    func highlightedRows(forOutlineView outlineView: NSOutlineView) -> IndexSet {
        if outlineView.clickedRow != -1 && outlineView.selectedRowIndexes.count < 2 {
            return IndexSet(integer: outlineView.clickedRow)
        } else {
            return outlineView.selectedRowIndexes
        }
    }
    
    // MARK: - Actions
    
    /// Open selected directory in new tab or a new terminal.
    @IBAction func newTab(_ sender: Any) {
        if let termVC = NSApp.keyWindow?.contentViewController as? TerminalViewController {
            do {
                let connection = termVC.controller.connection
                connection.useSFTP = false
                let controller = try ConnectionController(connection: connection)
                controller.presentTerminal()
            } catch {
                NSApp.presentError(error)
            }
        } else if let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController {
            for i in highlightedRows(forOutlineView: dirVC.outlineView) {
                dirVC.controller.presentBrowser(atPath: dirVC.directory.nsString.appendingPathComponent(dirVC.directoryContents[i].filename))
            }
        }
    }
    
    /// Show bookmarks.
    @IBAction func openBookmarks(_ sender: Any) {
        var alreadyShown = false
        for window in NSApp.windows {
            if window.contentViewController is BookmarksViewController && (window.isVisible || window.isMiniaturized) {
                window.setIsMiniaturized(false)
                window.makeKey()
                window.makeMain()
                alreadyShown = true
            }
        }
        
        if !alreadyShown {
            guard let window = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "bookmarks") as? NSWindowController else {
                return
            }
            window.showWindow(nil)
        }
    }
    
    /// Upload file.
    @IBAction func uploadFile(_ sender: Any) {
        guard let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController else {
            return
        }
        
        let picker = NSOpenPanel()
        picker.allowsMultipleSelection = true
        picker.canChooseDirectories = true
        picker.canCreateDirectories = true
        picker.allowedFileTypes = ["public.item"]
        if let window = dirVC.window {
            picker.beginSheetModal(for: window) { (_) in
                for file in picker.urls {
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    dirVC.upload(file.path, to: dirVC.directory.nsString.appendingPathComponent(file.lastPathComponent), completionHandler: { _ in
                        
                        semaphore.signal()
                    })
                    
                    semaphore.wait()
                }
            }
        }
    }
    
    /// Download selected file.
    @IBAction func downloadFile(_ sender: Any) {
        guard let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController else {
            return
        }
        
        let sftp = dirVC.controller.session.sftp
        
        for i in highlightedRows(forOutlineView: dirVC.outlineView) {
            let file = dirVC.directoryContents[i]
            
            if !file.isDirectory {
                dirVC.selectedFiles = [file]
                dirVC.openFile(showInFinder: true)
                dirVC.selectedFiles = nil
            } else if highlightedRows(forOutlineView: dirVC.outlineView).count == 1 {
                
                let alert = NSAlert()
                alert.messageText = "Downloading \(file.filename ?? "folder")..."
                alert.addButton(withTitle: "Cancel")
                
                var continue_ = true
                
                DispatchQueue.main.async {
                    if let window = dirVC.window {
                        alert.beginSheetModal(for: window, completionHandler: { (response) in
                            if response == .alertFirstButtonReturn {
                                continue_ = false
                            }
                        })
                    }
                }
                
                let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                
                struct File {
                    var sftpFile: NMSFTPFile
                    var path: String
                }
                
                func contents(of path: String) -> [File] {
                    guard let contents = sftp?.contentsOfDirectory(atPath: path) as? [NMSFTPFile] else {
                        return []
                    }
                    
                    var files = [File]()
                    for file in contents {
                        files.append(File(sftpFile: file, path: path.nsString.appendingPathComponent(file.filename)))
                    }
                    
                    return files
                }
                
                func download(file: String, to path: String) {
                    
                    guard continue_ else {
                        return
                    }
                    
                    if let data = sftp?.contents(atPath: file) {
                        if FileManager.default.fileExists(atPath: path) {
                            try? data.write(to: URL(fileURLWithPath: path))
                        } else {
                            FileManager.default.createFile(atPath: path, contents: data, attributes: [:])
                        }
                    }
                }
                
                func downloadContents(ofDirectory dir: String, to path: String) {
                    
                    guard continue_ else {
                        return
                    }
                    
                    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                    for file in contents(of: dir) {
                        if file.sftpFile.isDirectory {
                            downloadContents(ofDirectory: file.path, to: path.nsString.appendingPathComponent(file.sftpFile.filename))
                        } else {
                            download(file: file.path, to: path.nsString.appendingPathComponent(file.sftpFile.filename))
                        }
                    }
                }
                
                DispatchQueue.global(qos: .background).async {
                    downloadContents(ofDirectory: dirVC.directory.nsString.appendingPathComponent(file.filename), to: downloads.appendingPathComponent(file.filename).path)
                    
                    if (sender as? Bool) == true {
                        NSWorkspace.shared.openFile(downloads.appendingPathComponent(file.filename).path)
                    } else {
                        NSWorkspace.shared.selectFile(downloads.appendingPathComponent(file.filename).path, inFileViewerRootedAtPath: "")
                    }
                    
                    DispatchQueue.main.async {
                        alert.buttons[0].performClick(alert)
                    }
                }
            }
        }
    }
    
    /// Open selected file.
    @IBAction func openFile(_ sender: Any) {
        guard let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController else {
            return
        }
        
        for i in highlightedRows(forOutlineView: dirVC.outlineView) {
            let file = dirVC.directoryContents[i]
            
            if !file.isDirectory {
                dirVC.openFile()
            } else {
                if highlightedRows(forOutlineView: dirVC.outlineView).count == 1 {
                    dirVC.go(to: dirVC.directory.nsString.appendingPathComponent(file.filename))
                } else {
                    dirVC.controller.presentBrowser(atPath: dirVC.directory.nsString.appendingPathComponent(file.filename))
                }
            }
        }
    }
    
    /// Remove selected file.
    @IBAction func removeFile(_ sender: Any) {
        if let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController {
            for i in highlightedRows(forOutlineView: dirVC.outlineView) {
                let file = dirVC.directoryContents[i]
                
                if file.isDirectory {
                    func removeContents(of path: String) {
                        guard let contents = dirVC.controller.session.sftp!.contentsOfDirectory(atPath: path) as? [NMSFTPFile] else {
                            return
                        }
                        
                        for file in contents {
                            if file.isDirectory {
                                removeContents(of: path.nsString.appendingPathComponent(file.filename))
                                dirVC.controller.session.sftp!.removeDirectory(atPath: path.nsString.appendingPathComponent(file.filename))
                            } else {
                                dirVC.controller.session.sftp!.removeFile(atPath: path.nsString.appendingPathComponent(file.filename))
                            }
                        }
                    }
                    
                    removeContents(of: dirVC.directory.nsString.appendingPathComponent(file.filename))
                    dirVC.controller.session.sftp!.removeDirectory(atPath: dirVC.directory.nsString.appendingPathComponent(file.filename))
                } else {
                    dirVC.controller.session.sftp!.removeFile(atPath: dirVC.directory.nsString.appendingPathComponent(file.filename))
                }
                
                refresh(sender)
            }
        }
    }
    
    /// Refresh directory.
    @IBAction func refresh(_ sender: Any) {
        (NSApp.keyWindow?.contentViewController as? DirectoryViewController)?.go(to: (NSApp.keyWindow?.contentViewController as? DirectoryViewController)?.directory ?? "/")
    }
    
    /// Show or hide hidden files.
    @IBAction func toggleShowingHiddenFiles(_ sender: Any) {
        ConnectionController.showHiddenFiles = !ConnectionController.showHiddenFiles
        for window in NSApp.windows {
            if let dirVC = window.contentViewController as? DirectoryViewController {
                dirVC.go(to: dirVC.directory)
            }
        }
    }
    
    // MARK: - Menu delegate
    
    /// Enable or disable items.
    func menuWillOpen(_ menu: NSMenu) {
        guard let dirVC = NSApp.keyWindow?.contentViewController as? DirectoryViewController else {
            for item in menu.items {
                if item.title != "New Tab" {
                    item.isEnabled = false
                } else {
                    item.isEnabled = (NSApp.keyWindow?.contentViewController is TerminalViewController)
                }
            }
            return
        }
        
        for item in menu.items {
            if item.title == "Remove" || item.title == "Download" || item.title == "Open" {
                item.isEnabled = (highlightedRows(forOutlineView: dirVC.outlineView).count > 0)
            } else if item.title == "New Tab" || item.title == "New Window" {
                item.isEnabled = true
                for row in highlightedRows(forOutlineView: dirVC.outlineView) {
                    if !dirVC.directoryContents[row].isDirectory {
                        item.isEnabled = false
                    }
                }
            } else {
                item.isEnabled = true
            }
            
            if item.title == "Show hidden files" {
                if ConnectionController.showHiddenFiles {
                    item.state = .on
                } else {
                    item.state = .off
                }
            }
        }
    }
}
