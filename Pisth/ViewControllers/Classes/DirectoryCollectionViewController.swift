// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import GoogleMobileAds
import NMSSH
import Pisth_Shared
import Firebase
import CoreData
import Pisth_API
import StoreKit
import PanelKit
import CoreSpotlight

/// Collection view controller to manage remote files.
class DirectoryCollectionViewController: UICollectionViewController, LocalDirectoryCollectionViewControllerDelegate, DirectoryCollectionViewControllerDelegate, GADBannerViewDelegate, UIDocumentPickerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, SKStoreProductViewControllerDelegate, PanelContentDelegate {
    
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
    
    /// Ad banner view displayed at top of table view.
    var bannerView: GADBannerView!
    
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
        
        footerView = bannerView
        
        let activityVC = ActivityViewController(message: "Loading...")
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
        
        let fileInfoVC = UIViewController.fileInfo
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
        if UserDefaults.standard.bool(forKey: "list") {
            layout = DirectoryCollectionViewController.listLayout(forView: view)
        } else {
            layout = DirectoryCollectionViewController.gridLayout
        }
        if let currentLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = currentLayout.footerReferenceSize
            layout.headerReferenceSize = currentLayout.headerReferenceSize
        }
        collectionView?.reloadData()
        collectionView?.setCollectionViewLayout(layout, animated: true)
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
    
    /// Setup views.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-RemoteFileBrowser", AnalyticsParameterItemName : "Remote File Browser"])
        
        var files = ConnectionManager.shared.files(inDirectory: self.directory, showHiddenFiles: true)
        self.allFiles = files
        if !UserDefaults.standard.bool(forKey: "hidden") {
            for file in files ?? [] {
                if file.filename.hasPrefix(".") {
                    guard let i = files?.index(of: file) else { break }
                    files?.remove(at: i)
                }
            }
        }
        self.files = files
        
        guard self.files != nil else {
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
        
        navigationItem.largeTitleDisplayMode = .never
        
        // TableView cells
        collectionView?.register(UINib(nibName: "Grid File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileGrid")
        collectionView?.register(UINib(nibName: "List File Cell", bundle: Bundle.main), forCellWithReuseIdentifier: "fileList")
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
        clearsSelectionOnViewWillAppear = false
        collectionView?.dropDelegate = self
        collectionView?.dragDelegate = self
        collectionView?.dragInteractionEnabled = true
        collectionView?.backgroundColor = .white
        
        // Header
        let header = UIView.browserHeader
        headerView = header
        header.createNewFolder = { _ in // Create folder
            let chooseName = UIAlertController(title: "Create folder", message: "Choose new folder name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New folder name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error creating directory!", message: nil, preferredStyle: .alert)
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
        
        // Initialize the refresh control.
        collectionView?.refreshControl = UIRefreshControl()
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
        
        // Banner ad
        if !UserDefaults.standard.bool(forKey: "terminalThemesPurchased") {
            bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.rootViewController = self
            bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
            bannerView.delegate = self
            bannerView.load(GADRequest())
        }
        
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
                attributes.thumbnailData = UIImagePNGRepresentation(logo)
            }
        } else {
            attributes.thumbnailData = UIImagePNGRepresentation(#imageLiteral(resourceName: "File icons/folder"))
        }
        attributes.addedDate = Date()
        attributes.contentDescription = "sftp://\(connection.username)@\(connection.host):\(connection.port)\(directory)"
        activity.contentAttributeSet = attributes
        
        self.userActivity = activity
    }
    
    /// Show errors if there are and setup Notification center to call this function when Application becomes active.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showErrorBannerIfItsNeeded), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Toolbar
        setToolbarItems([UIBarButtonItem(title:"/", style: .plain, target: self, action: #selector(goToRoot)), UIBarButtonItem(image: #imageLiteral(resourceName: "home"), style: .plain, target: self, action: #selector(goToHome)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), AppDelegate.shared.showBookmarksBarButtonItem], animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        
        // Connection errors
        showErrorIfThereIsOne()
    }

    /// Hides toolbar.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.setToolbarHidden(true, animated: true)
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Resize layout.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout, layout.itemSize.width == view.frame.width {
            layout.itemSize.width = size.width
        }
    }
    
    /// Set user info.
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
                    let alert = UIAlertController(title: "Error opening directory!", message: "Check for permissions.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
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
        
        headerView = view
        
        collectionView?.setContentOffset(CGPoint(x: 0, y: 0-view.frame.height), animated: true)
    }
    
    /// Go back and show error.
    func showError() {
        
        let navVC = AppDelegate.shared.navigationController
        
        guard navVC.visibleViewController == self else {
            return
        }
        
        let result = ConnectionManager.shared.result
        
        var alert: UIAlertController!
        switch result {
        case .notConnected:
            alert = UIAlertController(title: "Error opening session!", message: "Unable to connect, check for your internet connection and the IP address or hostname.\nIf you can't connect with the IP address, try with the hostname.", preferredStyle: .alert)
        case .connected:
            alert = UIAlertController(title: "Error opening session!", message: "Unable to authenticate, check for username and password.", preferredStyle: .alert)
        default:
            alert = UIAlertController(title: "Connection was closed!", message: "An error with the connection occurred.", preferredStyle: .alert)
        }
                
        if alert != nil {
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                AppDelegate.shared.splitViewController.navigationController_.popToRootViewController(animated: true)
                AppDelegate.shared.splitViewController.detailNavigationController.popToRootViewController(animated: true)
            }))
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Check for connection errors and run handler if there is an error.
    func checkForConnectionError(errorHandler: @escaping () -> Void, successHandler: (() -> Void)? = nil) {
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
            
            let activityVC = ActivityViewController(message: "Loading")
            self.present(activityVC, animated: true, completion: {
                let dirVC = DirectoryCollectionViewController(connection: self.connection, directory: directory)
                if let delegate = self.delegate {
                    activityVC.dismiss(animated: true, completion: {
                        
                        delegate.directoryCollectionViewController(dirVC, didOpenDirectory: directory)
                    })
                } else {
                    activityVC.dismiss(animated: true, completion: {
                        
                        self.navigationController?.pushViewController(dirVC, animated: true)
                    })
                }
            })
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
        let navVC = UIViewController.gitNavigationController
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
        if !UserDefaults.standard.bool(forKey: "hidden") {
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
    ///     - directory: Directory where upload files, default is current directory.
    ///     - uploadHandler: Code to execute after uploading file, nil by default.
    ///     - errorHandler: Code to execute after the upload failed.
    ///     - showAlert: If show uploading alert.
    ///
    /// - Returns: `false` if upload failed, always returns `true` if `showAlert` is `true`.
    @discardableResult func sendFile(file: URL, toDirectory path: String? = nil, uploadHandler: (() -> Void)? = nil, errorHandler: (() -> Void)? = nil, showAlert: Bool = true) -> Bool {
        
        var directory: String!
        if path == nil {
            directory = self.directory
        } else {
            directory = path
        }
        
        let activityVC = ActivityViewController(message: "Uploading")
        
        /// Upload file with given parameters of parent function.
        ///
        /// - Returns: `false` if upload failed.
        func upload() -> Bool {
            do {
                let dataToSend = try Data(contentsOf: file)
                
                /// Show error or run error handler.
                func showError_() {
                    if let handler = errorHandler {
                        handler()
                    } else {
                        let alert = UIAlertController(title: "Error uploading file!", message: "An error occurred uploading file.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
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
                
                guard let result = ConnectionManager.shared.filesSession?.sftp.writeContents(dataToSend, toFileAtPath: directory.nsString.appendingPathComponent(file.lastPathComponent)) else {
                    
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
                            let alert = UIAlertController(title: "Error uploading file!", message: "An error occurred uploading file.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
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
                    let errorAlert = UIAlertController(title: "Error reading file data!", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                        
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
        let confirmAlert = UIAlertController(title: file.lastPathComponent, message: "Do you want to send \(file.lastPathComponent) to \(directory.nsString.lastPathComponent)?", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
            
            if let handler = uploadHandler {
                handler()
            }
            
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
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
                let alert = UIAlertController(title: "Error uploading file!", message: "An error occurred uploading file.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
                    if let handler = uploadHandler {
                        handler()
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            if isItemDirectory(file) { // Upload directory
                
                let activityVC = ActivityViewController(message: "Uploading")
                
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
        
        chooseAlert.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in // Upload file from browser
            let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            picker.allowsMultipleSelection = true
            picker.delegate = self
            
            self.present(picker, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Import from Pisth", style: .default, handler: { (_) in // Upload file from Pisth
            let localDirVC = LocalDirectoryCollectionViewController(directory: FileManager.default.documents)
            localDirVC.delegate = self
            
            self.navigationController?.pushViewController(localDirVC, animated: true)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Create blank file", style: .default, handler: { (_) in // Create file
            
            let chooseName = UIAlertController(title: "Create blank file", message: "Choose new file name", preferredStyle: .alert)
            chooseName.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
            })
            chooseName.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            chooseName.addAction(UIAlertAction(title: "Create", style: .default, handler: { (_) in
                
                let newPath = self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)
                
                guard let result = ConnectionManager.shared.filesSession?.sftp.writeFile(atPath: Bundle.main.path(forResource: "empty", ofType: nil), toFileAtPath: newPath) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error creating file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
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
                guard let result = ConnectionManager.shared.filesSession?.sftp.createDirectory(atPath: self.directory.nsString.appendingPathComponent(chooseName.textFields![0].text!)) else { return }
                
                if !result {
                    let errorAlert = UIAlertController(title: "Error creating directory!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
                }
                
                self.reload()
            }))
            
            self.present(chooseName, animated: true, completion: nil)
        }))
        
        chooseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
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
            
            let progress = UIAlertController(title: "Copying...", message: "\n\n", preferredStyle: .alert)
            
            var continue_ = true
            
            progress.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
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
                            let errorAlert = UIAlertController(title: "Error copying file!", message: nil, preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
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
                let errorAlert = UIAlertController(title: "Error moving file!", message: nil, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(errorAlert, animated: true, completion: nil)
            }
                
            Pasteboard.local.filePath = nil
        })
    }
    
    // MARK: - Collection view data source
    
    /// - Returns: count of `files`.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let files = files {
            return files.count
        }
        
        return 0
    }
    
    /// - Returns: A `FileCollectionViewCell` with title as current file name and with icon for current file.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell: FileCollectionViewCell
        if UserDefaults.standard.bool(forKey: "list") {
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
    
    /// - Returns: Enable copying for files but not directories.
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if files![indexPath.row].isDirectory {
            return false
        }
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:))) // Enable copy
    }
    
    /// - Returns: `true`.
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Copy selected file.
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == #selector(copy(_:)) { // Copy file
            
            Pasteboard.local.filePath = directory.nsString.appendingPathComponent(files![indexPath.row].filename)
            
            let dirVC = DirectoryCollectionViewController(connection: connection, directory: directory)
            dirVC.navigationItem.prompt = "Select a directory where copy file"
            dirVC.delegate = dirVC
            DirectoryCollectionViewController.action = .copyFile
            
            
            let navVC = UINavigationController(rootViewController: dirVC)
            present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: dirVC, action: #selector(dirVC.copyFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    /// - Returns: An header view containing `headerView`.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
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
    
    /// Open selected file or directory.
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
                
                let activityVC = ActivityViewController(message: "Loading")
                self.present(activityVC, animated: true, completion: {
                    let dirVC = DirectoryCollectionViewController(connection: self.connection, directory: path)
                    if let delegate = self.delegate {
                        activityVC.dismiss(animated: true, completion: {
                            
                            delegate.directoryCollectionViewController(dirVC, didOpenDirectory: path)
                            
                            collectionView.deselectItem(at: indexPath, animated: true)
                        })
                    } else {
                        activityVC.dismiss(animated: true, completion: {
                            
                            self.navigationController?.pushViewController(dirVC, animated: true)
                            
                            collectionView.deselectItem(at: indexPath, animated: true)
                        })
                    }
                })
            } else { // Download file
                
                let activityVC = UIAlertController(title: "Downloading...", message: "\n\n", preferredStyle: .alert)
                activityVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
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
                                } catch let error {
                                    activityVC.dismiss(animated: true, completion: {
                                        let errorAlert = UIAlertController(title: "Error saving file!", message: error.localizedDescription, preferredStyle: .alert)
                                        errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(errorAlert, animated: true, completion: nil)
                                    })
                                }
                                
                                collectionView.deselectItem(at: indexPath, animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                activityVC.dismiss(animated: true, completion: {
                                    let alert = UIAlertController(title: "Error downloading file!", message: "Check for permissions.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
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
    
    /// Upload local file.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenFile file: URL) {
        
        // Go back here
        navigationController?.popToViewController(self, animated: true, completion: {
            self.present(self.upload(file: file), animated: true, completion: nil)
        })
    }
    
    /// Open directory.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenDirectory directory: URL) {
    localDirectoryCollectionViewController.navigationController?.pushViewController(localDirectoryCollectionViewController, animated: true)
    }
    
    // MARK: - Directory collection view controller delegate
    
    /// Copy or move remote file.
    func directoryCollectionViewController(_ directoryCollectionViewController: DirectoryCollectionViewController, didOpenDirectory directory: String) {
        directoryCollectionViewController.delegate = directoryCollectionViewController
        
        if DirectoryCollectionViewController.action == .copyFile {
            directoryCollectionViewController.navigationItem.prompt = "Select a directory where copy file"
        }
        
        if DirectoryCollectionViewController.action == .moveFile {
            directoryCollectionViewController.navigationItem.prompt = "Select a directory where move file"
        }
        
        navigationController?.pushViewController(directoryCollectionViewController, animated: true, completion: {
            if DirectoryCollectionViewController.action == .copyFile {
                directoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Copy here", style: .plain, target: directoryCollectionViewController, action: #selector(directoryCollectionViewController.copyFile))], animated: true)
            }
            
            if DirectoryCollectionViewController.action == .moveFile {
                directoryCollectionViewController.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: directoryCollectionViewController, action: #selector(directoryCollectionViewController.moveFile))], animated: true)
            }
        })
    }
    
    // MARK: - Banner view delegate
    
    /// Show ad when it's received.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        footerView = bannerView
    }
    
    // MARK: - Document picker delegate
    
    /// Dismiss browser.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    /// Send selected file.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        present(upload(file: url), animated: true, completion: nil)
    }
    
    /// Send selected files.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count == 1 {
            documentPicker(controller, didPickDocumentAt: urls[0])
            return
        }
        
        let alert = UIAlertController(title: "Upload \(urls.count) files?", message: "Do you want to upload \(urls.count) files to \(directory.nsString.lastPathComponent)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
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
        
    /// Move dropped file to destination folder.
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
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
                    let errorAlert = UIAlertController(title: "Error moving file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(errorAlert, animated: true, completion: nil)
                }
            } else if item.dragItem.itemProvider.hasItemConformingToTypeIdentifier(item.dragItem.itemProvider.registeredTypeIdentifiers[0]) {
                
                let fileName = item.dragItem.itemProvider.suggestedName
                
                item.dragItem.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: item.dragItem.itemProvider.registeredTypeIdentifiers[0], completionHandler: { (file, inPlace, error) in
                    
                    let destination = self.directory
                    
                    if let error = error {
                        let errorAlert = UIAlertController(title: "Error uploading file!", message: error.localizedDescription, preferredStyle: .alert)
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
                                        let alert = UIAlertController(title: "Error uploading file!", message: "Error uploading \(file.lastPathComponent) to \(destination).", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                        try? FileManager.default.removeItem(at: newFile)
                                    }, showAlert: false)
                                }
                            } catch {
                                let errorAlert = UIAlertController(title: "Error copying file!", message: error.localizedDescription, preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                                self.present(errorAlert, animated: true, completion: nil)
                            }
                        } else { // Upload file and rename it
                            DispatchQueue.main.async {
                                self.sendFile(file: file, toDirectory: destination, uploadHandler: {
                                    self.reload()
                                }, errorHandler: {
                                    let alert = UIAlertController(title: "Error uploading file!", message: "Error uploading \(file.lastPathComponent) to \(destination).", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                }, showAlert: false)
                            }
                        }
                    }
                })
            }
        }
    }
    
    /// Set animation for moving files into a directory.
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
    
    /// Start dragging file.
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
         
        return [item]
    }
    
    /// Allow dragging only if the selected file is not the parent directory.
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
    
    /// Dismiss.
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Panel content delegate
    
    /// Returns `CGSize(width: 320, height: 400)`.
    let preferredPanelContentSize = CGSize(width: 320, height: 400)
    
    /// Returns `CGSize(width: 240, height: 260)`.
    var minimumPanelContentSize: CGSize {
        return CGSize(width: 240, height: 260)
    }
    
    /// Returns `CGSize(width: 500, height: 500)`.
    var maximumPanelContentSize: CGSize {
        return CGSize(width: 500, height: 500)
    }
    
    /// Returns: `320`.
    var preferredPanelPinnedHeight: CGFloat {
        return 400
    }
    
    /// Returns: `400`.
    var preferredPanelPinnedWidth: CGFloat {
        return 400
    }
    
    /// Returns `false`.
    var shouldAdjustForKeyboard: Bool {
        return false
    }
    
    private var gestureRecognizerTimer: Timer?
    
    /// Disable `AppDelegate.shared.splitViewController`'s gesture while dragging.
    func panelDragGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        AppDelegate.shared.splitViewController.presentsWithGesture = false
        
        gestureRecognizerTimer?.invalidate()
        
        gestureRecognizerTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            AppDelegate.shared.splitViewController.presentsWithGesture = true
        })
        
        return true
    }
    
    // MARK: - Static
    
    /// Action to do.
    static var action = DirectoryAction.none
    
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
}

