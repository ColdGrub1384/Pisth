// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import WebKit
import MultipeerConnectivity
import BiometricAuthentication
import Pisth_Shared
import Pisth_Terminal
import Firebase
import AVFoundation
import CoreData

/// Terminal used to do SSH.
class TerminalViewController: UIViewController, NMSSHChannelDelegate, WKNavigationDelegate, WKUIDelegate, UIKeyInput, UITextInputTraits, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, UIGestureRecognizerDelegate, UIDropInteractionDelegate {
    
    /// Terminal size in this format: `"0,0"`.
    private var terminalSize: String?
        
    /// If the terminal is in viewer mode.
    var viewer = false
    
    /// Directory to open.
    var pwd: String?
    
    /// Content of console.
    var console = ""
    
    /// Command to run at starting.
    var command: String?
    
    /// Ctrl key button.
    var ctrlKey: UIButton!
    
    /// Accessory view used in keyboard.
    var accessoryView: UIView!
    
    /// Toolbar used in keyboard.
    var toolbar: UIToolbar!
    
    /// Don't scroll when console's content changes.
    var dontScroll = false
    
    /// Send Ctrl key.
    private var ctrl_ = false
    
    /// Send Ctrl key.
    var ctrl: Bool {
        set {
            ctrl_ = newValue
            if self.ctrl_ {
                ctrlKey.setTitleColor(.lightGray, for: .normal)
            } else {
                if TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth"]?.toolbarStyle == .default {
                    ctrlKey.setTitleColor(.black, for: .normal)
                } else {
                    ctrlKey.setTitleColor(.white, for: .normal)
                }
            }
        }
        
