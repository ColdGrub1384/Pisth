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
import PanelKit
import CoreSpotlight
import InputAssistant

/// Terminal used to do SSH.
class TerminalViewController: UIViewController, NMSSHChannelDelegate, WKNavigationDelegate, WKUIDelegate, UIKeyInput, UITextInputTraits, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, UIGestureRecognizerDelegate, UIDropInteractionDelegate, PanelContentDelegate, InputAssistantViewDelegate, InputAssistantViewDataSource {
    
    private var terminalSize: String?
    
    /// Returns `false` if the terminal is presented as a panel on iPad.
    var isPresentedInFullscreen: Bool {
        guard let panel = panelNavigationController?.panelViewController else {
            return true
        }
        
        return (!panel.isPresentedAsPopover && !panel.isFloating)
    }
    
    /// Object managing the connection.
    var connectionManager = ConnectionManager.shared
    
    /// If the terminal is in viewer mode.
    var viewer = false
    
    /// Directory to open.
    var pwd: String? {
        didSet {
            files = files_ // Call the getter only once for improving performance
        }
    }
    
    /// Content of console.
    var console = ""
    
    /// Command to run at starting.
    var command: String?
        
    /// Don't scroll when console's content changes.
    var dontScroll = false
    
    /// The button for becoming or resigning first responder.
    var keyboardButton: UIBarButtonItem!
    
    /// Send Ctrl key.
    var ctrl = false {
        didSet {
            inputAssistant.reloadData()
        }
    }
    
    /// Is terminal read only.
    var readOnly = false
    
    /// Web view used to display content.
    var webView: TerminalWebView!
    
    /// Text view with plain output
    var selectionTextView: UITextView!
    
    /// If true, all addtional commands will not be executed and the shell with be launched 'purely'.
    var pureMode = false
    
    /// The theme currently used by the terminal.
    var theme: TerminalTheme {
        if UIAccessibility.isInvertColorsEnabled {
            return ProTheme()
        } else {
            return TerminalTheme.themes[UserKeys.terminalTheme.stringValue!]!
        }
    }
    
    /// The input assistant view.
    let inputAssistant = InputAssistantView()
    
    /// Ignored notifications name strings.
    /// When a the function linked with a notification listed here, the function will remove the given notification from this array and will return.
    var ignoredNotifications = [Notification.Name]()
    
    private var arrowsLongPressDelay = 2
    
    /// Navigation controller to reset at `viewDidDisappear(_:)`.
    var navigationController_: UINavigationController?
    
    /// Show commands history.
    @available(*, deprecated, message: "Showing the history from the terminal is now unsupported.")
    @objc func showHistory(_ sender: UIBarButtonItem) {
        
        do {
            guard let session = connectionManager.filesSession else { return }
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
            connectionManager.session?.channel.requestSizeWidth(cols, height: rows)
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
    
    /// Show plain output and allow selection.
    @objc func selectionMode() {
        selectionTextView.isHidden = false
        view.backgroundColor = selectionTextView.backgroundColor
        selectionTextView.text = ""
        webView.isHidden = true
        _ = resignFirstResponder()
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.webView.evaluateJavaScript("fit(term); term.selectAll(); term.selectionManager.selectionText", completionHandler: { (result, _) in
                
                if let result = result as? String {
                    self.selectionTextView.text = result
                    self.selectionTextView.scrollRangeToVisible(NSRange(location: self.selectionTextView.text.nsString.length, length: 1))
                }
                
                self.webView.evaluateJavaScript("term.selectionManager.setSelection(0)", completionHandler: nil)
            })
        })
    }
    
    /// Hide plain output and disallow selection.
    @objc func insertMode() {
        selectionTextView.isHidden = true
        webView.isHidden = false
        if theme.keyboardAppearance == .dark {
            view.backgroundColor = .black
        } else {
            view.backgroundColor = .white
        }
        _ = becomeFirstResponder()
    }
    
    /// Send clipboard.
    @objc func pasteText() {
        if isFirstResponder {
            insertText(UIPasteboard.general.string ?? "")
        }
    }
    
    /// Send text selected in `selectionTextView`.
    @objc func pasteSelection() {
        guard !selectionTextView.isHidden else {
            return
        }
        
        if let range = selectionTextView.selectedTextRange, let text = selectionTextView.text(in: range) {
            insertText(text)
        }
        
        insertMode()
    }
    
