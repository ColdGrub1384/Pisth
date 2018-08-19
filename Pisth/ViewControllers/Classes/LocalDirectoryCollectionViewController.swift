// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Zip
import AVFoundation
import AVKit
import Pisth_Shared
import Firebase
import QuickLook

/// Collection view controller used to manage local files.
class LocalDirectoryCollectionViewController: UICollectionViewController, UIDocumentPickerDelegate, LocalDirectoryCollectionViewControllerDelegate, QLPreviewControllerDataSource, UIDocumentInteractionControllerDelegate, UICollectionViewDragDelegate {
    
    /// Directory where retrieve files.
    var directory: URL
    
    /// Fetched files.
    var files = [URL]()
    
    /// Error viewing directory.
    var error: Error?
    
    /// File to open did view appear.
    var openFile: URL?
    
    /// Delegate used.
    var delegate: LocalDirectoryCollectionViewControllerDelegate?
    
    private var headerView_: UIView?
    
    /// `collectionView` header.
    var headerView: UIView? {
        get {
            return headerView_
        }
        
        set {
            headerView_ = newValue
            for view in headerSuperview?.subviews ?? [] {
                view.removeFromSuperview()
            }
            if let view = newValue {
                (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = view.frame.size
                view.frame = headerSuperview?.frame ?? view.frame
                view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                headerSuperview?.addSubview(view)
            } else {
                (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = CGSize.zero
            }
        }
    }
    
    /// `headerView` superview.
    var headerSuperview: UIView?
    
    private var footerView_: UIView?
    
    /// `collectionView` footer.
    var footerView: UIView? {
        get {
            return footerView_
        }
        
        set {
            footerView_ = newValue
            for view in footerSuperview?.subviews ?? [] {
                view.removeFromSuperview()
            }
            if let view = newValue {
                (collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = view.frame.size
                view.frame = headerSuperview?.frame ?? view.frame
                view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                footerSuperview?.addSubview(view)
            } else {
                (collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = CGSize.zero
            }
        }
    }
    
    /// `footerView` superview.
    var footerSuperview: UIView?
    
    private var document: UIDocumentInteractionController!
    
    /// Share file with an `UIDocumentInteractionController`.
    ///
    /// - Parameters:
    ///     - sender: `sender.tag` will be used as index of file in `files` array.
    @objc func shareFile(_ sender: UIButton) {
        document = UIDocumentInteractionController(url: files[sender.tag])
        document.delegate = self
        document.presentOpenInMenu(from: sender.bounds, in: sender, animated: true)
    }
    
    /// Preview file with a `QLPreviewController`.
    ///
    /// - Parameters:
    ///     - index: Index of file in the `files` array.
    ///
    /// - Returns: `QLPreviewController` to present.
    @objc func previewFile(atIndex index: Int) -> QLPreviewController {
        let qlVC = QLPreviewController()
        qlVC.dataSource = self
        qlVC.currentPreviewItemIndex = files.index(of: files[index]) ?? 0
        
        return qlVC
    }
    
    /// Move file stored in `Pasteboard` in current directory.
    @objc func moveFile() {
        
        guard let filePath = Pasteboard.local.localFilePath else {
            
            let errorAlert = UIAlertController(title: Localizable.Browsers.errorMovingFile, message: Localizable.Browsers.noFileInPasteboard, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            
            return
        }
        
        do {
            try FileManager.default.moveItem(atPath: filePath, toPath: directory.appendingPathComponent(filePath.nsString.lastPathComponent).path)
            
            navigationController?.dismiss(animated: true, completion: {
                if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? LocalDirectoryCollectionViewController {
                    dirVC.reload()
                }
            })
        } catch {
            let errorAlert = UIAlertController(title: Localizable.Browsers.errorMovingFile, message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        Pasteboard.local.localFilePath = nil
    }
    
    /// Copy file stored in `Pasteboard` in current directory.
    @objc func copyFile() {
        
        guard let filePath = Pasteboard.local.localFilePath else {
            
            let errorAlert = UIAlertController(title: Localizable.Browsers.errorCopyingFile, message: Localizable.Browsers.noFileInPasteboard, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            
            return
        }
        
        do {
            try FileManager.default.copyItem(atPath: filePath, toPath: directory.appendingPathComponent(filePath.nsString.lastPathComponent).path)
            
            navigationController?.dismiss(animated: true, completion: {
                if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? LocalDirectoryCollectionViewController {
                    dirVC.reload()
                }
            })
        } catch {
            let errorAlert = UIAlertController(title: Localizable.Browsers.errorCopyingFile, message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        Pasteboard.local.localFilePath = nil
    }
    
    /// Dismiss `navigationController`.
    @objc func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    /// Create or import file or directory.
    ///
    /// - Parameters:
    ///     - sender: Sender Bar button item.
    @objc func create(_ sender: UIBarButtonItem) {
        let chooseAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.Browsers.import, style: .default, handler: { (_) in // Upload file from browser
            let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            picker.allowsMultipleSelection = true
            picker.delegate = self
            
            self.present(picker, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.Browsers.createTitle, style: .default, handler: { (_) in // Create file
            
            let chooseName = UIAlertController(title: Localizable.Browsers.createTitle, message: Localizable.Browsers.createMessage, preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.FileCollectionViewCell.newFileName
            })
            chooseName.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
                
                guard let filename = chooseName.textFields?[0].text else {
                    return
                }
                
                if FileManager.default.createFile(atPath: self.directory.appendingPathComponent(filename).path, contents: nil, attributes: nil) {
                    self.reload()
                } else {
                    let errorAlert = UIAlertController(title: Localizable.Browsers.errorCreatingFile, message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            self.present(chooseName, animated: true, completion: nil)
            
        }))
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.Browsers.createFolder, style: .default, handler: { (_) in // Create folder
            let chooseName = UIAlertController(title: Localizable.Browsers.createFolder, message: Localizable.Browsers.chooseNewFolderName, preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.Browsers.folderName
            })
            chooseName.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
                
                guard let dirname = chooseName.textFields?[0].text else {
                    return
                }
                
                do {
                    try FileManager.default.createDirectory(atPath: self.directory.appendingPathComponent(dirname).path, withIntermediateDirectories: true, attributes: nil)
                    self.reload()
                } catch {
                    let errorAlert = UIAlertController(title: Localizable.Browsers.errorCreatingDirectory, message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }))
        
        if self is PluginsLocalDirectoryCollectionViewController {
            chooseAlert.addAction(UIAlertAction(title: Localizable.LocalDirectoryCollectionViewController.createTerminalPlugin, style: .default, handler: { (_) in // Create plugin
                let chooseName = UIAlertController(title: Localizable.LocalDirectoryCollectionViewController.createPluginTitle, message: Localizable.LocalDirectoryCollectionViewController.createPluginMessage, preferredStyle: .alert)
                chooseName.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = Localizable.LocalDirectoryCollectionViewController.createPluginPlaceholder
                })
                chooseName.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                chooseName.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
                    
                    guard let dirname = chooseName.textFields?[0].text else {
                        return
                    }
                    
                    do {
                        try FileManager.default.createDirectory(atPath: self.directory.appendingPathComponent(dirname+".termplugin").path, withIntermediateDirectories: true, attributes: nil)
                        if !FileManager.default.createFile(atPath: self.directory.appendingPathComponent(dirname+".termplugin").appendingPathComponent("index.js").path, contents: """
                            /* Write here JavaScript code to execute after loading the terminal.

                               - Use the `term` variable to modify the terminal. See more at https://xtermjs.org/docs/api/terminal/.
                               - Call `alert("bell")` to vibrate device.
                               - Call `alert("changeTitle<New title>")` to change the terminal title. NOTE: If it doesn't work, it's because the title was changed before by the shell, so don't call it at begining.
                               - Call `send("<Text>")` to write to the terminal.
                               - You can put resources in the plugin folder, access with the `bundlePath` constant: `bundlePath+"/<File name>"`.

                               # Options

                               `term` supports options, set them like: `term.setOption("<Option name>", <value>)`.

                                - 'bellStyle': "visual" || "sound" || "both" || "none"
                                - 'cursorStyle': "block" || "underline" || "bar"
                                - 'lineHeight': Number
                                - 'tabStopWidth': Number
                                - 'theme': {foreground: String, background: String, cursor: String, selection: String, black: String, red: String, green: String, yellow: String, blue: String, magenta: String, cyan: String, white: String, brightBlack: String, brightRed: String, brightGreen: String, brightYellow: String, brightBlue: String, brightMagenta: String, brightCyan: String, brightWhite: String} (All properties are optional)
                                - 'fontFamily': String
                                - 'fontSize': Number
                                - 'scrollBack': Number
                                - 'enableBold': Boolean
                                - 'letterSpacing': Number
                                - 'lineHeight': Number
                                - 'fontWeight': Number
                                - 'fontWeightBold': Number
                                - 'screenReaderModer': Bolean
                                - 'tabStopWidth': Number
                                - 'allowTransparency': Boolean
                                - 'cancelEvents': Boolean
                                - 'cols': Number
                                - 'rows': Number
                                - 'convertsEol': Boolean
                                - 'cursorBlink': Boolean
                                - 'debug': Boolean
                                - 'disableStdin': Boolean
                                - 'macOptionIsMeta': Boolean
                                - 'rightClickSelectsWord': Boolean
                                - 'screenKeys': Boolean
                                - 'termName': String
                                - 'useFlowControl': Boolean
                            */
                            
                            /// Path of the plugin.
                            const bundlePath = document.currentScript.bundlePath;
                            
                            """.data(using: .utf8), attributes: nil) {
                            
                            let errorAlert = UIAlertController(title: Localizable.LocalDirectoryCollectionViewController.errorCreatingPluginTitle, message: Localizable.LocalDirectoryCollectionViewController.errorCreatingPluginMessage, preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                            self.present(errorAlert, animated: true, completion: nil)
                            
                        }
                        self.reload()
                    } catch {
                        let errorAlert = UIAlertController(title: Localizable.LocalDirectoryCollectionViewController.errorCreatingPluginTitle, message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                }))
                
                self.present(chooseName, animated: true, completion: nil)
            }))
        }
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
        
        chooseAlert.popoverPresentationController?.barButtonItem = sender
        
        self.present(chooseAlert, animated: true, completion: nil)
    }
    
    /// Reload content of directory.
    @objc func reload() {
        files = []
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            for file in files {
                self.files.append(directory.appendingPathComponent(file))
            }
            
            collectionView?.reloadData()
        } catch {}
        
        collectionView?.refreshControl?.endRefreshing()
    }
    
    /// Set layout selected by the user.
    func loadLayout() {
        var layout: UICollectionViewFlowLayout
        if UserDefaults.standard.bool(forKey: "list") {
            layout = LocalDirectoryCollectionViewController.listLayout(forView: view)
        } else {
            layout = LocalDirectoryCollectionViewController.gridLayout
        }
        if let currentLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = currentLayout.footerReferenceSize
            layout.headerReferenceSize = currentLayout.headerReferenceSize
        }
        collectionView?.reloadData()
        collectionView?.setCollectionViewLayout(layout, animated: false)
    }
    
    /// Init with given directory.
    /// - Parameters:
    ///     - directory: Directory to open.
    ///
    /// - Returns: A Table view controller listing files in given directory.
    init(directory: URL) {
        
        self.directory = directory
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            for file in files {
                self.files.append(directory.appendingPathComponent(file))
            }
        } catch let error {
            self.error = error
        }
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View controller
    
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-LocalFileBrowser", AnalyticsParameterItemName : "Local File Browser"])
        
        title = directory.lastPathComponent
        
        navigationItem.largeTitleDisplayMode = .never
        
        collectionView?.register(UINib(nibName: "Grid File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileGrid")
        collectionView?.register(UINib(nibName: "List File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileList")
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
        collectionView?.backgroundColor = .white
        clearsSelectionOnViewWillAppear = false
        collectionView?.dragDelegate = self
        
        // Header
        let header = UIView.browserHeader
        headerView = header
        header.createNewFolder = { _ in // Create folder
            let chooseName = UIAlertController(title: Localizable.Browsers.createFolder, message: Localizable.Browsers.chooseNewFolderName, preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.Browsers.folderName
            })
            chooseName.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
                
                do {
                    try FileManager.default.createDirectory(at: self.directory.appendingPathComponent(chooseName.textFields![0].text!), withIntermediateDirectories: true, attributes: nil)
                } catch {
                    let errorAlert = UIAlertController(title: "Error creating directory!", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }
        header.switchLayout = { _ in // Switch layout
            self.loadLayout()
        }
        
        loadLayout()
        
        collectionView?.refreshControl = UIRefreshControl()
        collectionView?.refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        
        // Navigation bar items
        let createFile = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create(_:)))
        navigationItem.setRightBarButtonItems([createFile], animated: true)
    }
    
    /// Show error if there are or open `openFile` file.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if let error = error {
            let errorAlert = UIAlertController(title: Localizable.Browsers.errorOpeningDirectory, message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        if let openFile = openFile {
            guard let index = files.index(of: openFile) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            
            collectionView?.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            collectionView(collectionView!, didSelectItemAt: indexPath)
            
            self.openFile = nil
        }
        
        reload()
    }
    
    /// Remove observer.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Update `collectionView`'s layout.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != LocalDirectoryCollectionViewController.gridLayout.itemSize {
            layout.itemSize.width = size.width
        }
    }
    
    /// Resize layout.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != LocalDirectoryCollectionViewController.gridLayout.itemSize {
            layout.itemSize.width = view.frame.size.width
        }
    }
    
    // MARK: - Table view data source
    
    /// - Returns: `1`.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// - Returns: count of `files`.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }
    
    /// - Returns: A `UICollectionViewCell` with title as the current filename and file icon for current file.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell: FileCollectionViewCell
        if UserDefaults.standard.bool(forKey: "list") {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileList", for: indexPath) as! FileCollectionViewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileGrid", for: indexPath) as! FileCollectionViewCell
        }
        cell.localDirectoryCollectionViewController = self
         
        // Configure the cell...
         
        cell.filename.text = files[indexPath.row].lastPathComponent
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if isDir.boolValue { // Is directory
                cell.iconView.image = #imageLiteral(resourceName: "File icons/folder")
            } else { // Is file
                cell.iconView.image = UIImage.icon(forFileURL: files[indexPath.row], preferredSize: .smallest)
            }
        }
         