        get {
            return ctrl_
        }
    }
    
    /// Is terminal read only.
    var readOnly = false
    
    /// Web view used to display content.
    var webView: WKWebView!
    
    /// Text view with plain output
    var selectionTextView: UITextView!
    
    /// If true, all addtional commands will not be executed and the shell with be launched 'purely'.
    var pureMode = false
    
    /// Select text after loading terminal and put text in `selectionTextView`.
    var selectText = false
    
    /// Ignored notifications name strings.
    /// When a the function linked with a notification listed here, the function will remove the given notification from this array and will return.
    private var ignoredNotifications = [Notification.Name]()
    
    /// Variable used to delay a long press of the arrow keys.
    private var arrowsLongPressDelay = 2
    
    /// Show commands history.
    ///
    /// - Parameters:
    ///     - sender: Sender Bar button item.
    @objc func showHistory(_ sender: UIBarButtonItem) {
        
        do {
            guard let session = ConnectionManager.shared.filesSession else { return }
            let history = try session.channel.execute("cat .pisth_history").components(separatedBy: "\n")
            
            let commandsVC = CommandsTableViewController()
            commandsVC.title = "History"
            commandsVC.commands = history
            commandsVC.modalPresentationStyle = .popover
            
            if let popover = commandsVC.popoverPresentationController {
                popover.barButtonItem = sender
                popover.delegate = commandsVC
                
                self.present(commandsVC, animated: true, completion: {
                    commandsVC.tableView.scrollToRow(at: IndexPath(row: history.count-1, section: 0), at: .bottom, animated: true)
                })
            }
        } catch {
            print("Error sending command: \(error.localizedDescription)")
        }
    }
    
    /// Change terminal size to page size.
    ///
    /// - Parameters:
    ///     - completion: Function to call after resizing terminal.
    func changeSize(completion: (() -> Void)?) {
        
        var cols_: Any?
        var rows_: Any?
        
        func apply() {
            guard let cols = cols_ as? UInt else { return }
            guard let rows = rows_ as? UInt else { return }
            print(cols)
            print(rows)
            self.terminalSize = "\(cols),\(rows)"
            ConnectionManager.shared.session?.channel.requestSizeWidth(cols, height: rows)
        }
        
        // Get and set columns
        webView.evaluateJavaScript("term.cols") { (cols, error) in
            
            if let cols = cols {
                cols_ = cols
            }
            
            // Get and set rows
            self.webView.evaluateJavaScript("term.rows") { (rows, error) in
                if let rows = rows {
                    rows_ = rows
                    
                    apply()
                    if let completion = completion {
                        completion()
                    }
                }
            }
        }
    }
    
    /// Add keyboard's toolbar.
    @objc func addToolbar() {
        guard let theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth"] else {
            return
        }
        
        var toolbar: UIToolbar
        
        if theme.toolbarStyle == .default {
            toolbar = UIView.whiteTerminalToolbar
        } else {
            toolbar = UIView.blackTerminalToolbar
        }
        
        enum ItemsTag: Int {
            case finger = 1
            case ctrl = 2
            case esc = 3
            case more = 4
            case hideKeyboard = 5
            case back = 6
        }
        
        for item in toolbar.items ?? [] {
            
            switch item.tag {
            case ItemsTag.back.rawValue:
                item.target = navigationController
                item.action = #selector(navigationController?.popViewController(animated:))
            case ItemsTag.more.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(toggleSecondToolbar(_:)), for: .touchUpInside)
            case ItemsTag.finger.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(sendArrows(_:)), for: .touchUpInside)
            case ItemsTag.hideKeyboard.rawValue:
                item.target = self
                item.action = #selector(resignFirstResponder)
            default:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(insertKey(_:)), for: .touchUpInside)
                if item.tag == ItemsTag.ctrl.rawValue {
                    self.ctrlKey = (item.customView as? UIButton)
                    
                    if self.ctrl {
                        ctrlKey.setTitleColor(.lightGray, for: .normal)
                    }
                }
            }
        }
        
        self.accessoryView = toolbar
        self.toolbar = toolbar
    }
    
    /// Show or hide the first toolbar of the keyboard.
    ///
    /// - Parameters:
    ///     - sender: Sender button.
    @objc func toggleFirstToolbar(_ sender: UIButton) {
        addToolbar()
        reloadInputViews()
    }
    
    /// Show or hide the second toolbar of the keyboard.
    ///
    /// - Parameters:
    ///     - sender: Sender button.
    @objc func toggleSecondToolbar(_ sender: UIButton) {
        guard let theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pro"] else {
            return
        }
        
        var toolbar: UIToolbar
        
        if theme.toolbarStyle == .default {
            toolbar = UIView.secondWhiteTerminalToolbar
        } else {
            toolbar = UIView.secondBlackTerminalToolbar
        }
                
        enum ItemsTag: Int {
            case more = 1
            case fKeys = 2
            case arrowRight = 3
            case arrowDown = 4
            case arrowUp = 5
            case arrowLeft = 6
            case sendPassword = 7
        }
        
        for item in toolbar.items ?? [] {
            
            switch item.tag {
            case ItemsTag.more.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(toggleFirstToolbar(_:)), for: .touchUpInside)
            case ItemsTag.fKeys.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(insertKey(_:)), for: .touchUpInside)
            case ItemsTag.arrowLeft.rawValue, ItemsTag.arrowUp.rawValue, ItemsTag.arrowDown.rawValue, ItemsTag.arrowRight.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(insertKey(_:)), for: .touchUpInside)
                
                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(insertKeyByLongPress(_:)))
                (item.customView as? UIButton)?.addGestureRecognizer(longPressRecognizer)
            case ItemsTag.sendPassword.rawValue:
                (item.customView as? UIButton)?.addTarget(self, action: #selector(sendPassword), for: .touchUpInside)
            default:
                break
            }
        }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: toolbar.frame.height))
        
        view.addSubview(toolbar)
        
        toolbar.frame.size.width = view.frame.width
        toolbar.autoresizingMask = [.flexibleWidth]
        
        self.toolbar = toolbar
        accessoryView = view
        
        reloadInputViews()
        
        
        if !self.view.safeAreaLayoutGuide.layoutFrame.contains(toolbar.convert(toolbar.frame, to: self.view)) {
            toolbar.frame.origin.y = view.safeAreaLayoutGuide.layoutFrame.height-toolbar.frame.height
        } else {
            toolbar.frame.origin.y = 0
        }
    }
    
    /// Show plain output and allow selection.
    ///
    /// - Parameters:
    ///     - sender: Sender Bar button item
    @objc func selectionMode(_ sender: UIBarButtonItem) {
        selectionTextView.isHidden = selectionTextView.isHidden.inverted
        
        if !selectionTextView.isHidden {
            
            toolbar.items![1].tintColor = .white
            toolbarItems![1].tintColor = .white
            
            reload()
            selectText = true
            
            resignFirstResponder()
        } else {
            
            toolbar.items![1].tintColor = toolbar.tintColor
            toolbarItems![1].tintColor = view.tintColor
            
            becomeFirstResponder()
        }
    }
    
    /// Send clipboard.
    @objc func pasteText() {
        if isFirstResponder {
            insertText(UIPasteboard.general.string ?? "")
        }
    }
    
    /// Send user password.
    @objc func sendPassword() {
        if isFirstResponder {
            
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "Authenticate to send '\(ConnectionManager.shared.connection?.username ?? "user")' password.", fallbackTitle: "", cancelTitle: nil, success: {
                
                self.insertText(ConnectionManager.shared.connection?.password ?? "")
                
            }, failure: { (error) in
                
                if error == .biometryNotEnrolled || error == .passcodeNotSet || error == .biometryNotAvailable {
                    self.insertText(ConnectionManager.shared.connection?.password ?? "")
                }
            })
        }
    }
    
    /// Hide or show navigation bar.
    @objc func showNavBar() {
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden.inverted ?? true, animated: true)
        reload()
    }
    
    /// Enter in selection mode or paste text.
    @objc func showActions(_ sender: UIBarButtonItem) {
        var actions = [UIAlertAction]()
        
        if !selectionTextView.isHidden {
            actions.append(UIAlertAction(title: "Insert mode", style: .default, handler: { (_) in
                self.selectionTextView.isHidden = true
                
                self.becomeFirstResponder()
            }))
        } else {
            actions.append(UIAlertAction(title: "Selection mode", style: .default, handler: { (_) in
                self.selectionTextView.isHidden = false
                
                self.selectText = true
                
                self.resignFirstResponder()
            }))
        }
        
        actions.append(UIAlertAction(title: "Paste", style: .default, handler: { (_) in
            self.insertText(UIPasteboard.general.string ?? "")
        }))
        
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let alert = UIAlertController(title: "Select action", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        for action in actions {
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Show or hide keyboard.
    ///
    /// - Parameters:
    ///     - sender: Sende bar button item.
    @objc func toggleKeyboard(_ sender: UIBarButtonItem) {
        if isFirstResponder {
            resignFirstResponder()
            sender.image = #imageLiteral(resourceName: "show-keyboard")
        } else {
            becomeFirstResponder()
            sender.image = #imageLiteral(resourceName: "hide-keyboard")
        }
    }
    
    /// Play bell.
    @objc func bell() {
        AudioServicesPlayAlertSound(1054)
    }
    
    /// Reload terminal with animation.
    @objc func reload() {
        
        let view = UIVisualEffectView(frame: webView.frame)
        
        if keyboardAppearance == .dark {
            view.effect = UIBlurEffect(style: .dark)
        } else {
            view.effect = UIBlurEffect(style: .light)
        }
        
        view.alpha = 0
        view.tag = 5
        
        self.view.addSubview(view)
        
        webView.reload()
        
        UIView.animate(withDuration: 0.5) {
            view.alpha = 1
        }
    }
    
    /// Resize `webView`, dismiss and open keyboard (to resize terminal).
    func resizeView(withSize size: CGSize) {
        let wasFirstResponder = isFirstResponder
        
        if isFirstResponder {
            resignFirstResponder()
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            if wasFirstResponder {
                self.becomeFirstResponder()
            }
        })
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            let newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.webView.frame = newFrame
            self.selectionTextView.frame = newFrame
            if !wasFirstResponder {
                self.reload()
            }
        })
    }
    
    // MARK: - View controller
    
    /// `UIViewController`'s `canBecomeFirstResponder` variable.
    ///
    /// Returns if `webView is different than nil`.
    override var canBecomeFirstResponder: Bool {
        return (webView != nil && !readOnly)
    }

    /// `UIViewController`'s `canResignFirstResponder` variable.
    ///
    /// Returns `true`.
    override var canResignFirstResponder: Bool {
        return true
    }
    
    /// `UIViewController`'s `inputAccessoryView` variable.
    ///
    /// Returns `toolbar`.
    override var inputAccessoryView: UIView? {
        
        if !isFirstResponder {
            return nil
        }
        
        return accessoryView
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        resizeView(withSize: size)
    }
    
    /// Returns arrow keys, esc keys and ctrl keys from `A` to `_`.
    override var keyCommands: [UIKeyCommand]? {
        // Bluetooth keyboard
        
        var commands =  [
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(pasteText), discoverabilityTitle: "Paste text"),
            UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Up Arrow"),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Down Arrow"),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Left Arrow"),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Right Arrow"),
            UIKeyCommand(input: UIKeyInputEscape, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Esc key"),
        ]
        
        let ctrlKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_"] // All CTRL keys
        for ctrlKey in ctrlKeys {
            commands.append(UIKeyCommand(input: ctrlKey, modifierFlags: .control, action: #selector(write(fromCommand:)), discoverabilityTitle: "Send ^\(ctrlKey)"))
        }
        
        return commands
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        resizeView(withSize: view.frame.size)
    }
    
    /// Add notifications to resize `webView` when keyboard appears and setup multipeer connectivity.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-Terminal", AnalyticsParameterItemName : "Terminal"])
        
        navigationController?.navigationBar.isTranslucent = false
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showActions(_:))), UIBarButtonItem(image: #imageLiteral(resourceName: "hide-keyboard"), style: .plain, target: self, action: #selector(toggleKeyboard(_:)))]
        
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        
        let theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth"] ?? PisthTheme()
        navigationController?.navigationBar.barStyle = theme.toolbarStyle
        
        // Resize webView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        // Setup connectivity
        if peerID == nil {
            peerID = MCPeerID(displayName: UIDevice.current.name)
        }
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "terminal")
        mcNearbyServiceAdvertiser.delegate = self
        if !viewer {
            mcNearbyServiceAdvertiser.startAdvertisingPeer()
        }
        
        // Create WebView
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = .video
        webView = TerminalWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), configuration: config)
        webView.accessibilityIgnoresInvertColors = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isOpaque = false
        view.addSubview(webView)
        webView.backgroundColor = .clear
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.loadFileURL(Bundle.terminal.bundleURL.appendingPathComponent("terminal.html"), allowingReadAccessTo: URL(string:"file:///")!)
        view.addInteraction(UIDropInteraction(delegate: self))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showNavBar))
        tapGesture.delegate = self
        webView.addGestureRecognizer(tapGesture)
        
        // Create selection Textview
        selectionTextView = UITextView(frame: webView.frame)
        selectionTextView.isHidden = true
        selectionTextView.font = UIFont(name: "Courier", size: 15)
        selectionTextView.isEditable = false
        view.addSubview(selectionTextView)
        
        if readOnly {
            toolbarItems?.remove(at: 1)
        }
    }
    
    /// Close and open shell, add `toolbar` to keyboard and configure `navigationController`.
    override func viewWillAppear(_ animated: Bool) {
        
        edgesForExtendedLayout = []
        
        if console.isEmpty {
            
            if !pureMode {
                ConnectionManager.shared.session?.channel.closeShell()
                try? ConnectionManager.shared.session?.channel.startShell()
            }
            
            navigationItem.largeTitleDisplayMode = .never
            
            addToolbar()
        }
    }
    
    /// Undo changes made to `navigationController`, dismiss `ArrowsViewController` if it's presented and stop multipeer connectivity session.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.isTranslucent = true
        
        mcNearbyServiceAdvertiser.stopAdvertisingPeer()
    }
    
    /// Open a `DirectoryTableViewController` at the side
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        if !AppDelegate.shared.splitViewController.isCollapsed && navigationController != AppDelegate.shared.splitViewController.navigationController_ {
            
            if let i = navigationController?.viewControllers.index(of: self) {
                guard let vcs = navigationController?.viewControllers else {
                    return
                }
                
                guard vcs.indices.contains(i-1) else {
                    return
                }
                
                guard let dirVC = vcs[i-1] as? DirectoryTableViewController else {
                    return
                }
                
                if (AppDelegate.shared.splitViewController.navigationController_.visibleViewController as? DirectoryTableViewController)?.directory != dirVC.directory && AppDelegate.shared.splitViewController.displayMode == .allVisible {
                    AppDelegate.shared.splitViewController.navigationController_.pushViewController(DirectoryTableViewController(connection: dirVC.connection, directory: dirVC.directory), animated: true)
                }                
            }
        }
    }
    
    /// - Returns: `true`.
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden ?? true
    }
    
    // MARK: - Keyboard
    
    /// Resize `webView` when keyboard is shown.
    @objc func keyboardDidShow(_ notification:Notification) {
        
        guard !ignoredNotifications.contains(notification.name) else {
            if let i = ignoredNotifications.index(of: notification.name) {
                ignoredNotifications.remove(at: i)
            }
            return
        }
        
        if UIApplication.shared.keyWindow?.frame.size == UIScreen.main.bounds.size {
            let toolbarFrame = toolbar.convert(toolbar.frame, to: view)
            
            let newHeight = toolbarFrame.origin.y
            if webView.frame.height != newHeight {
                webView.frame.size.height = newHeight
                reload()
            }
        } else if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            webView.frame.size = CGSize(width: view.frame.width, height: view.frame.height-keyboardFrame.height)
            reload()
        }
        
        if let arrowsVC = ArrowsViewController.current {
            arrowsVC.view.frame = webView.frame
        }
            
        selectionTextView.frame = webView.frame
    }
    
    /// Resize `webView` when keyboard is hidden.
    @objc func keyboardDidHide(_ notification:Notification) {
        
        guard !ignoredNotifications.contains(notification.name) else {
            if let i = ignoredNotifications.index(of: notification.name) {
                ignoredNotifications.remove(at: i)
            }
            return
        }
        
        webView.frame = view.bounds
        reload()
        
        if let arrowsVC = ArrowsViewController.current {
            arrowsVC.view.frame = webView.frame
        }
        
        selectionTextView.frame = webView.frame
    }
    
    /// Enable or disable swiping to send arrow keys.
    ///
    /// - Parameters:
    ///     - sender: Sender button. If its tint color is white, this function will enable swiping and set its tint color to white, and if its tint color is gray, this function will disable swiping and set its tint color to blue.
    @objc func sendArrows(_ sender: UIButton) {
        
        if sender.tintColor != .lightGray {
            let arrowsVC = ArrowsViewController()
            
            view.addSubview(arrowsVC.view)
            arrowsVC.view.frame = webView.frame
            
            arrowsVC.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showNavBar)))
            
            sender.tintColor = .lightGray
        } else {
            
            sender.isEnabled = false
            
            ArrowsViewController.current?.helpLabel.isHidden = false
            ArrowsViewController.current?.helpLabel.alpha = 1
            ArrowsViewController.current?.helpLabel.text = "Scroll to\ngo down /\ngo up."
            
            for recognizer in ArrowsViewController.current!.view.gestureRecognizers! {
                recognizer.isEnabled = false
            }
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut, animations: {
                    ArrowsViewController.current?.helpLabel.alpha = 0
                }, completion: { _ in
                    ArrowsViewController.current?.helpLabel.isHidden = true
                    
                    ArrowsViewController.current?.view.removeFromSuperview()
                    
                    sender.isEnabled = true
                })
            })
            
            sender.tintColor = .white
        }
    }
    
    /// Insert special key.
    ///
    /// - Parameters:
    ///     - sender: Sender bar button item.
    @objc func insertKey(_ sender: UIButton) {
        
        if sender.tag == 1 { // ctrl
            ctrl = ctrl.inverted
        } else if sender.tag == 6 { // Esc
            insertText(Keys.esc)
        } else if sender.tag == 7 { // F keys
            let commandsVC = CommandsTableViewController()
            commandsVC.title = "Function keys"
            commandsVC.commands = [[Keys.f1, "F1"], [Keys.f2, "F2"], [Keys.f3, "F3"], [Keys.f4, "F4"], [Keys.f5, "F5"], [Keys.f6, "F6"], [Keys.f7, "F7"], [Keys.f8, "F8"], [Keys.f9, "F9"], [Keys.f10, "F10"], [Keys.f11, "F11"], [Keys.f12, "F12"]]
            commandsVC.modalPresentationStyle = .popover
            
            if let popover = commandsVC.popoverPresentationController {
                popover.sourceView = sender
                popover.delegate = commandsVC
                
                self.present(commandsVC, animated: true, completion: nil)
            }
        } else if sender.tag == 8 { // Left arrow
           insertText(Keys.arrowLeft)
        } else if sender.tag == 9 { // Up arrow
            insertText(Keys.arrowUp)
        } else if sender.tag == 10 { // Down arrow
            insertText(Keys.arrowDown)
        } else if sender.tag == 11 { // Right arrow
            insertText(Keys.arrowRight)
        }
    }
    
    /// Insert key by a long press gesture.
    ///
    /// - Parameters:
    ///     - sender: Sender event.
    @objc func insertKeyByLongPress(_ sender: UILongPressGestureRecognizer) {
        
        arrowsLongPressDelay -= 1
        
        guard arrowsLongPressDelay <= 0 else {
            return
        }
        
        arrowsLongPressDelay = 2
        
        if let button = sender.view as? UIButton {
            insertKey(button)
        }
    }
    
    /// Write from wireless keyboard.
    ///
    /// - Parameters:
    ///     - command: Command sent from keyboard.
    @objc func write(fromCommand command: UIKeyCommand) {
        guard let channel = ConnectionManager.shared.session?.channel else { return }
        
        if command.modifierFlags.rawValue == 0 {
            switch command.input {
            case UIKeyInputUpArrow?:
                try? channel.write(Keys.arrowUp)
            case UIKeyInputDownArrow?:
                try? channel.write(Keys.arrowDown)
            case UIKeyInputLeftArrow?:
                try? channel.write(Keys.arrowLeft)
            case UIKeyInputRightArrow?:
                try? channel.write(Keys.arrowRight)
            case UIKeyInputEscape?:
                try? channel.write(Keys.esc)
            default:
                break
            }
        } else if command.modifierFlags == .control { // Send CTRL key
            try? channel.write(Keys.ctrlKey(from: command.input!))
        }
    }
    
    // MARK: NMSSH channel delegate
    
    /// Write data to `webView` and send data to MC peers.
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            
            if self.console.contains(TerminalViewController.close) { // Close shell
                self.console = self.console.replacingOccurrences(of: TerminalViewController.close, with: "")
                self.resignFirstResponder()
                self.readOnly = true
                if self.toolbarItems?.count == 2 {
                    self.toolbarItems?.remove(at: 1)
                }
            }
            
            if self.webView != nil {
                self.webView.evaluateJavaScript("term.write(\(message.javaScriptEscapedString))", completionHandler: { (_, _) in
                    
                    // Send data to peer
                    let info = TerminalInfo(message: message, themeName: UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth", terminalSize: [Float(self.webView.frame.width), Float(self.webView.frame.height)], terminalColsAndRows: self.terminalSize)
                    NSKeyedArchiver.setClassName("TerminalInfo", for: TerminalInfo.self)
                    let data = NSKeyedArchiver.archivedData(withRootObject: info)
                    if self.mcSession.connectedPeers.count > 0 {
                        try? self.mcSession.send(data, toPeers: self.mcSession.connectedPeers, with: .reliable)
                    }
                    
                    // Scroll to top if dontScroll is true
                    if self.dontScroll {
                        self.webView.evaluateJavaScript("term.scrollToTop()", completionHandler: nil)
                    }
                })
            }
        }
    }
    
    /// Undo changes made to `navigationController` and pop to Root view controller.
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            if self.isFirstResponder {
                self.resignFirstResponder()
            }
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    // MARK: Key input
    
    /// Send text or ctrl key to shell.
    func insertText(_ text: String) {
        do {
            
            if !ctrl {
                if viewer {
                    if let data = text.data(using: .utf8) {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                    }
                } else {
                    try ConnectionManager.shared.session?.channel.write(text.replacingOccurrences(of: "\n", with: Keys.unicode(dec: 13)))
                }
            } else {
                if viewer {
                    if let data = Keys.ctrlKey(from: text).data(using: .utf8) {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                    }
                } else {
                    try ConnectionManager.shared.session?.channel.write(Keys.ctrlKey(from: text))
                }
                
                ctrl = false
                
            }
            
        } catch {}
    }
    
    /// Send backspace to shell.
    func deleteBackward() {
        do {
            if viewer {
                if let data = Keys.delete.data(using: .utf8) {
                    try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                }
            } else {
                try ConnectionManager.shared.session?.channel.write(Keys.delete)
            }
        } catch {}
    }
    
    /// Returns true.
    var hasText: Bool {
        return true
    }
    
    // MARK: Text input traits
    
    /// `UIKeyboardAppearance.dark`
    var keyboardAppearance: UIKeyboardAppearance = ((TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth"] ?? PisthTheme()).keyboardAppearance)
    
    /// `UITextAutocorrectionType.no`
    var autocorrectionType: UITextAutocorrectionType = .no
    
    /// Returns `.no`.
    var smartQuotesType: UITextSmartQuotesType = .no
    
    // MARK: Web kit navigation delegate

    /// Run startup commands if `console` is empty, enable blinking cursor if `UserDefaults` 'blink' value is `true` and resize terminal if the Web view was reloaded.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if UserDefaults.standard.bool(forKey: "blink") {
            webView.evaluateJavaScript("term.setOption('cursorBlink', true)", completionHandler: nil)
        }
        
        webView.evaluateJavaScript("term.setOption('fontSize', \(UserDefaults.standard.integer(forKey: "terminalTextSize")))", completionHandler: nil)
        selectionTextView.font = selectionTextView.font?.withSize(CGFloat(UserDefaults.standard.integer(forKey: "terminalTextSize")))
        
        let themeName = UserDefaults.standard.string(forKey: "terminalTheme")!
        if let theme = TerminalTheme.themes[themeName] {
            webView.evaluateJavaScript("term.setOption('theme', \(theme.javascriptValue))", completionHandler: nil)
            webView.backgroundColor = theme.backgroundColor
            selectionTextView.backgroundColor = theme.backgroundColor
            selectionTextView.textColor = theme.foregroundColor
        }
        
        webView.evaluateJavaScript("fit(term)", completionHandler: {_,_ in
            if !self.viewer {
                self.changeSize(completion: nil)
            }
            
            // Animation
            for view in self.view.subviews {
                if view.tag == 5 {
                    UIView.animate(withDuration: 0.5, animations: {
                        view.alpha = 0
                    })
                    
                    _ = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false, block: { (_) in
                        view.removeFromSuperview()
                    })
                }
            }
        })
        
        if console.isEmpty {
            
            guard !viewer else {
                return
            }
            
            // Session
            guard let session = ConnectionManager.shared.session else {
                navigationController?.popViewController(animated: true)
                return
            }
            
            if !session.isConnected {
                let errorMessage = "\(Keys.esc)[0;31mError connecting! Check for connection's host and your internet connection.\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("term.write(\(errorMessage))", completionHandler: nil)
                resignFirstResponder()
                navigationItem.rightBarButtonItems = []
                return
            }
            
            if !session.isAuthorized {
                let errorMessage = "\(Keys.esc)[0;31mError authenticating! Check for username and password.\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("term.write(\(errorMessage))", completionHandler: nil)
                resignFirstResponder()
                navigationItem.rightBarButtonItems = []
                return
            }
            
            do {
                if !self.pureMode {
                    let clearLastFromHistory = "history -d $(history 1)"
                    
                    session.channel.closeShell()
                    session.channel.delegate = self
                    try session.channel.startShell()
                    
                    if let pwd = self.pwd {
                        try session.channel.write("cd '\(pwd)'; \(clearLastFromHistory)\n")
                    }
                    
                    try session.channel.write("clear; \(clearLastFromHistory)\n")
                    
                    if let command = self.command {
                        try session.channel.write("\(command);\n")
                    }
                } else {
                    
                    // Sorry Termius ;-(
                    let os = try? ConnectionManager.shared.session?.channel.execute("""
                    SA_OS_TYPE="Linux"
                    REAL_OS_NAME=`uname`
                    if [ "$REAL_OS_NAME" != "$SA_OS_TYPE" ] ;
                    then
                    echo $REAL_OS_NAME
                    else
                    DISTRIB_ID=\"`cat /etc/*release`\"
                    echo $DISTRIB_ID;
                    fi;
                    """)
                    
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
                    request.returnsObjectsAsFaults = false
                    
                    do {
                        let results = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                        
                        for result in results {
                            if result.value(forKey: "host") as? String == ConnectionManager.shared.connection?.host {
                                if let os = os {
                                    result.setValue(os, forKey: "os")
                                }
                            }
                        }
                        
                        DataManager.shared.saveContext()
                    } catch let error {
                        print("Error retrieving connections: \(error.localizedDescription)")
                    }
                    
                    session.channel.delegate = self
                    try session.channel.startShell()
                }
            } catch {}
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                self.showNavBar()
            })
        } else {
            webView.evaluateJavaScript("term.write(\(self.console.javaScriptEscapedString))", completionHandler: {_, _ in
                if self.selectText {
                    webView.evaluateJavaScript("term.selectAll(); term.selectionManager.selectionText", completionHandler: { (result, _) in
                        
                        if let result = result as? String {
                            self.selectionTextView.text = result
                            self.selectionTextView.scrollRangeToVisible(NSRange(location: self.selectionTextView.text.nsString.length, length: 1))
                        }
                        
                        webView.evaluateJavaScript("term.selectionManager.setSelection(0)", completionHandler: nil)
                        
                    })
                    
                    self.selectText = false
                }
            })
        }
        
        // Plugins
        for plugin in (try? FileManager.default.contentsOfDirectory(at: FileManager.default.library.appendingPathComponent("Plugins"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] {
            
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: plugin.path, isDirectory: &isDir) && isDir.boolValue && plugin.pathExtension.lowercased() == "termplugin" {
                let tmpPlugin = URL(fileURLWithPath: NSTemporaryDirectory().nsString.appendingPathComponent(plugin.lastPathComponent))
                
                try? FileManager.default.removeItem(at: tmpPlugin)
                try? FileManager.default.copyItem(at: plugin, to: tmpPlugin)
                
                webView.evaluateJavaScript("var js = document.createElement('script'); js.type = 'text/javascript'; js.src = 'file://\(tmpPlugin.appendingPathComponent("index.js").path)'; js.bundlePath = '\(tmpPlugin.path)'; document.head.appendChild(js)", completionHandler: nil)
            }
            
        }
    }
    
    // MARK: Web kit ui delegate
    
    /// Sound bell if the text of the alert is "bell".
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if message == "bell" { // Play bell
            bell()
        } else if message.hasPrefix("changeTitle") { // Change title
            title = message.replacingFirstOccurrence(of: "changeTitle", with: "")
        } else if message.hasPrefix("runCommand") { // Run command
            title = message.replacingFirstOccurrence(of: "runCommand", with: "")
        }
        completionHandler()
    }
    
    // MARK: - Multipeer connectivity
    
    /// Peer ID used in `mcSession`.
    var peerID: MCPeerID!
    
    /// Multipeer connectivity to send data to the Mac app.
    var mcSession: MCSession!
    
    /// `MCNearbyServiceAdvertiser` used to be discoverable by the Mac app.
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    
    /// Display an alert to accept or decline invitation.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        let alert = UIAlertController(title: "Acept invitation from \(peerID.displayName)?", message: "\(peerID.displayName) wants to see the terminal.", preferredStyle: .alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: .default) { (alertAction) -> Void in
            invitationHandler(true, self.mcSession)
        }
        
        let declineAction = UIAlertAction(title: "Decline", style: .cancel) { (alertAction) -> Void in
            invitationHandler(false, nil)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    /// If `state` is connected, send initial information to `peer`.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {

        if state == .connected {
            print("Connected!")
            if !viewer {
                DispatchQueue.main.async {
                    // Send data to peer
                    let info = TerminalInfo(message: self.console, themeName: UserDefaults.standard.string(forKey: "terminalTheme") ?? "Pisth", terminalSize: [Float(self.webView.frame.width), Float(self.webView.frame.height)])
                    NSKeyedArchiver.setClassName("TerminalInfo", for: TerminalInfo.self)
                    let data = NSKeyedArchiver.archivedData(withRootObject: info)
                    try? self.mcSession.send(data, toPeers: self.mcSession.connectedPeers, with: .reliable)
                }
            }
        } else if state == .connecting {
            print("Connecting...")
        } else {
            print("Disconnected!")
        }
    }
    
    /// Write received String to the Shell.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSKeyedUnarchiver.setClass(TerminalInfo.self, forClassName: "TerminalInfo")
        
        DispatchQueue.main.async {
            if let str = String(data: data, encoding: .utf8) {
                if self.viewer {
                    self.webView.evaluateJavaScript("term.write(\(str.javaScriptEscapedString))", completionHandler: nil)
                    self.console += str
                } else {
                    self.insertText(str)
                }
            } else if let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? TerminalInfo {
                
                if let size = info.terminalColsAndRows {
                    self.webView.evaluateJavaScript("term.resize(\(size))", completionHandler: { (_, _) in
                        self.webView.evaluateJavaScript("term.write(\(info.message.javaScriptEscapedString))", completionHandler: nil)
                    })
                } else {
                    self.webView.evaluateJavaScript("term.write(\(info.message.javaScriptEscapedString))", completionHandler: nil)
                }
                
                self.console += info.message
            }
        }
    }
    
    /// Do nothing.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream")
    }
    
    /// Do nothing.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Start receiving resource")
    }
    
    /// Do nothing
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finish receiving resource")
    }
    
    // MARK: - Gesture recognizer delegate
    
    /// - Returns: `true`.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Drop interaction delegate
    
    /// Drop a file.
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        for item in session.items {
            if let file = item.localObject as? NMSFTPFile {
                guard let vcs = navigationController?.viewControllers else {
                    return
                }
                
                guard let i = vcs.index(of: self) else {
                    return
                }
                
                guard vcs.indices.contains(i-1) else {
                    return
                }
                
                guard let dirVC = vcs[i-1] as? DirectoryTableViewController else {
                    return
                }
                
                try? ConnectionManager.shared.session?.channel.write("\(dirVC.directory.nsString.appendingPathComponent(file.filename)) ")
            }
        }
        
       becomeFirstResponder()
    }
    
    /// Allow dragging a `NMSFTPFile`.
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return (session.localDragSession?.items.first?.localObject is NMSFTPFile)
    }
    
    /// - Returns: `UIDropProposal(operation: .copy)`.
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    // MARK: - Static
    
    /// Print this to dismiss the keyboard (from SSH).
    static let close = "\(Keys.esc)[CLOSE"
}
