// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Zip
import GoogleMobileAds
import AVFoundation
import AVKit
import Pisth_Shared
import Firebase
import QuickLook

/// Table view controller used to manage local files.
class LocalDirectoryTableViewController: UITableViewController, GADBannerViewDelegate, UIDocumentPickerDelegate, LocalDirectoryTableViewControllerDelegate, QLPreviewControllerDataSource {
    
    /// Directory where retrieve files.
    var directory: URL
    
    /// Fetched files.
    var files = [URL]()
    
    /// Error viewing directory.
    var error: Error?
    
    /// File to open did view appear.
    var openFile: URL?
    
    /// Delegate used.
    var delegate: LocalDirectoryTableViewControllerDelegate?
    
    /// Ad banner view displayed as header of Table view.
    var bannerView: GADBannerView!
    
    /// Share file with an `UIActivityViewController`.
    ///
    /// - Parameters:
    ///     - sender: Button that sends the action, where point the `UIActivityViewController` and in wich the `tag` will be used as index of file in `files` array.
    @objc func shareFile(_ sender: UIButton) {
        let shareVC = UIActivityViewController(activityItems: [files[sender.tag]], applicationActivities: nil)
        shareVC.popoverPresentationController?.sourceView = sender
        present(shareVC, animated: true, completion: nil)
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
            
            let errorAlert = UIAlertController(title: "Error moving file!", message: "No file in pasteboard.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            
            return
        }
        
        do {
            try FileManager.default.moveItem(atPath: filePath, toPath: directory.appendingPathComponent(filePath.nsString.lastPathComponent).path)
            
            navigationController?.dismiss(animated: true, completion: {
                if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? LocalDirectoryTableViewController {
                    dirVC.reload()
                }
            })
        } catch {
            let errorAlert = UIAlertController(title: "Error moving file!", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        Pasteboard.local.localFilePath = nil
    }
    
    /// Copy file stored in `Pasteboard` in current directory.
    @objc func copyFile() {
        
        guard let filePath = Pasteboard.local.localFilePath else {
            
            let errorAlert = UIAlertController(title: "Error copying file!", message: "No file in pasteboard.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            
            return
        }
        
        do {
            try FileManager.default.copyItem(atPath: filePath, toPath: directory.appendingPathComponent(filePath.nsString.lastPathComponent).path)
            
            navigationController?.dismiss(animated: true, completion: {
                if let dirVC = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? LocalDirectoryTableViewController {
                    dirVC.reload()
                }
            })
        } catch {
            let errorAlert = UIAlertController(title: "Error copying file!", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
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
        
        chooseAlert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in // Upload file from browser
            let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            picker.allowsMultipleSelection = true
            picker.delegate = self
            
            self.present(picker, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Create blank file", style: .default, handler: { (_) in // Create file
            
            let chooseName = UIAlertController(title: "Create blank file", message: "Choose new file name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                
                guard let filename = chooseName.textFields?[0].text else {
                    return
                }
                
                if FileManager.default.createFile(atPath: self.directory.appendingPathComponent(filename).path, contents: nil, attributes: nil) {
                    self.reload()
                } else {
                    let errorAlert = UIAlertController(title: "Error creating file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            self.present(chooseName, animated: true, completion: nil)
            
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Create folder", style: .default, handler: { (_) in // Create folder
            let chooseName = UIAlertController(title: "Create folder", message: "Choose new folder name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New folder name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                
                guard let dirname = chooseName.textFields?[0].text else {
                    return
                }
                
                do {
                    try FileManager.default.createDirectory(atPath: self.directory.appendingPathComponent(dirname).path, withIntermediateDirectories: true, attributes: nil)
                    self.reload()
                } catch {
                    let errorAlert = UIAlertController(title: "Error creating directory!", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }))
        
        if self is PluginsLocalDirectoryTableViewController {
            chooseAlert.addAction(UIAlertAction(title: "Create terminal plugin", style: .default, handler: { (_) in // Create plugin
                let chooseName = UIAlertController(title: "Create plugin", message: "Choose new plugin name", preferredStyle: .alert)
                chooseName.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "New plugin name"
                })
                chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                    
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
                               - You can put resources in the plugin folder, access with the `bundlePath` constant: `bundlePath+"/<File name>"`.
                               - You can't write to the session!

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
                            
                            const bundlePath = document.currentScript.bundlePath;

                            
                            """.data(using: .utf8), attributes: nil) {
                            
                            let errorAlert = UIAlertController(title: "Error creating plugin!", message: "Error creating index.js.", preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            self.present(errorAlert, animated: true, completion: nil)
                            
                        }
                        self.reload()
                    } catch {
                        let errorAlert = UIAlertController(title: "Error creating plugin!", message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                }))
                
                self.present(chooseName, animated: true, completion: nil)
            }))
        }
        
        chooseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
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
            
            tableView.reloadData()
        } catch {}
        
        refreshControl?.endRefreshing()
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
        
        super.init(style: .plain)
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
        
        tableView.register(UINib(nibName: "File Cell", bundle: Bundle.main), forCellReuseIdentifier: "file")
        clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
     
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        
        // Navigation bar items
        let createFile = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create(_:)))
        navigationItem.setRightBarButtonItems([createFile], animated: true)
        
        if !UserDefaults.standard.bool(forKey: "terminalThemesPurchased") {
            // Banner ad
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.rootViewController = self
            bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
            bannerView.delegate = self
            bannerView.load(GADRequest())
        }
    }
    
    /// Show error if there are or open `openFile` file.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .UIApplicationDidBecomeActive, object: nil)
        
        if let error = error {
            let errorAlert = UIAlertController(title: "Error opening directory!", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        if let openFile = openFile {
            guard let index = files.index(of: openFile) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            tableView(tableView, didSelectRowAt: indexPath)
            
            self.openFile = nil
        }
        
        reload()
    }
    
    /// Remove observer.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    /// - Returns: `50`.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    /// - Returns: `1`.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// - Returns: count of `files`.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return files.count
    }
    
    /// - Returns: An `UITableViewCell` with title as the current filename and file icon for current file.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "file") as! FileTableViewCell
        
        // Configure the cell...
        
        cell.filename.text = files[indexPath.row].lastPathComponent
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if isDir.boolValue { // Is directory
                cell.iconView.image = #imageLiteral(resourceName: "File icons/folder")
            } else { // Is file
                cell.iconView.image = fileIcon(forExtension: files[indexPath.row].pathExtension)
            }
        }
        
        let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.tag = indexPath.row
        shareButton.addTarget(self, action: #selector(shareFile(_:)), for: .touchUpInside)
        shareButton.backgroundColor = .clear
        cell.accessoryView = shareButton
                
        return cell
    }
    
    /// - Returns: `true`.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Remove selected file.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                try FileManager.default.removeItem(at: files[indexPath.row])
                
                files.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch let error {
                let errorAlert = UIAlertController(title: "Error removing file!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                tableView.reloadData()
            }
        }
    }
    
    /// - Returns: Enable copying files.
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    /// - Returns: `true`.
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Copy selected file.
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) { // Copy file
            
            Pasteboard.local.localFilePath = directory.appendingPathComponent(files[indexPath.row].lastPathComponent).path
            
            let dirVC = LocalDirectoryTableViewController(directory: FileManager.default.documents)
            dirVC.navigationItem.prompt = "Select a directory where copy file"
            dirVC.delegate = dirVC
            LocalDirectoryTableViewController.action = .copyFile
            
            
            let navVC = UINavigationController(rootViewController: dirVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: dirVC, action: #selector(dirVC.copyFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    // MARK: - Table view delegate
    
    /// Open selected file or directory.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        if cell.iconView.image == #imageLiteral(resourceName: "File icons/folder") { // Open folder
            let dirVC = LocalDirectoryTableViewController(directory: self.files[indexPath.row])
            
            if let delegate = delegate {
                delegate.localDirectoryTableViewController(dirVC, didOpenDirectory: self.files[indexPath.row])
            } else {
                dirVC.delegate = delegate
                self.navigationController?.pushViewController(dirVC, animated: true)
            }
        } else {
            if let delegate = delegate { // Handle the file with delegate
                delegate.localDirectoryTableViewController(self, didOpenFile: self.files[indexPath.row])
            } else { // Default handler
                LocalDirectoryTableViewController.openFile(files[indexPath.row], from: cell.frame, in: view, navigationController: navigationController, showActivityViewControllerInside: self)
            }
        }
    }
    
    // MARK: - Banner view delegate
    
    /// Show ad when it's received.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Show ad only when it received
        tableView.tableHeaderView = bannerView
    }
    
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
                let errorAlert = UIAlertController(title: "Error importing \(url.lastPathComponent)!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Local directory table view controller
    
    /// Copy or move file.
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenDirectory directory: URL) {
        localDirectoryTableViewController.delegate = localDirectoryTableViewController
        
        if LocalDirectoryTableViewController.action == .copyFile {
            localDirectoryTableViewController.navigationItem.prompt = "Select a directory where copy file"
        }
        
        if LocalDirectoryTableViewController.action == .moveFile {
            localDirectoryTableViewController.navigationItem.prompt = "Select a directory where move file"
        }
        
        navigationController?.pushViewController(localDirectoryTableViewController, animated: true, completion: {
            if LocalDirectoryTableViewController.action == .copyFile {
                localDirectoryTableViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: localDirectoryTableViewController, action: #selector(localDirectoryTableViewController.copyFile))], animated: true)
            }
            
            if LocalDirectoryTableViewController.action == .moveFile {
                localDirectoryTableViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: localDirectoryTableViewController, action: #selector(localDirectoryTableViewController.moveFile))], animated: true)
            }
        })
        
    }
    
    /// Call defailt handler.
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL) {
        LocalDirectoryTableViewController.openFile(file, from: localDirectoryTableViewController.tableView.cellForRow(at: IndexPath(row: localDirectoryTableViewController.files.index(of: file) ?? 0, section: 0))?.frame ?? CGRect.zero, in: localDirectoryTableViewController.view, navigationController: navigationController, showActivityViewControllerInside: localDirectoryTableViewController)
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
    
    // MARK: - Static
    
    /// Global delegate.
    static var delegate: LocalDirectoryTableViewControllerStaticDelegate?
    
    /// Action to do.
    static var action = DirectoryAction.none
    
    /// Edit, view or share given file.
    ///
    /// - Parameters:
    ///     - file: File to be opened.
    ///     - frame: Frame where point an `UIActivityController` if the file will be saved.
    ///     - view: View from wich share the file.
    ///     - navigationController: Navigation controller in wich push editor or viewer.
    ///     - viewController: viewController in wich show loading alert.
    static func openFile(_ file: URL, from frame: CGRect, `in` view: UIView, navigationController: UINavigationController?, showActivityViewControllerInside viewController: UIViewController?) {
        
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
                    let alert = UIAlertController(title: "Open file", message: "View HTML page or edit?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "View HTML", style: .default, handler: { (_) in // View HTML
                        let webVC = UIViewController.webViewController
                        webVC.file = file
                        
                        vc.present(UINavigationController(rootViewController: webVC), animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Edit HTML", style: .default, handler: { (_) in // View HTML
                        vc.present(UINavigationController(rootViewController: editTextVC), animated: true, completion: nil)
                    }))
                    
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
            } else if isFilePDF(file) {
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
                let newFolderVC = LocalDirectoryTableViewController(directory: unziped)
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
            }
        }
        
        let activityVC = ActivityViewController(message: "Loading...")
        if let viewController = viewController {
            viewController.present(activityVC, animated: true, completion: {
                openFile()
            })
        } else {
            openFile()
        }
    }
}


