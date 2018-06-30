// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa

/// A View controller showing the content of a remote directory.
class DirectoryViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate, NSDraggingDestination {
    
    /// Directory to show. Default value is `"/"`.
    var directory = "/"
    
    /// Local path were files will be downloaded.
    var localPath: String?
    
    private var directoryContents_ = [NMSFTPFile]()
    
    /// Selected or clicked rows in `outlineView`.
    var highlightedRows: IndexSet {
        if outlineView.clickedRow != -1 {
            return IndexSet(integer: outlineView.clickedRow)
        } else {
            return outlineView.selectedRowIndexes
        }
    }
    
    /// The contents of the directory set in `viewDidAppear` excluding hidden files if `ConnectionController.showHiddenFiles` is `false`.
    var directoryContents: [NMSFTPFile] {
        set {
            directoryContents_ = newValue
        }
        
        get {
            if ConnectionController.showHiddenFiles {
                return directoryContents_
            } else {
                var contents = directoryContents_
                var i = 0
                for file in contents {
                    if file.filename.hasPrefix(".") {
                        contents.remove(at: i)
                    } else {
                        i += 1
                    }
                }
                
                return contents
            }
        }
    }
    
    /// The `ConnectionController` that controls the connection for this directory.
    var controller: ConnectionController!
    
    /// The root window for this View controller.
    var window: NSWindow?
    
    /// Go to the parent directory.
    @objc func goBack() {
        go(to: directory.nsString.deletingLastPathComponent)
    }
    
    /// The `outlineView` showing the directory content.
    @IBOutlet weak var outlineView: FilesOutlineView!

    /// Sidebar.
    @IBOutlet weak var sidebar: BrowserSidebarOutlineView!
    
    /// Upload local file to given path.
    ///
    /// - Parameters:
    ///     - file: Local file to upload.
    ///     - path: Remote path.
    ///     - completionHandler: Code to execute after uploading file. The passed parameter if a `Bool` indicating if the file was uploaded. This block is executed in a background thread.
    func upload(_ file: String, to path: String, completionHandler: ((Bool) -> Void)? = nil) {
        
        let alert = NSAlert()
        alert.messageText = "Uploading \(file.nsString.lastPathComponent)..."
        
        func dismissAlert() {
            alert.buttons[0].performClick(alert)
        }
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) && isDir.boolValue {
            
            var success = true
            var continue_ = true
            
            DispatchQueue.main.async {
                alert.addButton(withTitle: "Cancel")
                if let window = self.window {
                    alert.beginSheetModal(for: window, completionHandler: { response in
                        if response == .alertFirstButtonReturn {
                            continue_ = false
                        }
                    })
                }
            }
            
            func isItemDirectory(_ item: URL) -> Bool {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
                    return isDir.boolValue
                } else {
                    return false
                }
            }
            