        return cell
    }
    
    /// - Returns: Enable copying files.
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    /// - Returns: `true`.
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Copy selected file.
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == #selector(copy(_:)) { // Copy file
            
            Pasteboard.local.localFilePath = directory.appendingPathComponent(files[indexPath.row].lastPathComponent).path
            
            let dirVC = LocalDirectoryCollectionViewController(directory: FileManager.default.documents)
            dirVC.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereCopyFile
            dirVC.delegate = dirVC
            LocalDirectoryCollectionViewController.action = .copyFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.copyHere, style: .plain, target: dirVC, action: #selector(dirVC.copyFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    /// - Returns: An header view containing `headerView`.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
            
            headerSuperview = view
            
            let header = headerView
            headerView = nil
            headerView = header
            
            return view
        } else {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
            
            footerSuperview = view
            
            let footer = footerView
            footerView = nil
            footerView = footer
            
            return view
        }
    }
    
    // MARK: - Table view delegate
    
    /// Open selected file or directory.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell else { return }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        if cell.iconView.image == #imageLiteral(resourceName: "File icons/folder") { // Open folder
            let dirVC = LocalDirectoryCollectionViewController(directory: self.files[indexPath.row])
            
            if let delegate = delegate {
                delegate.localDirectoryCollectionViewController(dirVC, didOpenDirectory: self.files[indexPath.row])
            } else {
                dirVC.delegate = delegate
                self.navigationController?.pushViewController(dirVC, animated: true)
            }
        } else {
            if let delegate = delegate { // Handle the file with delegate
                delegate.localDirectoryCollectionViewController(self, didOpenFile: self.files[indexPath.row])
            } else { // Default handler
                LocalDirectoryCollectionViewController.openFile(files[indexPath.row], from: cell.frame, in: view, navigationController: navigationController, showActivityViewControllerInside: self)
            }
        }
    }
    
    // MARK: - Banner view delegate
    
    // MARK: - Document picker delegate
    
    /// Dismiss document picker.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    /// Import selected documents.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            do {
                try FileManager.default.copyItem(atPath: url.path, toPath: directory.appendingPathComponent(url.lastPathComponent).path)
                reload()
            } catch {
                let errorAlert = UIAlertController(title: Localizable.Browsers.errorImporting, message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Local directory collection view controller
    
    /// Copy or move file.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenDirectory directory: URL) {
        localDirectoryCollectionViewController.delegate = localDirectoryCollectionViewController
        
        if LocalDirectoryCollectionViewController.action == .copyFile {
            localDirectoryCollectionViewController.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereCopyFile
        }
        
        if LocalDirectoryCollectionViewController.action == .moveFile {
            localDirectoryCollectionViewController.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereMoveFile
        }
        
        navigationController?.pushViewController(localDirectoryCollectionViewController, animated: true, completion: {
            if LocalDirectoryCollectionViewController.action == .copyFile {
                localDirectoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.copyHere, style: .plain, target: localDirectoryCollectionViewController, action: #selector(localDirectoryCollectionViewController.copyFile))], animated: true)
            }
            
            if LocalDirectoryCollectionViewController.action == .moveFile {
                localDirectoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.moveHere, style: .plain, target: localDirectoryCollectionViewController, action: #selector(localDirectoryCollectionViewController.moveFile))], animated: true)
            }
        })
        
    }
    
    /// Call defailt handler.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenFile file: URL) {
        LocalDirectoryCollectionViewController.openFile(file, from: localDirectoryCollectionViewController.collectionView!.cellForItem(at: IndexPath(row: localDirectoryCollectionViewController.files.index(of: file) ?? 0, section: 0))?.frame ?? CGRect.zero, in: localDirectoryCollectionViewController.view, navigationController: navigationController, showActivityViewControllerInside: localDirectoryCollectionViewController)
    }
    
    // MARK: - Preview controller data source
    
    /// - Returns: count of `files.`
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return files.count
    }
    
    /// - Returns: file in `files` at current index.
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return files[index] as QLPreviewItem
    }
    
    // MARK: - Document interaction controller delegate
    
    /// - Returns: `self`.
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    // MARK: - Collection view drag delegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let file = files[indexPath.row]
        
        let item = UIDragItem(itemProvider: NSItemProvider(item: file as NSSecureCoding, typeIdentifier: "public.item"))
        item.sourceViewController = self
        item.previewProvider = {
            
            guard let iconView = (collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell)?.iconView else {
                return nil
            }
            
            let dragPreview = UIDragPreview(view: iconView)
            dragPreview.parameters.backgroundColor = .clear
            
            return dragPreview
        }
        
        return [item]
    }
    
    // MARK: - Static
    
    /// Grid layout.
    static var gridLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 120)
        return layout
    }
    
    /// List layout.
    static func listLayout(forView view: UIView) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width, height: 50)
        return layout
    }
    
    /// Global delegate.
    static var delegate: LocalDirectoryCollectionViewControllerStaticDelegate?
    
    /// Action to do.
    static var action = DirectoryAction.none
    
    /// Edit, view or share given file.
    ///
    /// - Parameters:
    ///     - file: File to be opened.
    ///     - wasJustDownloaded: If `true`, will show the file in the browser.
    ///     - frame: Frame where point an `UIActivityController` if the file will be saved.
    ///     - view: View from wich share the file.
    ///     - navigationController: Navigation controller in wich push editor or viewer.
    ///     - viewController: viewController in wich show loading alert.
    static func openFile(_ file: URL, wasJustDownloaded: Bool = false, from frame: CGRect, `in` view: UIView, navigationController: UINavigationController?, showActivityViewControllerInside viewController: UIViewController?) {
        
        if let delegate = delegate {
            guard let data = try? Data(contentsOf: file) else {
                return
            }
            delegate.didOpenFile(file, withData: data)
            return
        }
        
        func openFile() {
            
            guard let vc = viewController ?? navigationController ?? UIApplication.shared.keyWindow?.rootViewController else {
                return
            }
            
            if let _ = try? String.init(contentsOfFile: file.path) { // Is text
                var editTextVC: EditTextViewController! {
                    let editTextViewController = UIViewController.codeEditor
                    
                    editTextViewController.file = file
                    
                    return editTextViewController
                }
                
                if file.pathExtension.lowercased() == "html" || file.pathExtension.lowercased() == "htm" { // Ask for view HTML or edit
                    let alert = UIAlertController(title: Localizable.LocalDirectoryCollectionViewController.openFileTitle, message: Localizable.LocalDirectoryCollectionViewController.openFileMessage, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Localizable.LocalDirectoryCollectionViewController.viewHTML, style: .default, handler: { (_) in // View HTML
                        let webVC = UIViewController.webViewController
                        webVC.file = file
                        
                        vc.present(UINavigationController(rootViewController: webVC), animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: Localizable.LocalDirectoryCollectionViewController.editHTML, style: .default, handler: { (_) in // Edit HTML
                        vc.present(UINavigationController(rootViewController: editTextVC), animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    
                    if viewController == nil {
                        vc.present(alert, animated: true, completion: nil)
                    } else {
                        vc.dismiss(animated: true, completion: {
                            navigationController?.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    if viewController == nil {
                        vc.present(UINavigationController(rootViewController: editTextVC), animated: true, completion: nil)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            vc.present(UINavigationController(rootViewController: editTextVC), animated: true, completion: nil)
                        })
                    }
                }
            } else if wasJustDownloaded {
                let dirVC = LocalDirectoryCollectionViewController(directory: file.deletingLastPathComponent())
                
                guard let i = dirVC.files.firstIndex(of: file) else {
                    return
                }
                
                func show() {
                    AppDelegate.shared.navigationController.pushViewController(dirVC, animated: true) {
                        dirVC.collectionView?.selectItem(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .centeredHorizontally)
                        
                        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
                            dirVC.collectionView?.deselectItem(at: IndexPath(row: i, section: 0), animated: true)
                        })
                    }
                }
                
                if viewController == nil {
                    show()
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        show()
                    })
                }
                
                return
            }
            
            if isFilePDF(file) {
                let webVC = UIViewController.webViewController
                webVC.file = file
                
                if viewController == nil {
                    vc.present(UINavigationController(rootViewController: webVC), animated: true, completion: nil)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        vc.present(UINavigationController(rootViewController: webVC), animated: true, completion: nil)
                    })
                }
            } else if let unziped = try? Zip.quickUnzipFile(file) {
                let newFolderVC = LocalDirectoryCollectionViewController(directory: unziped)
                if viewController == nil {
                    navigationController?.pushViewController(newFolderVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(newFolderVC, animated: true)
                    })
                }
            } else if AVAsset(url: file).isPlayable { // Is video or audio
                let player = AVPlayer(url: file)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                
                if viewController == nil {
                    vc.present(UINavigationController(rootViewController: playerVC), animated: true, completion: nil)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        vc.present(UINavigationController(rootViewController: playerVC), animated: true, completion: nil)
                    })
                }
            } else if let image = UIImage(contentsOfFile: file.path) { // Image
                let imageViewer = UIViewController.imageViewer
                imageViewer.image = image
                if viewController == nil {
                    vc.present(UINavigationController(rootViewController: imageViewer), animated: true, completion: nil)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        vc.present(UINavigationController(rootViewController: imageViewer), animated: true, completion: nil)
                    })
                }
            } else {
                let dirVC = LocalDirectoryCollectionViewController(directory: file.deletingLastPathComponent())
                if let i = dirVC.files.firstIndex(of: file) {
                    if viewController == nil {
                        vc.present(dirVC.previewFile(atIndex: i), animated: true, completion: nil)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            vc.present(dirVC.previewFile(atIndex: i), animated: true, completion: nil)
                        })
                    }
                }
            }
        }
        
        let activityVC = ActivityViewController(message: Localizable.loading)
        if let viewController = viewController {
            viewController.present(activityVC, animated: true, completion: {
                openFile()
            })
        } else {
            openFile()
        }
    }
}