    /// Send user password.
    @objc func sendPassword() {
        if isFirstResponder {
            
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: Localizable.TerminalViewController.authenticateToSendPassword(of: connectionManager.connection?.username ?? "user"), fallbackTitle: "", cancelTitle: nil, success: {
                
                self.insertText(self.connectionManager.connection?.password ?? "")
                
            }, failure: { (error) in
                
                if error == .biometryNotEnrolled || error == .passcodeNotSet || error == .biometryNotAvailable {
                    self.insertText(self.connectionManager.connection?.password ?? "")
                }
            })
        }
    }
    
    /// Hide or show navigation bar.
    @objc func showNavBar() {
        navigationController?.setNavigationBarHidden(!navigationController!.isNavigationBarHidden, animated: true)
        fit()
    }
    
    /// Enter in selection mode or paste text.
    @objc func showActions(_ sender: UIBarButtonItem) {
        var actions = [UIAlertAction]()
        
        if !selectionTextView.isHidden {
            actions.append(UIAlertAction(title: Localizable.TerminalViewController.insertMode, style: .default, handler: { (_) in
                self.insertMode()
            }))
        } else {
            actions.append(UIAlertAction(title: Localizable.TerminalViewController.selectionMode, style: .default, handler: { (_) in
                self.selectionMode()
            }))
        }
        
        actions.append(UIAlertAction(title: Localizable.TerminalViewController.paste, style: .default, handler: { (_) in
            self.insertText(UIPasteboard.general.string ?? "")
        }))
        
        actions.append(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
        
        let alert = UIAlertController(title: Localizable.TerminalViewController.selectAction, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        for action in actions {
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Show or hide keyboard.
    @objc func toggleKeyboard() {
        
        if isFirstResponder {
            _ = resignFirstResponder()
        } else {
            _ = becomeFirstResponder()
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
    
    /// Resize and reload `webView`.
    func resizeView(withSize size: CGSize) {
                
        webView.frame.size = size
        webView.frame.origin = CGPoint(x: 0, y: 0)
        if let arrowsVC = ArrowsViewController.current {
            arrowsVC.view.frame = webView.frame
        }
        
        fit()
    }
    
    /// Fit the terminal content.
    func fit() {
        webView.evaluateJavaScript("fit(term)", completionHandler: {_, _ in
            if !self.viewer {
                self.changeSize(completion: nil)
            }
        })
    }
    
    /// Close this View controller.
    @objc func close() {
        if panelNavigationController != nil {
            panelNavigationController?.dismiss(animated: true, completion: nil)
        } else if navigationController != nil {
            navigationController?.popViewController(animated: true)
        }
    }
    
    /// Show the menu.
    @objc func showMenu(_ gesture: UILongPressGestureRecognizer) {

        UIMenuController.shared.setTargetRect(CGRect(origin: gesture.location(in: webView), size: CGSize.zero), in: webView)
        
        if gesture.state == .ended {
            _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                UIMenuController.shared.setMenuVisible(true, animated: true)
            })
        } else {
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    /// Called by `NotificationCenter` to inform the theme changed.
    @objc func themeDidChanged(_ notification: Notification) {
        guard let theme = notification.object as? TerminalTheme else {
            return
        }
        
        keyboardAppearance = theme.keyboardAppearance
        webView.reload()
    }
    
    // MARK: - View controller
    
    override var canBecomeFirstResponder: Bool {
        return (webView != nil && !readOnly)
    }
    
    override var canResignFirstResponder: Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? {
        return inputAssistant
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        
        webView.evaluateJavaScript("term.setOption('cursorStyle', 'bar')", completionHandler: nil)
        keyboardButton?.image = #imageLiteral(resourceName: "show-keyboard")
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        
        webView.evaluateJavaScript("term.setOption('cursorStyle', 'block')", completionHandler: nil)
        keyboardButton?.image = #imageLiteral(resourceName: "hide-keyboard")
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        // Bluetooth keyboard
        
        var commands =  [
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(pasteText), discoverabilityTitle: Localizable.TerminalViewController.paste),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendUpArrow),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendDownArrow),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendLeftArrow),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendRightArrow),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendEsc),
        ]
        
        let ctrlKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_"] // All CTRL keys
        for ctrlKey in ctrlKeys {
            commands.append(UIKeyCommand(input: ctrlKey, modifierFlags: .control, action: #selector(write(fromCommand:)), discoverabilityTitle: Localizable.TerminalViewController.sendCtrl(ctrlKey)))
        }
        
        return commands
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-Terminal", AnalyticsParameterItemName : "Terminal"])
        
        edgesForExtendedLayout = []
        
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        
        // Resize webView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChanged), name: .init("TerminalThemeDidChanged"), object: nil)
        
        // Setup connectivity
        if peerID == nil {
            peerID = MCPeerID(displayName: UIDevice.current.name)
        }
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "terminal")
        mcNearbyServiceAdvertiser.delegate = self
        
        // Create WebView
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = .video
        webView = TerminalWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isOpaque = false
        webView.loadFileURL(Bundle.terminal.bundleURL.appendingPathComponent("terminal.html"), allowingReadAccessTo: URL(string:"file:///")!)
        view.addSubview(webView)
        webView.backgroundColor = .clear
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.ignoresInvertColors = true
        webView.toggleKeyboard = toggleKeyboard
        webView.showMenu = showMenu(_:)
        
        if #available(iOS 11.0, *) {
            view.addInteraction(UIDropInteraction(delegate: self))
        }
        
        // Create selection Textview
        selectionTextView = UITextView(frame: view.frame)
        selectionTextView.isHidden = true
        selectionTextView.font = UIFont(name: "Courier", size: 15)
        selectionTextView.isEditable = false
        selectionTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectionTextView)
        NSLayoutConstraint.activate([
            selectionTextView.leadingAnchor.constraint(equalTo: webView.layoutMarginsGuide.leadingAnchor),
            selectionTextView.trailingAnchor.constraint(equalTo: webView.layoutMarginsGuide.trailingAnchor)
        ])
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                selectionTextView.topAnchor.constraint(equalToSystemSpacingBelow: webView.layoutMarginsGuide.topAnchor, multiplier: 1.0),
                webView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: selectionTextView.bottomAnchor, multiplier: 1.0)
            ])
        }
        
        if readOnly {
            toolbarItems?.remove(at: 1)
        }
        
        navigationItem.rightBarButtonItems = rightBarButtonItems
        
        (panelNavigationController?.navigationController ?? navigationController)?.view.ignoresInvertColors = true
        
        keyboardAppearance = theme.keyboardAppearance
        selectionTextView.keyboardAppearance = keyboardAppearance
        
        // Input assistant
        inputAssistant.delegate = self
        inputAssistant.dataSource = self
        inputAssistant.attach(to: selectionTextView) // For keyboard appearance
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController_ = navigationController
        
        if !viewer {
            mcNearbyServiceAdvertiser.startAdvertisingPeer()
        }
        
        if console.isEmpty {
            
            if !pureMode {
                connectionManager.session?.channel.closeShell()
                try? connectionManager.session?.channel.startShell()
            }
        }
        
        if pureMode && panelNavigationController == nil {
            navigationItem.leftBarButtonItem = AppDelegate.shared.showBookmarksBarButtonItem
        }
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        addObserver(self, forKeyPath: #keyPath(view.frame), options: .new, context: nil)
        
         _ = becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        mcNearbyServiceAdvertiser.stopAdvertisingPeer()
        if !isShell {
            navigationController_?.navigationBar.barStyle = .default
        } else {
            navigationController_?.navigationBar.barStyle = .black
        }
        navigationController_?.view.backgroundColor = .white
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let theme = TerminalTheme.themes[UserKeys.terminalTheme.stringValue!], theme.toolbarStyle == .black {
            return .lightContent
        }
        
        return .default
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if selectionTextView.isHidden {
            return (action == #selector(pasteText) || action == #selector(selectionMode) || action == #selector(showNavBar))
        } else {
            return (action == #selector(pasteSelection) || action == #selector(insertMode) || action == #selector(showNavBar))
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        fit()
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        guard let connection = connectionManager.connection else {
            return
        }
        
        activity.userInfo = ["username":connection.username, "password":connection.password, "host":connection.host, "port":connection.port]
        
        if let pubKey = connection.publicKey {
            activity.userInfo!["publicKey"] = pubKey
        }
        
        if let privKey = connection.privateKey {
            activity.userInfo!["privateKey"] = privKey
        }
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
        
        guard isPresentedInFullscreen else {
            return
        }
        
        let inputAssistantOrigin = view.convert(inputAssistant.frame.origin, from: inputAssistant)
        if inputAssistantOrigin.y > 0 {
            resizeView(withSize: CGSize(width: view.frame.width, height: inputAssistantOrigin.y))
        } else if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            resizeView(withSize: CGSize(width: view.frame.width, height: view.frame.height-keyboardFrame.height))
        }
        
        if let arrowsVC = ArrowsViewController.current {
            arrowsVC.view.frame = webView.frame
        }
        
        if !selectionTextView.isHidden {
            insertMode()
        }
    }
    
    /// Resize `webView` when keyboard is hidden.
    @objc func keyboardDidHide(_ notification:Notification) {
        
        guard !ignoredNotifications.contains(notification.name) else {
            if let i = ignoredNotifications.index(of: notification.name) {
                ignoredNotifications.remove(at: i)
            }
            return
        }
        
        if webView.frame.size != view.bounds.size {
            webView.frame = view.bounds
            fit()
        }
        
        if let arrowsVC = ArrowsViewController.current {
            arrowsVC.view.frame = webView.frame
        }
    }
    
    /// Enable or disable swiping to send arrow keys.
    ///
    /// - Parameters:
    ///     - flag: If `true`, arrows will be enabled.
    @objc func toggleSendArrows(_ flag: Bool) {
        
        if flag {
            let arrowsVC = ArrowsViewController()
            
            view.addSubview(arrowsVC.view)
            arrowsVC.view.frame = webView.frame
            
            for gesture in webView.gestureRecognizers ?? [] {
                arrowsVC.view.addGestureRecognizer(gesture)
            }
        } else {
            
            ArrowsViewController.current?.helpLabel.isHidden = false
            ArrowsViewController.current?.helpLabel.alpha = 1
            ArrowsViewController.current?.helpLabel.text = Localizable.ArrowsViewControllers.helpTextScroll
            
            for gesture in ArrowsViewController.current!.view.gestureRecognizers! {
                if gesture.gestureName == "arrow" {
                    gesture.isEnabled = false
                } else {
                    webView.addGestureRecognizer(gesture)
                }
            }
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut, animations: {
                    ArrowsViewController.current?.helpLabel.alpha = 0
                }, completion: { _ in
                    ArrowsViewController.current?.helpLabel.isHidden = true
                    
                    ArrowsViewController.current?.view.removeFromSuperview()
                })
            })
        }
    }
    
    /// Write from wireless keyboard.
    ///
    /// - Parameters:
    ///     - command: Command sent from keyboard.
    @objc func write(fromCommand command: UIKeyCommand) {
        guard let channel = connectionManager.session?.channel else { return }
        
        if command.modifierFlags.rawValue == 0 {
            switch command.input {
            case UIKeyCommand.inputUpArrow?:
                try? channel.write(Keys.arrowUp)
            case UIKeyCommand.inputDownArrow?:
                try? channel.write(Keys.arrowDown)
            case UIKeyCommand.inputLeftArrow?:
                try? channel.write(Keys.arrowLeft)
            case UIKeyCommand.inputRightArrow?:
                try? channel.write(Keys.arrowRight)
            case UIKeyCommand.inputEscape?:
                try? channel.write(Keys.esc)
            default:
                break
            }
        } else if command.modifierFlags == .control { // Send CTRL key
            try? channel.write(Keys.ctrlKey(from: command.input!))
        }
    }
    
    // MARK: NMSSH channel delegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            
            if self.console.contains(TerminalViewController.close) { // Close shell
                self.console = self.console.replacingOccurrences(of: TerminalViewController.close, with: "")
                _ = self.resignFirstResponder()
                self.readOnly = true
                if self.toolbarItems?.count == 2 {
                    self.toolbarItems?.remove(at: 1)
                }
            }
            
            if self.webView != nil {
                self.webView.evaluateJavaScript("term.write(\(message.javaScriptEscapedString)); term.scrollToBottom();", completionHandler: { (_, _) in
                    
                    // Send data to peer
                    let info = TerminalInfo(message: message, themeName: UserKeys.terminalTheme.stringValue ?? "Pisth", terminalSize: [Float(self.webView.frame.width), Float(self.webView.frame.height)], terminalColsAndRows: self.terminalSize)
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
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            if self.isFirstResponder {
                _ = self.resignFirstResponder()
            }
            self.close()
        }
    }
    
    
    // MARK: Key input
    
    func insertText(_ text: String) {
        do {
            
            if !ctrl {
                if viewer {
                    if let data = text.data(using: .utf8) {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                    }
                } else {
                    try connectionManager.session?.channel.write(text.replacingOccurrences(of: "\n", with: Keys.unicode(dec: 13)))
                    if text == "\n" {
                        files = files_
                        inputAssistant.reloadData()
                    }
                }
            } else {
                if viewer {
                    if let data = Keys.ctrlKey(from: text).data(using: .utf8) {
                        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                    }
                } else {
                    try connectionManager.session?.channel.write(Keys.ctrlKey(from: text))
                }
                
                ctrl = false
            }
            
        } catch {}
    }
    
    func deleteBackward() {
        do {
            if viewer {
                if let data = Keys.delete.data(using: .utf8) {
                    try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
                }
            } else {
                try connectionManager.session?.channel.write(Keys.delete)
            }
        } catch {}
    }
    
    var hasText: Bool {
        return true
    }
    
    // MARK: Text input traits
    
    var keyboardAppearance: UIKeyboardAppearance = .default
    
    var autocorrectionType: UITextAutocorrectionType = .no
    
    @available(iOS 11.0, *)
    var smartQuotesType: UITextSmartQuotesType {
        get {
            return .no
        }
        
        set {
            print("`smartQuotesType` setter not implemented")
        }
    }

    // MARK: Web kit navigation delegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if UserKeys.blink.boolValue {
            webView.evaluateJavaScript("term.setOption('cursorBlink', true)", completionHandler: nil)
        }
        webView.evaluateJavaScript("term.setOption('fontSize', \(UserKeys.terminalTextSize.integerValue))", completionHandler: nil)
        selectionTextView.font = selectionTextView.font?.withSize(CGFloat(UserKeys.terminalTextSize.integerValue))
        
        (panelNavigationController?.navigationController ?? navigationController)?.navigationBar.barStyle = theme.toolbarStyle
        webView.evaluateJavaScript("term.setOption('theme', \(theme.javascriptValue))", completionHandler: nil)
        webView.backgroundColor = theme.backgroundColor
        (panelNavigationController?.navigationController ?? navigationController)?.view.backgroundColor = theme.backgroundColor
        selectionTextView.backgroundColor = theme.backgroundColor
        selectionTextView.textColor = theme.foregroundColor
        if theme.keyboardAppearance == .dark {
            view.backgroundColor = .black
        } else {
            view.backgroundColor = .white
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
            guard let session = connectionManager.session else {
                self.close()
                return
            }
            
            if !session.isConnected {
                let errorMessage = "\(Keys.esc)[0;31m\(Localizable.TerminalViewController.errorConnecting)\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("term.write(\(errorMessage))", completionHandler: nil)
                _ = resignFirstResponder()
                navigationItem.rightBarButtonItems = []
                return
            }
            
            if !session.isAuthorized {
                let errorMessage = "\(Keys.esc)[0;31m\(Localizable.TerminalViewController.errorAuthenticating)\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("term.write(\(errorMessage))", completionHandler: nil)
                _ = resignFirstResponder()
                navigationItem.rightBarButtonItems = []
                return
            }
            
            DispatchQueue.main.async {
                do {
                    
                    if !self.pureMode {
                        
                        session.channel.closeShell()
                        session.channel.delegate = self
                        try session.channel.startShell()
                        
                    } else {
                        
                        // Sorry Termius ;-(
                        let os = try? self.connectionManager.session?.channel.execute("""
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
                        
                        self.connectionManager.connection?.os = os ?? nil
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
                        request.returnsObjectsAsFaults = false
                        
                        do {
                            let results = try (DataManager.shared.coreDataContext.fetch(request) as! [NSManagedObject])
                            
                            for result in results {
                                if result.value(forKey: "host") as? String == self.connectionManager.connection?.host {
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
                        
                        // Siri Shortcuts
                        
                        guard let connection = self.connectionManager.connection else {
                            return
                        }
                        
                        let activity = NSUserActivity(activityType: "ch.marcela.ada.Pisth.openTerminal")
                        if #available(iOS 12.0, *) {
                            activity.isEligibleForPrediction = true
                            //                    activity.suggestedInvocationPhrase = connection.name
                        }
                        activity.isEligibleForSearch = true
                        activity.keywords = [connection.name, connection.username, connection.host, connection.path,"ssh", "terminal"]
                        activity.title = connection.name
                        var userInfo = ["username":connection.username, "password":connection.password, "host":connection.host, "directory":connection.path, "port":connection.port] as [String : Any]
                        
                        if let pubKey = connection.publicKey {
                            userInfo["publicKey"] = pubKey
                        }
                        
                        if let privKey = connection.privateKey {
                            userInfo["privateKey"] = privKey
                        }
                        
                        activity.userInfo = userInfo
                        
                        let attributes = CSSearchableItemAttributeSet(itemContentType: "public.item")
                        if let os = connection.os?.lowercased() {
                            if let logo = UIImage(named: (os.slice(from: " id=", to: " ")?.replacingOccurrences(of: "\"", with: "") ?? os).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")) {
                                attributes.thumbnailData = logo.pngData()
                            }
                        }
                        attributes.addedDate = Date()
                        attributes.contentDescription = "ssh://\(connection.username)@\(connection.host):\(connection.port)"
                        activity.contentAttributeSet = attributes
                        
                        self.userActivity = activity
                    }
                    
                    if let pwd = self.pwd {
                        try session.channel.write("cd '\(pwd)'\n")
                    }
                    
                    if let command = self.command {
                        try session.channel.write("\(command);\n")
                    }
                } catch {}
            }
        } else {
            webView.evaluateJavaScript("term.write(\(self.console.javaScriptEscapedString))", completionHandler: nil)
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
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if message == "bell" { // Play bell
            bell()
        } else if message.hasPrefix("changeTitle") { // Change title
            title = message.replacingFirstOccurrence(of: "changeTitle", with: "")
        } else if message.hasPrefix("runCommand") { // Run command
            try? connectionManager.session?.channel.write(message.replacingFirstOccurrence(of: "runCommand", with: ""))
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
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        let alert = UIAlertController(title: Localizable.TerminalViewController.acceptInvitation(from: peerID.displayName), message: Localizable.TerminalViewController.peerWantsToSeeTheTerminal(peerID.displayName), preferredStyle: .alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: Localizable.TerminalViewController.accept, style: .default) { (alertAction) -> Void in
            invitationHandler(true, self.mcSession)
        }
        
        let declineAction = UIAlertAction(title: Localizable.TerminalViewController.decline, style: .cancel) { (alertAction) -> Void in
            invitationHandler(false, nil)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {

        if state == .connected {
            print("Connected!")
            if !viewer {
                DispatchQueue.main.async {
                    // Send data to peer
                    let info = TerminalInfo(message: self.console, themeName: UserKeys.terminalTheme.stringValue ?? "Pisth", terminalSize: [Float(self.webView.frame.width), Float(self.webView.frame.height)])
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
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Start receiving resource")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finish receiving resource")
    }
    
    // MARK: - Gesture recognizer delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Drop interaction delegate
    
    @available(iOS 11.0, *)
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        if session.localDragSession?.items.first?.localObject is NMSFTPFile {
            for item in session.items {
                if let file = item.localObject as? NMSFTPFile {
                    guard let dirVC = item.sourceViewController as? DirectoryCollectionViewController else {
                        return
                    }
                    
                    try? connectionManager.session?.channel.write("\(dirVC.directory.nsString.appendingPathComponent(file.filename)) ")
                }
            }
        } else if session.canLoadObjects(ofClass: String.self) {
            _ = session.loadObjects(ofClass: String.self) { (strings) in
                for string in strings {
                    try? self.connectionManager.session?.channel.write(string+" ")
                }
            }
        }
        
       _ = becomeFirstResponder()
    }
    
    @available(iOS 11.0, *)
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        let canHandle = (session.localDragSession?.items.first?.localObject is NMSFTPFile || session.canLoadObjects(ofClass: String.self))
        if canHandle {
            webView.removeFromSuperview()
        }
        return canHandle
    }

    @available(iOS 11.0, *)
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    @available(iOS 11.0, *)
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        view.addSubview(webView)
    }
    
    // MARK: - Panel content delegate
    
    var preferredPanelContentSize: CGSize {
        return CGSize(width: 500, height: 500)
    }
    
    var minimumPanelContentSize: CGSize {
        return CGSize(width: 240, height: 260)
    }
    
    var maximumPanelContentSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    var preferredPanelPinnedHeight: CGFloat {
        return 500
    }

    var preferredPanelPinnedWidth: CGFloat {
        return 500
    }
    
    var rightBarButtonItems: [UIBarButtonItem] {
        if keyboardButton == nil {
            keyboardButton = UIBarButtonItem(image: #imageLiteral(resourceName: "hide-keyboard"), style: .plain, target: self, action: #selector(toggleKeyboard))
        }
        let items = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showActions(_:))), keyboardButton]
        for item in items {
            item?.tintColor = UIApplication.shared.keyWindow?.tintColor
        }
        return (items as? [UIBarButtonItem]) ?? []
    }
    
    var shouldAdjustForKeyboard: Bool {
        return isFirstResponder
    }
    
    var closeButtonTitle: String {
        return "×"
    }
    
    var modalCloseButtonTitle: String {
        return "×"
    }
    
    // MARK: - Suggestions
    
    private struct Suggestion {
        
        var name: String
        var value: String?
        var customHandler: (() -> Void)?
    }
    
    private var arrows = false
    
    private var files_: [String] {
        
        guard let fileSession = connectionManager.filesSession else {
            return []
        }
        
        let homeDir = try? fileSession.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "")
        let dir =  pwd ?? homeDir ?? "/"
        
        guard !viewer, let files = connectionManager.files(inDirectory: dir) else {
            return []
        }
        
        var filenames = [String]()
        
        for file in files {
            filenames.append(URL(fileURLWithPath: dir).appendingPathComponent(file.filename).path)
        }
        
        if let data = fileSession.sftp.contents(atPath: (homeDir ?? "~")+"/.bash_history"), let history = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") {
            for command in history {
                filenames.append(command)
            }
        }
        
        return filenames
    }
    
    private var files = [String]()
    
    private var suggestions: [Suggestion] {
        
        if ctrl {
            var ctrlKeysSuggestions = [Suggestion(name: "abc", value: nil, customHandler: {
                self.ctrl = false
            })]
            let ctrlKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_"] // All CTRL keys
            for key in ctrlKeys {
                ctrlKeysSuggestions.append(Suggestion(name: "^\(key)", value: key, customHandler: nil))
            }
            return ctrlKeysSuggestions
        } else {
            var suggestions = [
                Suggestion(name: "👆", value: nil, customHandler: {
                    self.arrows = !self.arrows
                    self.toggleSendArrows(self.arrows)
                }),
                Suggestion(name: "ctrl", value: nil, customHandler: {
                    self.ctrl = true
                }),
                Suggestion(name: "esc", value: Keys.esc, customHandler: nil),
                Suggestion(name: "←", value: Keys.arrowLeft, customHandler: nil),
                Suggestion(name: "↑", value: Keys.arrowUp, customHandler: nil),
                Suggestion(name: "↓", value: Keys.arrowDown, customHandler: nil),
                Suggestion(name: "→", value: Keys.arrowRight, customHandler: nil),
                Suggestion(name: "F1-F12", value: nil, customHandler: {
                    let commandsVC = CommandsTableViewController()
                    commandsVC.title = "Function keys"
                    commandsVC.commands = [[Keys.f1, "F1"], [Keys.f2, "F2"], [Keys.f3, "F3"], [Keys.f4, "F4"], [Keys.f5, "F5"], [Keys.f6, "F6"], [Keys.f7, "F7"], [Keys.f8, "F8"], [Keys.f9, "F9"], [Keys.f10, "F10"], [Keys.f11, "F11"], [Keys.f12, "F12"]]
                    commandsVC.modalPresentationStyle = .popover
                    
                    if let popover = commandsVC.popoverPresentationController {
                        popover.sourceView = self.inputAssistant
                        popover.delegate = commandsVC
                        
                        self.present(commandsVC, animated: true, completion: nil)
                    }
                })
            ]
            
            for file in files {
                suggestions.append(Suggestion(name: URL(fileURLWithPath: file).lastPathComponent, value: file+" ", customHandler: nil))
            }
            
            return suggestions
        }
    }
    
    // MARK: - Input assistant view delegete
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        if let value = suggestions[index].value {
            insertText(value)
        }
        suggestions[index].customHandler?()
    }
    
    // MARK: - Input assistant view data source
    
    func textForEmptySuggestionsInInputAssistantView() -> String? {
        return ""
    }
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        return suggestions.count
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        return suggestions[index].name
    }
    
    // MARK: - Static
    
    /// Print this to dismiss the keyboard (from SSH).
    static let close = "\(Keys.esc)[CLOSE"
}