            func filesIn(directory: URL) -> [URL] {
                return (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            }
            
            var uploaded = 0
            var size = 0
            func countFiles(inside directory: URL) {
                for file in filesIn(directory: directory) {
                    size += 1
                    if isItemDirectory(file) {
                        countFiles(inside: file)
                    }
                }
            }
            countFiles(inside: URL(fileURLWithPath: file))
            
            func uploadFilesInDirectory(_ directory: URL, toPath path: String) {
                
                guard continue_ else {
                    return
                }
                
                for url in filesIn(directory: directory) {
                    
                    if isItemDirectory(url) {
                        success = controller.session.sftp!.createDirectory(atPath: path.nsString.appendingPathComponent(url.lastPathComponent))
                        if success {
                            uploaded += 1
                        }
                        uploadFilesInDirectory(url, toPath: path.nsString.appendingPathComponent(url.lastPathComponent))
                    } else {
                        if let data = try? Data(contentsOf: url) {
                            success = controller.session.sftp!.writeContents(data, toFileAtPath: path.nsString.appendingPathComponent(url.lastPathComponent), progress: { (_) -> Bool in
                                return continue_
                            })
                            if success {
                                uploaded += 1
                            }
                        }
                    }
                }
            }
            
            var finished = false
            
            controller.session.sftp!.createDirectory(atPath: path)
            
            DispatchQueue.global(qos: .background).async {
                uploadFilesInDirectory(URL(fileURLWithPath: file), toPath: self.directory.nsString.appendingPathComponent(file.nsString.lastPathComponent))
                finished = true
                DispatchQueue.main.async {
                    self.go(to: self.directory)
                }
            }
            
            completionHandler?(success)
            
            if success {
                let success = NSUserNotification()
                success.title = "Upload finished!"
                success.subtitle = path
                NSUserNotificationCenter.default.deliver(success)
            } else {
                let success = NSUserNotification()
                success.title = "Upload failed!"
                success.subtitle = path
                NSUserNotificationCenter.default.deliver(success)
            }
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                if finished {
                    dismissAlert()
                    timer.invalidate()
                } else {
                    alert.informativeText = "\(uploaded) / \(size) items"
                }
            })
            
            return
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return
        }
        
        var continue_ = true
        
        DispatchQueue.main.async {
            alert.addButton(withTitle: "Cancel")
            if let window = self.window {
                alert.beginSheetModal(for: window, completionHandler: { response in
                    if response == .alertFirstButtonReturn {
                        continue_ = false
                    }
                })
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            
            if !self.controller.session.sftp!.writeContents(data, toFileAtPath: path, progress: { (written) -> Bool in
                let writtenFormatted = ByteCountFormatter().string(fromByteCount: Int64(written))
                let totalFormatted = ByteCountFormatter().string(fromByteCount: Int64(data.count))
                
                DispatchQueue.main.async {
                    alert.informativeText = "\(writtenFormatted) / \(totalFormatted)"
                }
                return continue_
            }) {
                DispatchQueue.main.async {
                    dismissAlert()
                    NSApp.presentError(NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey:"Cannot upload file."]))
                }
                completionHandler?(false)
            } else {
                DispatchQueue.main.async {
                    self.go(to: self.directory)
                    dismissAlert()
                }
                let success = NSUserNotification()
                success.title = "Upload finished!"
                success.subtitle = path
                NSUserNotificationCenter.default.deliver(success)
                completionHandler?(true)
            }
        }
    }
    
    /// Custom selected files to open with `openFile(showInFinder:)`.
    var selectedFiles: [NMSFTPFile]?
    
    @objc private func openFile_() {
        openFile()
    }
    
    /// Open selected files.
    ///
    /// - Parameters:
    ///     - showInFinder: Show file in Finder.
    @objc func openFile(showInFinder: Bool = false) {
        
        var files = [NMSFTPFile]()
        if let files_ = selectedFiles {
            files = files_
        } else {
            for i in highlightedRows {
                files.append(directoryContents[i])
            }
        }
        
        for file in files {
            if file.isDirectory { // Open directory
                if files.count == 1 {
                    go(to: directory.nsString.appendingPathComponent(file.filename))
                } else {
                    controller.presentBrowser(atPath: directory.nsString.appendingPathComponent(file.filename))
                }
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
                            
                            if !showInFinder { // Open file
                                try? FileObserver(file: URL(fileURLWithPath: filePath)).start { // Upload file
                                    DispatchQueue.main.async {
                                        self.upload(filePath, to: self.directory.nsString.appendingPathComponent(file.filename))
                                    }
                                }
                                
                                NSWorkspace.shared.openFile(filePath)
                            } else { // Show file in Finder
                                do {
                                    let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                                    try FileManager.default.moveItem(at: URL(fileURLWithPath: filePath), to: downloads.appendingPathComponent(filePath.nsString.lastPathComponent))
                                    NSWorkspace.shared.selectFile(downloads.appendingPathComponent(filePath.nsString.lastPathComponent).path, inFileViewerRootedAtPath: "")
                                } catch {
                                    NSApp.presentError(error)
                                }
                            }
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
    }
    
    /// Refresh the contents of directory.
    @objc func refresh() {
        go(to: directory)
    }
    
    /// Go to the given directory.
    ///
    /// - Parameters:
    ///     - directory: Directory's full path.
    func go(to directory: String) {
        window?.tab.title = "\(controller.session.username!)@\(controller.session.host!) - \(directory.nsString.lastPathComponent)"
        window?.tab.toolTip = directory
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
        
        var items = [BrowserSidebarOutlineView.Item]()
        var path = "/"
        for component in directory.nsString.pathComponents {
            path = path.nsString.appendingPathComponent(component)
            items.append(.init(title: component, value: path))
        }
        
        var containsSelf = false
        for item in sidebar.items {
            if item.value.removingUnnecessariesSlashes == directory.removingUnnecessariesSlashes {
                containsSelf = true
            }
        }
        if sidebar.items.count < items.count || !containsSelf {
            sidebar.items = items.reversed()
            sidebar.reloadData()
            sidebar.ignoreSelection = true
            sidebar.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
        
        self.directory = directory
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
        
        outlineView.menu = (NSApp.delegate as? AppDelegate)?.fileMenu
                
        window?.registerForDraggedTypes([.fileURL, .fileContents])
        
        outlineView.directoryViewController = self
        outlineView.doubleAction = #selector(openFile_)
        outlineView.registerForDraggedTypes([.fileURL, .string])
        
        go(to: directory)
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
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        return .move
    }
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        if let file = item as? NMSFTPFile {
            return directory.nsString.appendingPathComponent(file.filename) as NSPasteboardWriting
        }
        return nil
    }
    
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
    
    // MARK: - Dragging destination
    
    /// - Returns: `.copy`.
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    /// Upload files.
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        let dirVC = self
        
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                let alert = NSAlert()
                alert.messageText = "Uploading \(url.lastPathComponent)..."
                
                dirVC.upload(url.path, to: dirVC.directory.nsString.appendingPathComponent(url.lastPathComponent), completionHandler: { success in
                    DispatchQueue.main.async {
                        alert.buttons[0].performClick(alert)
                    }
                })
                
                alert.runModal()
            }
            return true
        }
        return false
    }
}
