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

/// Table view controller used to manage local files.
class LocalDirectoryTableViewController: UITableViewController, GADBannerViewDelegate, UIDocumentPickerDelegate, LocalDirectoryTableViewControllerDelegate {
    
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
            if #available(iOS 11.0, *) {
                picker.allowsMultipleSelection = true
            }
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
        
        chooseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        chooseAlert.popoverPresentationController?.barButtonItem = sender
        
        self.present(chooseAlert, animated: true, completion: nil)
    }
    
    /// Reload content of directory.
    func reload() {
        files = []
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            for file in files {
                self.files.append(directory.appendingPathComponent(file))
            }
            
            tableView.reloadData()
        } catch {}
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
    
    /// `UIViewController`'s `viewDidLoad` function.
    ///
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-LocalFileBrowser", AnalyticsParameterItemName : "Local File Browser"])
        
        title = directory.lastPathComponent
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "file")
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
     
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
    
    /// `UIViewController`'s `viewDidAppear(_:)` function.
    ///
    /// Show error if there are or open `openFile` file.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
    
    // MARK: - Table view data source
    
    /// `UITableViewController`'s `tableView(_:, heightForRowAt:)` function.
    ///
    /// - Returns: `50`.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    /// `UITableViewController`'s `numberOfSections(in:)` function.
    ///
    /// - Returns: `1`.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// `UITableViewController`'s `tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)` function.
    ///
    /// - Returns: count of `files`.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return files.count
    }
    
    /// `UITableViewController`'s `tableView(_:, cellForRowAt:)` function.
    ///
    /// - Returns: An `UITableViewCell` with title as the current filename and file icon for current file.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "file") as! FileTableViewCell
        cell.contentView.superview?.backgroundColor = .black
        
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
    
    /// `UITableViewController`'s `tableView(_:, canEditRowAt:)` function.
    ///
    /// - Returns: `true`.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// `UITableViewController`'s `tableView(_:, commit:, forRowAt:)` function.
    ///
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
    
    /// `UITableViewController`'s `tableView(_:, canPerformAction:, forRowAt:, withSender:)` function.
    ///
    /// - Returns: Enable copying files.
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    /// `UITableViewController`'s `tableView(_ tableView:, shouldShowMenuForRowAt:` function.
    ///
    /// - Returns: `true`.
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// `UITableViewController`'s `tableView(_:, performAction:, forRowAt:, withSender:)` function.
    ///
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
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
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
    
    /// `GADBannerViewDelegate`'s `adViewDidReceiveAd(_:)` function.
    ///
    /// Show ad when it's received.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Show ad only when it received
        tableView.tableHeaderView = bannerView
    }
    
    // MARK: - Document picker delegate
    
    /// `UIDocumentPickerDelegate`'s `documentPickerWasCancelled(_:)` function.
    ///
    /// Dismiss document picker.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    /// `UIDocumentPickerDelegate`'s `documentPicker(_:, didPickDocumentsAt:)` function.
    ///
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
    
    /// `LocalDirectoryTableViewController`'s `localDirectoryTableViewController(_:, didOpenDirectory:)` function.
    ///
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
    
    /// `LocalDirectoryTableViewController`'s `localDirectoryTableViewController(_:, didOpenFile:)` function.
    ///
    /// Call defailt handler.
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL) {
        LocalDirectoryTableViewController.openFile(file, from: localDirectoryTableViewController.tableView.cellForRow(at: IndexPath(row: localDirectoryTableViewController.files.index(of: file) ?? 0, section: 0))?.frame ?? CGRect.zero, in: localDirectoryTableViewController.view, navigationController: navigationController, showActivityViewControllerInside: localDirectoryTableViewController)
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
            if let _ = try? String.init(contentsOfFile: file.path) { // Is text
                var editTextVC: EditTextViewController! {
                    let editTextViewController = Bundle.main.loadNibNamed("EditTextViewController", owner: nil, options: nil)!.first as! EditTextViewController
                    
                    editTextViewController.file = file
                    
                    return editTextViewController
                }
                
                if file.pathExtension.lowercased() == "html" || file.pathExtension.lowercased() == "htm" { // Ask for view HTML or edit
                    let alert = UIAlertController(title: "Open file", message: "View HTML page or edit?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "View HTML", style: .default, handler: { (_) in // View HTML
                        guard let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)?.first as? WebViewController else { return }
                        webVC.file = file
                        
                        navigationController?.pushViewController(webVC, animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Edit HTML", style: .default, handler: { (_) in // View HTML
                        navigationController?.pushViewController(editTextVC, animated: true)
                    }))
                    
                    if viewController == nil {
                        navigationController?.present(alert, animated: true, completion: nil)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            navigationController?.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    if viewController == nil {
                        navigationController?.pushViewController(editTextVC!, animated: true)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            navigationController?.pushViewController(editTextVC, animated: true)
                        })
                    }
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
            } else if let image = UIImage(contentsOfFile: file.path) { // Is image
                let imageVC = Bundle.main.loadNibNamed("ImageViewController", owner: nil, options: nil)!.first! as! ImageViewController
                imageVC.image = image
                
                if viewController == nil {
                    navigationController?.pushViewController(imageVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(imageVC, animated: true)
                    })
                }
            } else if AVAsset(url: file).isPlayable { // Is video or audio
                let player = AVPlayer(url: file)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                
                if viewController == nil {
                    navigationController?.pushViewController(playerVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(playerVC, animated: true)
                    })
                }
            } else if isFilePDF(file) { // Is PDF
                let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
                webVC.file = file
                
                if viewController == nil {
                    navigationController?.pushViewController(webVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(webVC, animated: true)
                    })
                }
            } else { // Share
                let shareVC = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                shareVC.popoverPresentationController?.sourceView = view
                viewController?.present(shareVC, animated: true, completion: nil)
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


