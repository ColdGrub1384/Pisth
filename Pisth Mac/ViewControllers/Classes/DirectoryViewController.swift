// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa

/// A View controller showing the content of a remote directory.
class DirectoryViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    
    /// Directory to show. Default value is `"/"`.
    var directory = "/"
    
    /// Local path were files will be downloaded.
    var localPath: String?
    
    /// The contents of the directory set in `viewDidAppear`.
    var directoryContents = [NMSFTPFile]()
    
    /// The `ConnectionController` that controls the connection for this directory.
    var controller: ConnectionController!
    
    /// The root window for this View controller.
    var window: NSWindow?
    
    /// Go to the parent directory.
    @objc func goBack() {
        go(to: directory.nsString.deletingLastPathComponent)
    }
    
    /// The `outlineView` showing the directory content.
    @IBOutlet weak var outlineView: NSOutlineView!
    
    /// Upload local file to given path.
    ///
    /// - Parameters:
    ///     - file: Local file to upload.
    ///     - path: Remote path.
    func upload(_ file: String, to path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            if !self.controller.session.sftp!.writeContents(data, toFileAtPath: path) {
                DispatchQueue.main.async {
                    NSApp.presentError(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey:"Cannot upload file."]))
                }
            } else {
                let success = NSUserNotification()
                success.title = "Upload finished!"
                success.subtitle = path
                NSUserNotificationCenter.default.deliver(success)
            }
        }
    }
    
    /// Open clicked file or directory.
    @objc func openFile() {
        guard let file = outlineView.item(atRow: outlineView.clickedRow) as? NMSFTPFile else {
            return
        }
        
        if file.isDirectory { // Open directory
            go(to: directory.nsString.appendingPathComponent(file.filename))
        } else { // Download file
            
            guard let localPath = localPath else {
                return
            }
            
            let alert = NSAlert()
            alert.messageText = "Downloading \(file.filename!)..."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Cancel")
            
            var continueDownload = true
            
            DispatchQueue.global(qos: .background).async {
                let data = self.controller.session.sftp!.contents(atPath: self.directory.nsString.appendingPathComponent(file.filename), progress: { (downloaded, total) -> Bool in
                    let downloadedFormatted = ByteCountFormatter().string(fromByteCount: Int64(downloaded))
                    let totalFormatted = ByteCountFormatter().string(fromByteCount: Int64(total))
                    
                    DispatchQueue.main.async {
                        alert.informativeText = "\(downloadedFormatted) / \(totalFormatted)"
                    }
                    
                    return continueDownload
                })
                
                guard continueDownload else {
                    return
                }
                
                DispatchQueue.main.async {
                    alert.buttons[0].performClick(alert)
                    
                    do { // Open file
                        let filePath = localPath.nsString.appendingPathComponent(file.filename)
                        
                        if FileManager.default.fileExists(atPath: filePath) {
                            try FileManager.default.removeItem(atPath: filePath)
                        }
                        
                        if !FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil) {
                            NSApp.presentError(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey:"Error creating file!"]))
                            return
                        }
                        
                        try? FileObserver(file: URL(fileURLWithPath: filePath)).start { // Upload file
                            DispatchQueue.main.async {
                                self.upload(filePath, to: self.directory.nsString.appendingPathComponent(file.filename))
                            }
                        }
                        
                        NSWorkspace.shared.openFile(filePath)
                    } catch {
                        NSApp.presentError(error)
                    }
                }
            }
            
            if alert.runModal() == .alertFirstButtonReturn {
                continueDownload = false
            }
        }
    }
    
    /// Go to the given directory.
    ///
    /// - Parameters:
    ///     - directory: Directory's full path.
    func go(to directory: String) {
        self.directory = directory
        directoryContents = (controller.session.sftp.contentsOfDirectory(atPath: directory) as? [NMSFTPFile]) ?? []
        outlineView.reloadData()
        
        localPath = NSTemporaryDirectory().nsString.appendingPathComponent(directory)
        try? FileManager.default.createDirectory(atPath: localPath!, withIntermediateDirectories: true, attributes: nil)
        window?.setTitleWithRepresentedFilename(localPath!)
        
        for toolbarItem in window?.toolbar?.items ?? [] {
            if toolbarItem.itemIdentifier.rawValue == "path" {
                (toolbarItem.view as? NSTextField)?.stringValue = directory
            } else if toolbarItem.itemIdentifier.rawValue == "goBack" {
                toolbarItem.isEnabled = (directory != "/")
            }
        }
    }
    
    // MARK: - View controller
    
    /// Go to typed directory.
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            self.go(to: fieldEditor.string)
        })
        return true
    }
    
    /// Fetch files and setup `outlineView`.
    override func viewDidAppear() {
        super.viewDidAppear()
        
        outlineView.doubleAction = #selector(openFile)
        
        directoryContents = (controller.session.sftp.contentsOfDirectory(atPath: directory) as? [NMSFTPFile]) ?? []
        outlineView.reloadData()
    }
    
    // MARK: - Outline view data source
    
    /// - Returns: The file for given index.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return directoryContents[index]
    }
    
    /// - Returns: `false`.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    /// - Returns: The count of `directoryContents`.
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return directoryContents.count
    }
    
    /// - Returns: `65`.
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 65
    }
    
    // MARK: - Outline view delegate
    
    /// Setup view.
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if let file = item as? NMSFTPFile {
            guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) else {
                return nil
            }
            
            if file.filename.hasPrefix(".") {
                cell.alphaValue = 0.5
            } else {
                cell.alphaValue = 1
            }
            
            let fileIcon = NSWorkspace.shared.icon(forFileType: file.filename.nsString.pathExtension)
            let blankFileIcon = NSWorkspace.shared.icon(forFileType: "")
            if file.isDirectory && fileIcon == blankFileIcon {
                (cell.viewWithTag(1) as? NSImageView)?.image = NSImage(named: NSImage.folderName)
            } else {
                (cell.viewWithTag(1) as? NSImageView)?.image = fileIcon
            }
            (cell.viewWithTag(2) as? NSTextField)?.stringValue = file.filename
            (cell.viewWithTag(3) as? NSTextField)?.stringValue = file.permissions
            
            return cell
        }
        
        return nil
    }
}
