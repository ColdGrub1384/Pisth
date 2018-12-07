// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import Pisth_Shared
import Firebase
import CoreData
import Pisth_API
import StoreKit
import PanelKit
import CoreSpotlight
import UserNotifications

/// Collection view controller to manage remote files.
class DirectoryCollectionViewController: UICollectionViewController, LocalDirectoryCollectionViewControllerDelegate, DirectoryCollectionViewControllerDelegate, UIDocumentPickerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, SKStoreProductViewControllerDelegate, PanelContentDelegate {
    
    /// Directory used to list files.
    var directory: String
    
    /// The connection's home directory.
    var homeDirectory = "/"
    
    /// Connection to open if is not.
    var connection: RemoteConnection
    
    /// Fetched files.
    var files: [NMSFTPFile]?
    
    /// All files including hidden files.
    var allFiles: [NMSFTPFile]?
    
    /// Delegate used.
    var delegate: DirectoryCollectionViewControllerDelegate?
    
    /// Close after sending file.
    var closeAfterSending = false
    
    private var isViewSet = false
    
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
                view.frame.size = footerSuperview?.frame.size ?? view.frame.size
                view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                footerSuperview?.addSubview(view)
            } else {
                (collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = CGSize.zero
            }
        }
    }
    
    /// `footerView` superview.
    var footerSuperview: UIView?
    
    /// Open this connection in Pisth APT.
    @objc func openAPTManager() {
        guard let connection = ConnectionManager.shared.connection else {
            return
        }
        
        let apt = PisthAPT(urlScheme: URL(string: "pisth://")!)
        if apt.canOpen {
            apt.open(connection: connection)
        } else {
            let appStore = SKStoreProductViewController()
            appStore.delegate = self
            appStore.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: "1369552277"], completionBlock: nil)
            present(appStore, animated: true, completion: nil)
        }
    }
    
    /// Resume closed session.
    @objc func resume() {
                
        let activityVC = ActivityViewController(message: Localizable.loading)
        present(activityVC, animated: true) {
            let dirVC = DirectoryCollectionViewController(connection: self.connection, directory: self.directory)

            activityVC.dismiss(animated: true) {
                self.navigationController?.pushViewController(dirVC, animated: true)
            }
        }
    }
    
    /// Show file info.
    ///
    /// - Parameters:
    ///     - sender: Sender button. Its `tag` is the index of the file to inspect.
    @available(*, deprecated, message: "Use `FileCollectionViewCell.showFileInfo(_:)`")
    @objc func showInfo(sender: UIButton) {
        
        guard let files = files else {
            return
        }
        
        let fileInfoVC = FileInfoViewController.makeViewController()
        fileInfoVC.file = files[sender.tag]
        if sender.tag != files.count-1 {
            fileInfoVC.parentDirectory = directory
        } else {
            fileInfoVC.parentDirectory = directory.nsString.deletingLastPathComponent.nsString.deletingLastPathComponent
        }
        fileInfoVC.modalPresentationStyle = .popover
        fileInfoVC.popoverPresentationController?.sourceView = sender
            fileInfoVC.popoverPresentationController?.delegate = fileInfoVC
        
        present(fileInfoVC, animated: true)
    }
    
    /// Set layout selected by the user.
    func loadLayout() {
        var layout: UICollectionViewFlowLayout
        if UserKeys.areListViewsEnabled.boolValue {
            layout = DirectoryCollectionViewController.listLayout(forView: view)
        } else {
            layout = DirectoryCollectionViewController.gridLayout
        }
        if let currentLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = currentLayout.footerReferenceSize
            layout.headerReferenceSize = currentLayout.headerReferenceSize
        }
        collectionView?.reloadData()
        collectionView?.setCollectionViewLayout(layout, animated: false)
    }
        
    /// Init with given connection and directory.
    ///
    /// - Parameters:
    ///     - connection: Connection to be opened if is not.
    ///     - directory: Directory to open, by default, is `connection`'s default path.
    ///
    /// - Returns: A Directory collection view controller at given directory.
    init(connection: RemoteConnection, directory: String? = nil) {
        self.connection = connection
        ConnectionManager.shared.connection = connection
        
        if directory == nil {
            self.directory = connection.path
        } else {
            self.directory = directory!
        }
        
        if !Reachability.isConnectedToNetwork() {
            ConnectionManager.shared.result = .notConnected
        } else {
            if ConnectionManager.shared.session == nil && ConnectionManager.shared.filesSession == nil {
                ConnectionManager.shared.connect()
            }
        }
        
        if ConnectionManager.shared.result == .connectedAndAuthorized {
            
            if self.directory.contains("~") {
                // Get absolute path from "~"
                if let path = try? ConnectionManager.shared.filesSession?.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "") {
                    self.directory = self.directory.replacingOccurrences(of: "~", with: path ?? "/")
                    self.homeDirectory = path ?? "/"
                }
            }
            
            if directory == nil {
                // Sorry Termius ;-(
                let os = try? ConnectionManager.shared.filesSession?.channel.execute("""
                SA_OS_TYPE="Linux"
                REAL_OS_NAME=`uname`
                if [ "$REAL_OS_NAME" != "$SA_OS_TYPE" ] ;
                then
                echo $REAL_OS_NAME
                else
                DISTRIB_ID=\"`cat /etc/*release`\"
                echo $DISTRIB_ID;
                fi;
                exit;
                """)
                
                connection.os = os ?? nil
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
                request.returnsObjectsAsFaults = false
                
                do {
                    let results = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                    
                    for result in results {
                        if result.value(forKey: "host") as? String == connection.host {
                            if let os = os {
                                result.setValue(os, forKey: "os")
                            }
                        }
                    }
                    
                    DataManager.shared.saveContext()
                } catch let error {
                    print("Error retrieving connections: \(error.localizedDescription)")
                }
            }
            
            // TODO: - Make it compatible with only SFTP
            // Ignore files listed in ~/.pisthignore
            /*if let result = try? ConnectionManager.shared.filesSession!.channel.execute("cat ~/.pisthignore") {
                for file in result.components(separatedBy: "\n") {
                    if file != "" && !file.hasSuffix("#") {
                        
                        if let files = self.files {
                            var i = 0
                            for file_ in files {
                                if file_.filename == file {
                                    self.files!.remove(at: i)
                                    self.isDir.remove(at: i)
                                }
                                i += 1
                            }
                        }
                    }
                }
            }*/
        }
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-RemoteFileBrowser", AnalyticsParameterItemName : "Remote File Browser"])
        
        collectionView?.backgroundColor = .white
        collectionView?.backgroundView = UIActivityIndicatorView(style: .gray)
        (collectionView?.backgroundView as? UIActivityIndicatorView)?.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCard()
        
        if !isViewSet {
            
            isViewSet = true
            
            var files = ConnectionManager.shared.files(inDirectory: self.directory, showHiddenFiles: true)
            self.allFiles = files
            if !UserKeys.shouldHiddenFilesBeShown.boolValue {
                for file in files ?? [] {
                    if file.filename.hasPrefix(".") {
                        guard let i = files?.index(of: file) else { break }
                        files?.remove(at: i)
                    }
                }
            }
            self.files = files
            
            collectionView?.refreshControl?.endRefreshing()
            
            guard self.files != nil else {
                showErrorIfThereIsOne()
                return
            }
            
            if self.directory.removingUnnecessariesSlashes != "/" {
                // Append parent directory
                guard let parent = ConnectionManager.shared.filesSession?.sftp.infoForFile(atPath: self.directory.nsString.deletingLastPathComponent) else {
                    return
                }
                self.files!.append(parent)
            }
            
            let titleComponents = directory.components(separatedBy: "/")
            title = titleComponents.last
            if directory.hasSuffix("/") {
                title = titleComponents[titleComponents.count-2]
            }
            
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .never
            }
            
            // TableView cells
            collectionView?.register(UINib(nibName: "Grid File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileGrid")
            collectionView?.register(UINib(nibName: "List File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileList")
            collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
            collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
            collectionView?.refreshControl = UIRefreshControl()
            collectionView?.backgroundView = nil
            collectionView?.contentInset.bottom += cardHandleAreaHeight
            clearsSelectionOnViewWillAppear = false
            if #available(iOS 11.0, *) {
                collectionView?.dropDelegate = self
                collectionView?.dragDelegate = self
                collectionView?.dragInteractionEnabled = true
            }
            
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
                    guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)) else { return }
                    
                    if !result {
                        let errorAlert = UIAlertController(title: Localizable.Browsers.errorCreatingDirectory, message: nil, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
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
            
            // Initialize the refresh control.
            collectionView?.refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
            
            // Bar buttons
            let uploadFile = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadFile(_:)))
            let terminal = UIBarButtonItem(image: #imageLiteral(resourceName: "terminal"), style: .plain, target: self, action: #selector(openShell(_:)))
            let git = UIBarButtonItem(title: "Git", style: .plain, target: self, action: #selector(self.git))
            let apt = UIBarButtonItem(image: #imageLiteral(resourceName: "package"), style: .plain, target: self, action: #selector(openAPTManager))
            var buttons: [UIBarButtonItem] {
                guard files != nil else { return [uploadFile, terminal] }
                guard let session = ConnectionManager.shared.filesSession else { return [uploadFile, terminal] }
                
                // Check for GIT
                var isGitRepo = false
                for file in allFiles ?? [] {
                    if file.filename == ".git" || file.filename == ".git/" {
                        isGitRepo = true
                    }
                }
                
                // Check for Aptitude
                guard let resultAPT = try? session.channel.execute("command -v apt-get").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "\n") else { return [] }
                
                if isGitRepo {
                    if resultAPT.isEmpty {
                        return [uploadFile, git, terminal]
                    } else {
                        return [uploadFile, apt, git, terminal]
                    }
                } else {
                    if resultAPT.isEmpty {
                        return [uploadFile, terminal]
                    } else {
                        return [uploadFile, apt, terminal]
                    }
                }
            }
            
            navigationItem.setRightBarButtonItems(buttons, animated: true)
            
            // Siri Shortcuts
            
            let activity = NSUserActivity(activityType: "ch.marcela.ada.Pisth.openDirectory")
            if #available(iOS 12.0, *) {
                activity.isEligibleForPrediction = true
                //                    activity.suggestedInvocationPhrase = connection.name
            }
            activity.isEligibleForSearch = true
            activity.keywords = [connection.name, connection.username, connection.host, directory.nsString.lastPathComponent, "ssh", "sftp"]
            if directory == connection.path.replacingOccurrences(of: "~", with: homeDirectory) {
                activity.title = connection.name
            } else {
                activity.title = directory.nsString.lastPathComponent
            }
            var userInfo = ["username":connection.username, "password":connection.password, "host":connection.host, "directory":directory, "port":connection.port] as [String : Any]
            
            if let pubKey = connection.publicKey {
                userInfo["publicKey"] = pubKey
            }
            
            if let privKey = connection.privateKey {
                userInfo["privateKey"] = privKey
            }
            
            activity.userInfo = userInfo
            
            let attributes = CSSearchableItemAttributeSet(itemContentType: "public.item")
            if let os = connection.os?.lowercased(), directory == connection.path.replacingOccurrences(of: "~", with: homeDirectory) {
                if let logo = UIImage(named: (os.slice(from: " id=", to: " ")?.replacingOccurrences(of: "\"", with: "") ?? os).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")) {
                    attributes.thumbnailData = logo.pngData()
                }
            } else {
                attributes.thumbnailData = #imageLiteral(resourceName: "File icons/folder").pngData()
            }
            attributes.addedDate = Date()
            attributes.contentDescription = "sftp://\(connection.username)@\(connection.host):\(connection.port)\(directory)"
            activity.contentAttributeSet = attributes
            
            self.userActivity = activity
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(showErrorBannerIfItsNeeded), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Toolbar
        setToolbarItems([UIBarButtonItem(title:"/", style: .plain, target: self, action: #selector(goToRoot)), UIBarButtonItem(image: #imageLiteral(resourceName: "home"), style: .plain, target: self, action: #selector(goToHome)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), AppDelegate.shared.showBookmarksBarButtonItem], animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        
        // Connection errors
        self.showErrorIfThereIsOne()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        unsetupCard()
        
        (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.setToolbarHidden(true, animated: true)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != DirectoryCollectionViewController.gridLayout.itemSize {
            layout.itemSize.width = size.width
        }
        
        // I hate timers 😡😡
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            self.reloadCard()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize != DirectoryCollectionViewController.gridLayout.itemSize {
            layout.itemSize.width = view.frame.size.width
        }
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        var userInfo = ["username":connection.username, "password":connection.password, "host":connection.host, "directory":directory, "port":connection.port] as [String : Any]
        
        if let pubKey = connection.publicKey {
            userInfo["publicKey"] = pubKey
        }
        
        if let privKey = connection.privateKey {
            userInfo["privateKey"] = privKey
        }
        
        activity.userInfo = userInfo
    }
    
    // MARK: - Connection errors handling
    
    /// Show error if there is one.
    @objc func showErrorIfThereIsOne() {
        checkForConnectionError(errorHandler: {
            self.showError()
        }) {
            if self.files == nil {
                
                self.navigationController?.popViewController(animated: true, completion: {
                    let alert = UIAlertController(title: Localizable.Browsers.errorOpeningDirectory, message: Localizable.DirectoryCollectionViewController.checkForPermssions, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
    
    /// Show error banner if it's needed.
    @objc func showErrorBannerIfItsNeeded() {
        checkForConnectionError(errorHandler: {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            self.showErrorBanner()
        })
    }
    
    /// Show view saying that the connection was closed.
    @objc func showErrorBanner() {
        
        let view = UIView.disconnected
        
        (view.viewWithTag(1) as? UIButton)?.addTarget(self, action: #selector(resume), for: .touchUpInside)
        (view.viewWithTag(2) as? UIButton)?.addTarget(navigationController, action: #selector(navigationController?.popToRootViewController(animated:)), for: .touchUpInside)
        
        view.frame.size = CGSize(width: 320, height: 70)
        
        headerView = view
        
        loadLayout()
        
        collectionView?.setContentOffset(CGPoint(x: 0, y: 0-view.frame.height), animated: true)
    }
    
    /// Go back and show error.
    func showError() {
        
        collectionView?.backgroundView = nil
        
        setToolbarItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), AppDelegate.shared.showBookmarksBarButtonItem], animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        
        let navVC = AppDelegate.shared.navigationController
        
        guard navVC.visibleViewController == self else {
            return
        }
        
        let result = ConnectionManager.shared.result
        
        var alert: UIAlertController!
        switch result {
        case .notConnected:
            alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorOpeningSessionTitle, message: Localizable.DirectoryCollectionViewController.errorConnecting, preferredStyle: .alert)
        case .connected:
            alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorOpeningSessionTitle, message: Localizable.DirectoryCollectionViewController.errorAuthenticating, preferredStyle: .alert)
        default:
            alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.sessionClosedTitle, message: Localizable.DirectoryCollectionViewController.sessionClosedMessage, preferredStyle: .alert)
        }
                
        if alert != nil {
            
            alert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: { (_) in
                AppDelegate.shared.showBookmarks()
            }))
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Check for connection errors and run handler if there is an error.
    func checkForConnectionError(errorHandler: @escaping () -> Void, successHandler: (() -> Void)? = nil) {
        
        guard AppDelegate.shared.action == nil else {
            successHandler?()
            return
        }
        
        guard let session = ConnectionManager.shared.session else {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        if !Reachability.isConnectedToNetwork() {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        if !session.isConnected || !session.isAuthorized {
            ConnectionManager.shared.session = nil
            ConnectionManager.shared.filesSession = nil
            errorHandler()
            return
        }
        
        do {
            try session.channel.write("")
            if let handler = successHandler {
                handler()
            }
        } catch {
            errorHandler()
        }
    }
    
    
    // MARK: - Actions

    /// Go to given directory.
    ///
    /// - Parameters:
    ///     - directory: Directory where go.
    func goTo(directory: String) {
        checkForConnectionError(errorHandler: {
            self.showError()
        }) {
            let dirVC = DirectoryCollectionViewController(connection: self.connection, directory: directory)
            if let delegate = self.delegate {
                
                delegate.directoryCollectionViewController(dirVC, didOpenDirectory: directory)
            } else {
                self.navigationController?.pushViewController(dirVC, animated: true)
            }
        }
    }
    
    /// Go to "~".
    @objc func goToHome() {
        goTo(directory: "~")
    }
    
    /// Go to "/".
    @objc func goToRoot() {
        goTo(directory: "/")
    }

    
    /// Dismiss `navigationController`.
    @objc func close() {
    	 navigationController?.dismiss(animated: true, completion: nil)
    }
    
    /// Open source control manager for Git repos.
    @objc func git() {
        let navVC = SourceControlTableViewController.makeViewController()
        guard let branchesVC = navVC.topViewController as? SourceControlTableViewController else { return }
        
        branchesVC.repoPath = directory
        
        present(navVC, animated: true, completion: nil)
    }
    
    /// Reload content.
    @objc func reload() { // Reload current directory content
        
        self.files = nil
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        guard ConnectionManager.shared.filesSession != nil else { return }
        var files = ConnectionManager.shared.files(inDirectory: self.directory, showHiddenFiles: true)
        self.allFiles = files
        if !UserKeys.shouldHiddenFilesBeShown.boolValue {
            for file in files ?? [] {
                if file.filename.hasPrefix(".") {
                    guard let i = files?.index(of: file) else { break }
                    files?.remove(at: i)
                }
            }
        }
        self.files = files
            
        if self.directory.removingUnnecessariesSlashes != "/" {
            // Append parent directory
            guard let parent = ConnectionManager.shared.filesSession!.sftp.infoForFile(atPath: self.directory.nsString.deletingLastPathComponent) else { return }
            self.files!.append(parent)
        }
        
        // TODO: Make it compatible with SFTP only
        // Ignore files listed in ~/.pisthignore
        /*if let result = try? ConnectionManager.shared.filesSession!.channel.execute("cat ~/.pisthignore") {
            for file in result.components(separatedBy: "\n") {
                if file != "" && !file.hasSuffix("#") {
                    
                    if let indexOfFile = self.files?.index(of: self.directory.nsString.appendingPathComponent(file)) {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                    
                    if let indexOfFile = self.files?.index(of: self.directory.nsString.appendingPathComponent(file)+"/") {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                    
                    if let indexOfFile = self.files?.index(of: "."+self.directory.nsString.appendingPathComponent(file)) {
                        self.files?.remove(at: indexOfFile)
                        isDir.remove(at: indexOfFile)
                    }
                }
            }
        }*/
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    /// Open shell in current directory.
    ///
    /// - Parameters:
    ///     - sender: Sender `UIBarButtonItem`.
    @objc func openShell(_ sender: UIBarButtonItem) {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        ContentViewController.shared.presentTerminal(inDirectory: directory, from: sender)
    }
    
    /// Upload given file in current dircectory.
    ///
    /// - Parameters:
    ///     - file: Local file to upload.
    ///     - data: Data to send.
    ///     - filename: The filename. Default is `file.lastPathComponent`.
    ///     - directory: Directory where upload files, default is current directory.
    ///     - uploadHandler: Code to execute after uploading file, nil by default.
    ///     - errorHandler: Code to execute after the upload failed.
    ///     - showAlert: If show uploading alert.
    ///
    /// - Returns: `false` if upload failed, always returns `true` if `showAlert` is `true`.
    @discardableResult func sendFile(file: URL? = nil, data: Data? = nil, filename: String? = nil, toDirectory path: String? = nil, uploadHandler: (() -> Void)? = nil, errorHandler: (() -> Void)? = nil, showAlert: Bool = true) -> Bool {
        
        let filename_ = filename ?? file?.lastPathComponent ?? "uploaded"
        
        var directory: String!
        if path == nil {
            directory = self.directory
        } else {
            directory = path
        }
        
        let activityVC = ActivityViewController(message: Localizable.uploading)
        
        /// Upload file with given parameters of parent function.
        ///
        /// - Returns: `false` if upload failed.
        func upload() -> Bool {
            do {
                
                guard !(file != nil && data != nil) else {
                    fatalError("A file and data can't be specified. Choose one.")
                }
                
                var dataToSend: Data
                if let file = file {
                    dataToSend = try Data(contentsOf: file)
                } else if let data = data {
                    dataToSend = data
                } else {
                    fatalError("A file URL or the data have to be specified.")
                }
                
                /// Show error or run error handler.
                func showError_() {
                    if let handler = errorHandler {
                        handler()
                    } else {
                        let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: Localizable.DirectoryCollectionViewController.errorUploadingMessage, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: { (_) in
                            if let handler = errorHandler {
                                handler()
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
                /// Show upload error and dismiss uploding alert.
                func showError() {
                    if showAlert {
                        activityVC.dismiss(animated: true, completion: {
                            showError_()
                        })
                    } else {
                        showError_()
                    }
                }
                
                guard let result = ConnectionManager.shared.filesSession?.sftp.writeContents(dataToSend, toFileAtPath: directory.nsString.appendingPathComponent(filename_)) else {
                    
                    showError()
                    
                    return false
                }
                
                if !result {
                    showError()
                    return false
                }
                
                if self.closeAfterSending {
                    /// Close this Navigation controller.
                    func close(alert: UIViewController) {
                        alert.dismiss(animated: true, completion: {
                            if let handler = uploadHandler {
                                handler()
                            } else {
                                AppDelegate.shared.close()
                            }
                        })
                    }
                    
                    if result {
                        close(alert: activityVC)
                    } else {
                        
                        /// Show error and call `close(alert:)` after clicking "Ok".
                        func showErrorAndCallClose() {
                            let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: Localizable.DirectoryCollectionViewController.errorUploadingMessage, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: { (_) in
                                close(alert: alert)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                        if showAlert {
                            activityVC.dismiss(animated: true, completion: {
                                showErrorAndCallClose()
                            })
                            
                            return false
                        } else {
                            showErrorAndCallClose()
                            
                            return false
                        }
                    }
                    
                } else {
                    if showAlert {
                        activityVC.dismiss(animated: true, completion: {
                            self.reload()
                            if let handler = uploadHandler {
                                handler()
                            }
                        })
                    } else {
                        self.reload()
                        if let handler = uploadHandler {
                            handler()
                        }
                    }
                }
                
            } catch let error {
                /// Show error reading file.
                func showErrorReadingFile() {
                    let errorAlert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorReadingFile, message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: { (action) in
                        
                        if let handler = uploadHandler {
                            handler()
                        }
                        
                    }))
                    self.present(errorAlert, animated: true, completion: nil)
                }
                
                if showAlert {
                    activityVC.dismiss(animated: true, completion: {
                        showErrorReadingFile()
                    })
                    
                    return false
                } else {
                    showErrorReadingFile()
                    
                    return false
                }
            }
            
            return true
        }
        
        if showAlert {
            self.present(activityVC, animated: true) {
                _ = upload()
            }
        } else {
            return upload()
        }
        
        return true
    }
    
    /// Upload file in current directory.
    ///
    /// - Parameters:
    ///     - file: Local file url.
    ///     - uploadHandler: Code to execute after uploading file, nil by default.
    ///
    /// - Returns: Alert asking for sending file.
    func upload(file: URL, uploadHandler: (() -> Void)? = nil) -> UIAlertController {
        // Upload file
        
        // Ask user to send file
        let confirmAlert = UIAlertController(title: file.lastPathComponent, message: Localizable.DirectoryCollectionViewController.send(file.lastPathComponent, to: directory.nsString.lastPathComponent), preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: Localizable.no, style: .cancel, handler: { (action) in
            
            if let handler = uploadHandler {
                handler()
            }
            
        }))
        
        confirmAlert.addAction(UIAlertAction(title: Localizable.yes, style: .default, handler: { (action) in
            
            /// - Parameters:
            ///     - item: Local file or directory URL.
            /// - Returns: `true` if given item is directory.
            func isItemDirectory(_ item: URL) -> Bool {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
                    return isDir.boolValue
                } else {
                    return false
                }
            }
            
            /// - Parameters:
            ///     - directory: Local directory URL.
            /// - Returns: Files in given directory.
            func filesIn(directory: URL) -> [URL] {
                if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
                    return files
                } else {
                    return []
                }
            }
            
            /// Show upload error.
            func showError() {
                let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: Localizable.DirectoryCollectionViewController.errorUploadingMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: { (_) in
                    if let handler = uploadHandler {
                        handler()
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            if isItemDirectory(file) { // Upload directory
                
                let activityVC = ActivityViewController(message: Localizable.uploading)
                
                /// Upload files in given directory.
                ///
                /// - Parameters:
                ///     - directory: Local directory URL.
                ///     - path: Remote directory path.
                ///
                /// - Returns: `false` if upload failed.
                func uploadFilesInDirectory(_ directory: URL, toPath path: String) -> Bool {
                    
                    guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: path) else {
                        
                        activityVC.dismiss(animated: true, completion: {
                            showError()
                        })
                        
                        return false
                    }
                    
                    guard result else {
                        activityVC.dismiss(animated: true, completion: {
                            showError()
                        })
                        
                        return false
                    }
                    
                    for url in filesIn(directory: directory) {
                        
                        if isItemDirectory(url) {
                                
                            if !uploadFilesInDirectory(url, toPath: path.nsString.appendingPathComponent(url.lastPathComponent)) {
                                
                                activityVC.dismiss(animated: true, completion: {
                                    showError()
                                })
                                
                                return false
                            }
                                
                        } else {
                            if !self.sendFile(file: url, toDirectory: path, showAlert: false) {
                                
                                activityVC.dismiss(animated: true, completion: {
                                    showError()
                                })
                                
                                return false
                            }
                        }
                    }
                    
                    activityVC.dismiss(animated: true, completion: {
                        self.reload()
                    })
                    
                    return true
                }
                
                self.present(activityVC, animated: true, completion: {
                     _ = uploadFilesInDirectory(file, toPath: self.directory.nsString.appendingPathComponent(file.lastPathComponent))
                })
                
                
            } else { // Upload file
                self.sendFile(file: file, uploadHandler: uploadHandler)
            }
            
        }))
        
        return confirmAlert
    }
    
    /// Show an alert to choose if import a file, create blank file, or create directory.
    ///
    /// - Parameters:
    ///     - sender: Send bar button item.
    @objc func uploadFile(_ sender: UIBarButtonItem) {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        let chooseAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.Browsers.import, style: .default, handler: { (_) in // Upload file from browser
            let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            if #available(iOS 11.0, *) {
                picker.allowsMultipleSelection = true
            }
            picker.delegate = self
            
            self.present(picker, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.DirectoryCollectionViewController.importFromPisth, style: .default, handler: { (_) in // Upload file from other session
            
            AppDelegate.shared.pisthAPIDirectoryCollectionViewControllerSender = self
            Pisth(message: nil, urlScheme: URL(string:"pisth://")!).importFile()
        }))
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.Browsers.createTitle, style: .default, handler: { (_) in // Create file
            
            let chooseName = UIAlertController(title: Localizable.Browsers.createTitle, message: Localizable.Browsers.createMessage, preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.FileCollectionViewCell.newFileName
            })
            chooseName.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
                
                let newPath = self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)
                
                guard let result = ConnectionManager.shared.filesSession?.sftp.writeFile(atPath: Bundle.main.path(forResource: "empty", ofType: nil), toFileAtPath: newPath) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: Localizable.Browsers.errorCreatingFile, message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
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
                guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: Localizable.Browsers.errorCreatingDirectory, message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
        
        chooseAlert.popoverPresentationController?.barButtonItem = sender
        
        self.present(chooseAlert, animated: true, completion: nil)
    }
    
    /// Copy file in current directory
    @objc func copyFile() {
        DirectoryCollectionViewController.action = .none
        navigationController?.dismiss(animated: true, completion: {
            
            self.checkForConnectionError(errorHandler: {
                self.showError()
            })
            
            let progress = UIAlertController(title: Localizable.copying, message: "\n\n", preferredStyle: .alert)
            
            var continue_ = true
            
            progress.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: { _ in
                continue_ = false
            }))
            
            UIApplication.shared.keyWindow?.rootViewController?.present(progress, animated: true, completion: {
                
                //  Add the progress bar
                let progressView = UIProgressView(frame: CGRect(x: 8, y: 72, width: progress.view.frame.width - 8 * 2, height: 2))
                progressView.tintColor = UIApplication.shared.keyWindow?.tintColor
                progress.view.addSubview(progressView)
                
                DispatchQueue.global(qos: .background).async {
                    guard let result = ConnectionManager.shared.filesSession?.sftp.copyContents(ofPath: Pasteboard.local.filePath!, toFileAtPath: self.directory.nsString.appendingPathComponent(Pasteboard.local.filePath!.nsString.lastPathComponent), progress: { (receivedBytes, bytesToBeReceived) -> Bool in
                        
                        let received = ByteCountFormatter().string(fromByteCount: Int64(receivedBytes))
                        let toBeReceived = ByteCountFormatter().string(fromByteCount: Int64(bytesToBeReceived))
                        
                        DispatchQueue.main.async {
                            progress.message = "\(received) / \(toBeReceived)\n"
                            progressView.setProgress(Float(receivedBytes)/Float((bytesToBeReceived)), animated: true)
                        }
                        
                        return continue_
                    }) else {
                        progress.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    progress.dismiss(animated: true, completion: {
                        if !result && continue_ {
                            let errorAlert = UIAlertController(title: Localizable.Browsers.errorCopyingFile, message: nil, preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                            UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                        }
                    })
                    
                    if let dirVC = AppDelegate.shared.navigationController.visibleViewController as? DirectoryCollectionViewController {
                        dirVC.reload()
                    }
                    
                    Pasteboard.local.filePath = nil
                }
            })
            
        })
    }
    
    /// Move file in current directory
    @objc func moveFile() {
        
        checkForConnectionError(errorHandler: {
            self.showError()
        })
        
        DirectoryCollectionViewController.action = .none
        navigationController?.dismiss(animated: true, completion: {
            
            self.checkForConnectionError(errorHandler: {
                self.showError()
            })
            
            guard let result = ConnectionManager.shared.filesSession?.sftp.moveItem(atPath: Pasteboard.local.filePath!, toPath: self.directory.nsString.appendingPathComponent(Pasteboard.local.filePath!.nsString.lastPathComponent)) else { return }
                
            if let dirVC = AppDelegate.shared.navigationController.visibleViewController as? DirectoryCollectionViewController {
                dirVC.reload()
            }
            
            if !result {
                let errorAlert = UIAlertController(title: Localizable.Browsers.errorMovingFile, message: nil, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
            }
                
            Pasteboard.local.filePath = nil
        })
    }
    
    // MARK: - Collection view data source
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let files = files {
            return files.count
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell: FileCollectionViewCell
        if UserKeys.areListViewsEnabled.boolValue {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileList", for: indexPath) as! FileCollectionViewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileGrid", for: indexPath) as! FileCollectionViewCell
        }
        cell.directoryCollectionViewController = self
        
        // Configure the cell...
        
        guard let files = files else { return cell }
        
        cell.filename.text = files[indexPath.row].filename
        
        if files[indexPath.row].isDirectory {
            cell.iconView.image = #imageLiteral(resourceName: "File icons/folder")
        } else {
            cell.iconView.image = UIImage.icon(forPathExtension: files[indexPath.row].filename.nsString.pathExtension, preferredSize: .smallest)
        }
        
        if files[indexPath.row].filename.nsString.lastPathComponent.hasPrefix(".") {
            cell.filename.isEnabled = false
            cell.iconView.alpha = 0.5
        } else {
            cell.filename.isEnabled = true
            cell.iconView.alpha = 1
        }
        
        if indexPath.row == files.count-1 && directory.removingUnnecessariesSlashes != "/" {
            cell.filename.text = "../"
        }
        
        cell.more?.isHidden = false
        cell.more?.text = files[indexPath.row].permissions
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if files![indexPath.row].isDirectory {
            return false
        }
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == #selector(copy(_:)) { // Copy file
            
            Pasteboard.local.filePath = directory.nsString.appendingPathComponent(files![indexPath.row].filename)
            
            let dirVC = DirectoryCollectionViewController(connection: connection, directory: directory)
            dirVC.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereCopyFile
            dirVC.delegate = dirVC
            DirectoryCollectionViewController.action = .copyFile
            
            
            let navVC = UINavigationController(rootViewController: dirVC)
            present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.copyHere, style: .plain, target: dirVC, action: #selector(dirVC.copyFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
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
    
    // MARK: - Collection view delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let files = files else { return }
        var path = self.directory.nsString.appendingPathComponent(files[indexPath.row].filename)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell {
            if cell.filename.text == "../" {
                path = self.directory.nsString.deletingLastPathComponent
            }
        }
        
        var continueDownload = true
        
        self.checkForConnectionError(errorHandler: {
            self.showError()
        }) {
            if files[indexPath.row].isDirectory { // Open folder
                
                let dirVC = DirectoryCollectionViewController(connection: self.connection, directory: path)
                if let delegate = self.delegate {
                    
                    delegate.directoryCollectionViewController(dirVC, didOpenDirectory: path)
                    
                    collectionView.deselectItem(at: indexPath, animated: true)
                } else {
                    
                    self.navigationController?.pushViewController(dirVC, animated: true)
                            
                    collectionView.deselectItem(at: indexPath, animated: true)
                }
            } else { // Download file
                
                let activityVC = UIAlertController(title: Localizable.DirectoryCollectionViewController.downloading, message: "\n\n", preferredStyle: .alert)
                activityVC.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: { (_) in
                    continueDownload = false
                    collectionView.deselectItem(at: indexPath, animated: true)
                }))
                
                self.present(activityVC, animated: true, completion: {
                    
                    //  Add the progress bar
                    let progressView = UIProgressView(frame: CGRect(x: 8, y: 72, width: activityVC.view.frame.width - 8 * 2, height: 2))
                    progressView.tintColor = UIApplication.shared.keyWindow?.tintColor
                    activityVC.view.addSubview(progressView)
                    
                    let newFile = FileManager.default.documents.appendingPathComponent(path.nsString.lastPathComponent)
                    
                    guard let session = ConnectionManager.shared.filesSession else { return }
                    
                    DispatchQueue.global(qos: .background).async {
                        if let data = session.sftp.contents(atPath: path, progress: { (receivedBytes, bytesToBeReceived) -> Bool in
                            
                            let received = ByteCountFormatter().string(fromByteCount: Int64(receivedBytes))
                            let toBeReceived = ByteCountFormatter().string(fromByteCount: Int64(bytesToBeReceived))
                            
                            DispatchQueue.main.async {
                                activityVC.message = "\(received) / \(toBeReceived)\n"
                                progressView.setProgress(Float(receivedBytes)/Float(bytesToBeReceived), animated: true)
                            }
                            
                            return continueDownload
                        }) {
                            DispatchQueue.main.async {
                                do {
                                    try data.write(to: newFile)
                                    
                                    activityVC.dismiss(animated: true, completion: {
                                        ConnectionManager.shared.saveFile = SaveFile(localFile: newFile.path, remoteFile: path)
                                        LocalDirectoryCollectionViewController.openFile(newFile, wasJustDownloaded: true, from: collectionView.cellForItem(at: indexPath)!.frame, in: collectionView, navigationController: self.navigationController, showActivityViewControllerInside: self)
                                    })
                                    
                                    // Send notification
                                    let content = UNMutableNotificationContent()
                                    content.title = newFile.lastPathComponent
                                    content.body = Localizable.DirectoryCollectionViewController.downloadFinished
                                    content.sound = UNNotificationSound.default
                                    let request = UNNotificationRequest(identifier: "download", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                                } catch let error {
                                    activityVC.dismiss(animated: true, completion: {
                                        let errorAlert = UIAlertController(title: Localizable.errorSavingFile, message: error.localizedDescription, preferredStyle: .alert)
                                        errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                                        self.present(errorAlert, animated: true, completion: nil)
                                    })
                                }
                                
                                collectionView.deselectItem(at: indexPath, animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                activityVC.dismiss(animated: true, completion: {
                                    let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorDownloading, message: Localizable.DirectoryCollectionViewController.checkForPermssions, preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                                    collectionView.deselectItem(at: indexPath, animated: true)
                                })
                            }
                        }
                    }
                })
            }
        }
    }

    // MARK: - Local directory collection view controller delegate
    
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenFile file: URL) {
        
        // Upload local file.
        
        // Go back here
        navigationController?.popToViewController(self, animated: true, completion: {
            self.present(self.upload(file: file), animated: true, completion: nil)
        })
    }
    
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenDirectory directory: URL) {
    localDirectoryCollectionViewController.navigationController?.pushViewController(localDirectoryCollectionViewController, animated: true)
    }
    
    // MARK: - Directory collection view controller delegate
    
    func directoryCollectionViewController(_ directoryCollectionViewController: DirectoryCollectionViewController, didOpenDirectory directory: String) {
        
        // Copy or move remote file.
        
        directoryCollectionViewController.delegate = directoryCollectionViewController
        
        if DirectoryCollectionViewController.action == .copyFile {
            directoryCollectionViewController.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereCopyFile
        }
        
        if DirectoryCollectionViewController.action == .moveFile {
            directoryCollectionViewController.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereMoveFile
        }
        
        navigationController?.pushViewController(directoryCollectionViewController, animated: true, completion: {
            if DirectoryCollectionViewController.action == .copyFile {
                directoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.copyHere, style: .plain, target: directoryCollectionViewController, action: #selector(directoryCollectionViewController.copyFile))], animated: true)
            }
            
            if DirectoryCollectionViewController.action == .moveFile {
                directoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.moveHere, style: .plain, target: directoryCollectionViewController, action: #selector(directoryCollectionViewController.moveFile))], animated: true)
            }
        })
    }
    
    // MARK: - Document picker delegate
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        present(upload(file: url), animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count == 1 && urls[0].startAccessingSecurityScopedResource() {
            documentPicker(controller, didPickDocumentAt: urls[0])
            return
        }
        
        let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.uploadTitle(for: urls.count), message: Localizable.DirectoryCollectionViewController.uploadMessage(for: urls.count, destination: directory.nsString.lastPathComponent), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizable.no, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localizable.yes, style: .default, handler: { (_) in
            var i = 0
            
            /// Upload next file.
            func uploadNext() {
                self.sendFile(file: urls[i], uploadHandler: {
                    i += 1
                    
                    if urls.indices.contains(i) {
                        uploadNext()
                    }
                })
            }
            
            uploadNext()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Collection view drop delegate
        
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        // Move dropped file to destination folder.
        
        guard let sftp = ConnectionManager.shared.filesSession?.sftp else {
            return
        }
        
        for item in coordinator.items {
            if let file = item.dragItem.localObject as? NMSFTPFile {
                // Move file
                
                guard let indexPath = coordinator.destinationIndexPath else {
                    return
                }
                
                guard let files = files else {
                    return
                }
                
                if coordinator.proposal.intent != .insertAtDestinationIndexPath {
                    guard files[indexPath.row].isDirectory || item.dragItem.sourceViewController != self else {
                        return
                    }
                    
                    guard file != files[indexPath.row] else {
                        return
                    }
                }
                
                guard let dirVC = item.dragItem.sourceViewController as? DirectoryCollectionViewController else {
                    return
                }
                
                let target = dirVC.directory.nsString.appendingPathComponent(file.filename)
                let destination: String
                
                if dirVC.directory.removingUnnecessariesSlashes != "/" && files[indexPath.row] == files.last {
                    destination = dirVC.directory.nsString.deletingLastPathComponent.nsString.appendingPathComponent(file.filename)
                } else if dirVC == self {
                    destination = directory.nsString.appendingPathComponent(files[indexPath.row].filename).nsString.appendingPathComponent(file.filename)
                } else if coordinator.proposal.intent == .insertIntoDestinationIndexPath {
                    destination = directory.nsString.appendingPathComponent(files[indexPath.row].filename).nsString.appendingPathComponent(file.filename)
                } else {
                    destination = directory.nsString.appendingPathComponent(file.filename)
                }
                
                if sftp.moveItem(atPath: target, toPath: destination) {
                    _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                        self.reload()
                        if dirVC != self {
                            dirVC.reload()
                        }
                    })
                } else {
                    let errorAlert = UIAlertController(title: Localizable.Browsers.errorMovingFile, message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    present(errorAlert, animated: true, completion: nil)
                }
            } else if item.dragItem.itemProvider.hasItemConformingToTypeIdentifier(item.dragItem.itemProvider.registeredTypeIdentifiers[0]) {
                
                let fileName = item.dragItem.itemProvider.suggestedName
                
                item.dragItem.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: item.dragItem.itemProvider.registeredTypeIdentifiers[0], completionHandler: { (file, inPlace, error) in
                    
                    let destination = self.directory
                    
                    if let error = error {
                        let errorAlert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                    
                    if let file = file {
                        if !inPlace { // Copy file and upload it
                            do {
                                let newFile = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask)[0].appendingPathComponent(fileName ?? file.lastPathComponent)
                                try FileManager.default.copyItem(at: file, to: newFile)
                                DispatchQueue.main.async {
                                    self.sendFile(file: newFile, toDirectory: destination, uploadHandler: {
                                        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                                            self.reload()
                                        })
                                        try? FileManager.default.removeItem(at: newFile)
                                    }, errorHandler: {
                                        let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: Localizable.DirectoryCollectionViewController.errorUploading(file: file.lastPathComponent, to: destination), preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                        try? FileManager.default.removeItem(at: newFile)
                                    }, showAlert: false)
                                }
                            } catch {
                                let errorAlert = UIAlertController(title: Localizable.Browsers.errorCopyingFile, message: error.localizedDescription, preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                                self.present(errorAlert, animated: true, completion: nil)
                            }
                        } else { // Upload file and rename it
                            DispatchQueue.main.async {
                                self.sendFile(file: file, toDirectory: destination, uploadHandler: {
                                    self.reload()
                                }, errorHandler: {
                                    let alert = UIAlertController(title: Localizable.DirectoryCollectionViewController.errorUploadingTitle, message: Localizable.DirectoryCollectionViewController.errorUploading(file: file.lastPathComponent, to: destination), preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                }, showAlert: false)
                            }
                        }
                    }
                })
            }
        }
    }
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        guard let _ = session.localDragSession?.items.first?.localObject as? NMSFTPFile else {
            
            guard let indexPath = destinationIndexPath else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
            }
            
            if let _ = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell {
                if !self.files![indexPath.row].isDirectory && session.items.first?.sourceViewController == self {
                    return UICollectionViewDropProposal(operation: .forbidden, intent: .insertIntoDestinationIndexPath)
                }
            }
            
            return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
        
        guard let indexPath = destinationIndexPath else {
            return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
        }
        
        if session.items.first?.sourceViewController != self {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        
        if let _ = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell {
            if !self.files![indexPath.row].isDirectory {
                return UICollectionViewDropProposal(operation: .forbidden, intent: .insertIntoDestinationIndexPath)
            }
        }
        
        return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
    }
    
    // MARK: - Collection view drag delegate
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell else {
            return []
        }
         
        guard let files = files else {
            return []
        }
         
        guard files.indices.contains(indexPath.row) else {
            return []
        }
         
        let file = files[indexPath.row]
         
        let item = UIDragItem(itemProvider: NSItemProvider(item: nil, typeIdentifier: "remote"))
        item.localObject = file
        item.sourceViewController = self
        item.previewProvider = {
         
            guard let iconView = cell.iconView else {
                return nil
            }
         
            let dragPreview = UIDragPreview(view: iconView)
            dragPreview.parameters.backgroundColor = .clear
         
            return dragPreview
        }
        
        for terminal in ContentViewController.shared.terminalPanels {
            (terminal.contentViewController as? TerminalViewController)?.webView?.removeFromSuperview()
        }
        
        return [item]
    }
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        for terminal in ContentViewController.shared.terminalPanels {
            guard let term = terminal.contentViewController as? TerminalViewController else {
                continue
            }
            term.view.addSubview(term.webView)
        }
    }
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        
        guard let files = files else {
            return false
        }
        
        var hasSFTPFiles = false
        var sftpFiles = [NMSFTPFile]()
        
        for item in session.localDragSession?.items ?? [] {
            if let file = item.localObject as? NMSFTPFile {
                sftpFiles.append(file)
                hasSFTPFiles = true
            }
        }
        
        guard hasSFTPFiles else {
            return (session.hasItemsConforming(toTypeIdentifiers: ["public.item"]))
        }
        
        if directory.removingUnnecessariesSlashes == "/" {
            return true
        } else if let lastFile = files.last {
            return !sftpFiles.contains(lastFile)
        }
        
        return false
    }
    
    // MARK: - Store product view controller delegate
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Panel content delegate
    
    let preferredPanelContentSize = CGSize(width: 320, height: 400)
    
    var minimumPanelContentSize: CGSize {
        return CGSize(width: 240, height: 260)
    }
    
    var maximumPanelContentSize: CGSize {
        return CGSize(width: 500, height: 500)
    }
    
    var preferredPanelPinnedHeight: CGFloat {
        return 400
    }
    
    var preferredPanelPinnedWidth: CGFloat {
        return 400
    }
    
    var shouldAdjustForKeyboard: Bool {
        return false
    }
    
    var closeButtonTitle: String {
        return "×"
    }
    
    var modalCloseButtonTitle: String {
        return "×"
    }
    
    // MARK: - Commit card view
    
    // Thanks to Brian Advent: https://github.com/brianadvent/InteractiveCardViewAnimation
    
    // That code implements the Snippets view on the bottom of the View controller like in the Shortcuts or Maps app.
    
    // That code hasn't been written by me, I don't code like that :)
    
    private enum CardState {
        case expanded
        case collapsed
    }
    
    private var cardViewController: SnippetsViewController!
    private var visualEffectView:UIVisualEffectView!
    
    private var cardHeight: CGFloat {
        return view.frame.height-200
    }
    private let cardHandleAreaHeight: CGFloat = 200
    
    private var cardVisible = false
    private var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted: CGFloat = 0
    
    private var cardSuperView: UIView {
        return view
    }
    
    private func setupCard() {
        
        guard cardViewController == nil, panelNavigationController == nil else {
            return
        }
        
        visualEffectView = UIVisualEffectView()
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        visualEffectView.frame = cardSuperView.frame
        visualEffectView.isUserInteractionEnabled = false
        cardSuperView.addSubview(visualEffectView)
        
        cardViewController = SnippetsViewController.makeViewController(connection: connection, directory: directory)
        cardViewController.expansionHandler = {
            if !self.cardVisible {
                self.animateTransitionIfNeeded(state: .expanded, duration: 0.9)
            }
        }
        cardViewController.collapsionHandler = {
            if self.cardVisible {
                self.animateTransitionIfNeeded(state: .collapsed, duration: 0.9)
            }
        }
        addChild(cardViewController)
        cardSuperView.addSubview(cardViewController.view)
        
        reloadCard()
        
        cardViewController.view.clipsToBounds = true
        cardViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(recognizer:)))
        
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func unsetupCard() {
        guard cardViewController != nil else {
            return
        }
        
        visualEffectView.removeFromSuperview()
        visualEffectView = nil
        
        cardViewController.view.removeFromSuperview()
        cardViewController.removeFromParent()
        cardViewController = nil
        
        cardVisible = false
        runningAnimations = []
        animationProgressWhenInterrupted = 0
    }
    
    private func reloadCard() {
        if !cardVisible {
            cardViewController?.view.frame = CGRect(x: 0, y: cardSuperView.frame.height - cardHandleAreaHeight, width: cardSuperView.bounds.width, height: cardHeight)
        }
    }
    
    @objc private func handleCardTap(recognzier:UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc private func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
        
    }
    
    private func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.cardSuperView.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.cardSuperView.frame.height - self.cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    private func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    private func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    private func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
    // MARK: - Navigation controller delegate
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController != self {
            unsetupCard()
        } else {
            view.setNeedsLayout()
            setupCard()
        }
    }
    
    // MARK: - Static
    
    /// Action to do.
    static var action = DirectoryAction.none
    
    /// Grid layout.
    static var gridLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        return layout
    }
    
    /// List layout.
    static func listLayout(forView view: UIView) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width, height: 50)
        return layout
    }
}

