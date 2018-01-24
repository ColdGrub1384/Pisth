// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import WebKit

/// Terminal used to do SSH.
class TerminalViewController: UIViewController, NMSSHChannelDelegate, WKNavigationDelegate, UIKeyInput, UITextInputTraits {
    
    /// Directory to open.
    var pwd: String?
    
    /// Content of console.
    var console = ""
    
    /// Command to run at starting.
    var command: String?
    
    /// Ctrl key button.
    var ctrlKey: UIBarButtonItem!
    
    /// Disallow to dismiss keyboard.
    var preventKeyboardFromBeeingDismissed = true
    
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
                ctrlKey.tintColor = .white
            } else {
                ctrlKey.tintColor = view.tintColor
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
    
    /// If true, all addtional commands will not be executed and the shell with be launched 'purely'.
    var pureMode = false
    
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
    func addToolbar() {
        let toolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        // Buttons
        
        let goBack = UIBarButtonItem(image: #imageLiteral(resourceName: "back"), style: .plain, target: navigationController, action: #selector(navigationController?.popViewController(animated:)))
        
        let history = UIBarButtonItem(image:#imageLiteral(resourceName: "history"), style: .plain, target: self, action: #selector(showHistory(_:)))
        
        let arrows = UIBarButtonItem(image: #imageLiteral(resourceName: "touch"), style: .plain, target: self, action: #selector(sendArrows(_:)))
        
        ctrlKey = UIBarButtonItem(title: "Ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
        ctrlKey.tag = 1
        
        let escKey = UIBarButtonItem(title: "⎋", style: .done, target: self, action: #selector(insertKey(_:)))
        escKey.setTitleTextAttributes([NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 25)], for: .normal)
        escKey.tag = 6
        
        let fKeys = UIBarButtonItem(title: "F1-12", style: .done, target: self, action: #selector(insertKey(_:)))
        fKeys.tag = 7
        
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let items = [goBack, history, ctrlKey, space, arrows, escKey, fKeys] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        self.toolbar = toolbar
        
        setToolbarItems([UIBarButtonItem(image: #imageLiteral(resourceName: "back"), style: .plain, target: navigationController, action: #selector(navigationController?.popViewController(animated:)))], animated: true)
    }
    
    // MARK: - View controller
    
    /// `UIViewController`'s `canBecomeFirstResponder` variable.
    ///
    /// Returns if `webView is different than nil`.
    override var canBecomeFirstResponder: Bool {
        return (webView != nil)
    }

    /// `UIViewController`'s `canResignFirstResponder` variable.
    ///
    /// Returns inverted value of `preventKeyboardFromBeeingDismissed` and set it to true.
    override var canResignFirstResponder: Bool {
        let canDoIt = preventKeyboardFromBeeingDismissed.inverted
        preventKeyboardFromBeeingDismissed = true
        return canDoIt
    }
    
    /// `UIViewController`'s `inputAccessoryView` variable.
    ///
    /// Returns `toolbar`.
    override var inputAccessoryView: UIView? {
        return toolbar
    }
    
    /// `UIViewController`'s `viewWillTransition(to:, with:)` function.
    ///
    /// Resize `webView`, dismiss and open keyboard (to resize terminal).
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if isFirstResponder {
            preventKeyboardFromBeeingDismissed = false
            resignFirstResponder()
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.becomeFirstResponder()
        })
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            let newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.webView.frame = newFrame
        })
    }
    
    /// `UIViewController`'s `keyCommands` variable.
    ///
    /// Returns arrow keys, esc keys and ctrl keys from `A` to `_`.
    override var keyCommands: [UIKeyCommand]? {
        // Bluetooth keyboard
        
        var commands =  [
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
    
    /// `UIViewController`'s `viewDidLoad` function.
    ///
    /// Add notifications to resize `webView` when keyboard appears.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize webView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /// `UIViewController``s `viewWillAppear(_:)` function.
    ///
    /// Close and open shell, add `toolbar` to keyboard and configure `navigationController`.
    override func viewWillAppear(_ animated: Bool) {
        
        if console.isEmpty {
            
            if !pureMode {
                ConnectionManager.shared.session?.channel.closeShell()
                try? ConnectionManager.shared.session?.channel.startShell()
            }
            
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .never
            }
            
            addToolbar()
        }
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    /// `UIViewController``s `viewDidAppear(_:)` function.
    ///
    /// Init `webView`.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if console.isEmpty {
            // Create WebView
            webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            view.addSubview(webView)
            webView.backgroundColor = .black
            webView.navigationDelegate = self
            webView.scrollView.isScrollEnabled = false
            if !readOnly {
                becomeFirstResponder()
            } else {
                preventKeyboardFromBeeingDismissed = false
            }
            webView.loadFileURL(Bundle.main.bundleURL.appendingPathComponent("terminal.html"), allowingReadAccessTo: Bundle.main.bundleURL)
        }
    }
    
    /// `UIViewController``s `viewWillDisappear(_:)` function.
    ///
    /// Undo changes made to `navigationController` and dismiss `ArrowsViewController` if it's presented.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        
        ArrowsViewController.current?.dismiss(animated: true, completion: nil)
    }
    
    /// `UIViewController``s `prefersStatusBarHidden` variable.
    ///
    /// - Returns: `true`.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Keyboard
    
    /// Resize `webView` when keyboard will show.
    @objc func keyboardWillShow(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            
            webView.frame.size.height -= keyboardSize.height
            webView.reload()
        }
    }
    
    /// Resize `webView` when keyboard will hide.
    @objc func keyboardWillHide(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            
            webView.frame.size.height += keyboardSize.height
            webView.reload()
        }
    }
    
    /// Send arrow keys.
    ///
    /// - Parameters:
    ///     - sender: Sender bar button item.
    @objc func sendArrows(_ sender: UIBarButtonItem) {
        let arrowsVC = ArrowsViewController()
        arrowsVC.modalPresentationStyle = .popover
        arrowsVC.preferredContentSize = CGSize(width: 200, height: 200)
        
        if let popover = arrowsVC.popoverPresentationController {
            popover.barButtonItem = sender
            popover.delegate = arrowsVC
            popover.backgroundColor = .clear
            
            self.present(arrowsVC, animated: true, completion: nil)
        }
    }
    
    /// Insert special key.
    ///
    /// - Parameters:
    ///     - sender: Sender bar button item.
    @objc func insertKey(_ sender: UIBarButtonItem) {
        
        guard let channel = ConnectionManager.shared.session?.channel else { return }
        
        if sender.tag == 1 { // ctrl
            ctrl = ctrl.inverted
        } else if sender.tag == 6 { // Esc
            try? channel.write(Keys.esc)
        } else if sender.tag == 7 { // F keys
            let commandsVC = CommandsTableViewController()
            commandsVC.title = "Function keys"
            commandsVC.commands = [[Keys.f1, "F1"], [Keys.f2, "F2"], [Keys.f3, "F3"], [Keys.f4, "F4"], [Keys.f5, "F5"], [Keys.f6, "F6"], [Keys.f7, "F7"], [Keys.f8, "F8"], [Keys.f9, "F9"], [Keys.f10, "F10"], [Keys.f11, "F11"], [Keys.f12, "F12"]]
            commandsVC.modalPresentationStyle = .popover
            
            if let popover = commandsVC.popoverPresentationController {
                popover.barButtonItem = sender
                popover.delegate = commandsVC
                
                self.present(commandsVC, animated: true, completion: nil)
            }
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
    
    /// `NMSSHChannelDelegate`'s `channel(_:, didReadData:)` function.
    ///
    /// Write data to `webView`.
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            
            if self.console.contains(TerminalViewController.close) { // Close shell
                self.preventKeyboardFromBeeingDismissed = false
                self.console = self.console.replacingOccurrences(of: TerminalViewController.close, with: "")
                self.resignFirstResponder()
            }
            
            if self.webView != nil {
                self.webView.evaluateJavaScript("writeText(\(message.javaScriptEscapedString))", completionHandler: { (_, _) in
                    
                    // Scroll to top if dontScroll is true
                    if self.dontScroll {
                        self.webView.evaluateJavaScript("term.scrollToTop()", completionHandler: { (returnValue, error) in
                            if let returnValue = returnValue {
                                print(returnValue)
                            }
                            
                            if let error = error {
                                print(error)
                            }
                        })
                    }
                })
            }
        }
    }
    
    /// `NMSSHChannelDelegate`'s `channelShellDidClose(_:)` function.
    ///
    /// Undo changes made to `navigationController` and pop to Root view controller.
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    // MARK: Key input
    
    /// `UIKeyInput`'s `insertText(_:)` function.
    ///
    /// Send text or ctrl key to shell.
    func insertText(_ text: String) {
        do {
            if !ctrl {
                try ConnectionManager.shared.session?.channel.write(text.replacingOccurrences(of: "\n", with: Keys.unicode(dec: 13)))
            } else {
                try ConnectionManager.shared.session?.channel.write(Keys.ctrlKey(from: text))
                ctrl = false
            }
        } catch {}
    }
    
    /// `UIKeyInput`'s `deleteBackward` function.
    ///
    /// Send backspace to shell.
    func deleteBackward() {
        do {
            try ConnectionManager.shared.session?.channel.write(Keys.delete)
        } catch {}
    }
    
    /// `UIKeyInput`s `hasText` variable.
    ///
    /// Returns true.
    var hasText: Bool {
        return true
    }
    
    // MARK: Text input traits
    
    /// `UITextInputTraits`'s `keyboardAppearance` variable.
    ///
    /// `UIKeyboardAppearance.dark`
    var keyboardAppearance: UIKeyboardAppearance = .dark
    
    /// `UITextInputTraits`'s `autocorrectionType` variable.
    ///
    /// `UITextAutocorrectionType.no`
    var autocorrectionType: UITextAutocorrectionType = .no
    
    
    // MARK: Web kit navigation delegate

    /// `WKNavigationDelegate`'s `webView(_:, didFinish:)` function.
    ///
    /// Run startup commands if `console` is empty, enable blinking cursor if `UserDefaults` 'blink' value is `true` and resize terminal if the Web view was reloaded.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if UserDefaults.standard.bool(forKey: "blink") {
            webView.evaluateJavaScript("term.setOption('cursorBlink', true)", completionHandler: nil)
        }
        
        if console.isEmpty {
            
            // Session
            guard let session = ConnectionManager.shared.session else {
                navigationController?.popViewController(animated: true)
                return
            }
            
            if !session.isConnected {
                let errorMessage = "\(Keys.esc)[0;31mError connecting! Check for connection's host and your internet connection.\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("writeText(\(errorMessage))", completionHandler: nil)
                preventKeyboardFromBeeingDismissed = false
                resignFirstResponder()
                return
            }
            
            if !session.isAuthorized {
                let errorMessage = "\(Keys.esc)[0;31mError authenticating! Check for username and password.\(Keys.esc)[0m".javaScriptEscapedString
                webView.evaluateJavaScript("writeText(\(errorMessage))", completionHandler: nil)
                preventKeyboardFromBeeingDismissed = false
                resignFirstResponder()
                return
            }
            
            do {
                
                session.channel.delegate = self
                
                if !self.pureMode {
                    let clearLastFromHistory = "history -d $(history 1)"
                    
                    if let pwd = self.pwd {
                        try session.channel.write("cd '\(pwd)'; \(clearLastFromHistory)\n")
                    }
                    
                    for command in ShellStartup.commands {
                        try session.channel.write("\(command); \(clearLastFromHistory);\n")
                    }
                    
                    try session.channel.write("clear; \(clearLastFromHistory)\n")
                    
                    if let command = self.command {
                        try session.channel.write("\(command);\n")
                    }
                } else {
                    try session.channel.startShell()
                    toolbar.items?[1].isEnabled = false
                }
                
                changeSize(completion: nil)
            } catch {
            }
        } else {
            webView.evaluateJavaScript("writeText(\(self.console.javaScriptEscapedString))", completionHandler: nil)
            changeSize(completion: nil)
        }
    }
    
    // MARK: - Static
    
    /// Print this to dismiss the keyboard (from SSH).
    static let close = "\(Keys.esc)[CLOSE"
}
