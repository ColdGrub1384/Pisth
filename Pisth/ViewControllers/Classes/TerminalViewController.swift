// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import WebKit

class TerminalViewController: UIViewController, NMSSHChannelDelegate, WKNavigationDelegate, UIKeyInput, UITextInputTraits {
    
    static var close = "\(Keys.esc)[CLOSE" // Print this to dismiss the keyboard
    
    var pwd: String?
    var console = ""
    var command: String?
    var ctrlKey: UIBarButtonItem!
    var preventKeyboardFronBeeingDismissed = true
    var toolbar: UIToolbar!
    var dontScroll = false
    private var ctrl_ = false
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
    
    var navBarHeight: CGFloat {
        return AppDelegate.shared.navigationController.navigationBar.frame.height+UIApplication.shared.statusBarFrame.height
    }
    
    var readOnly = false
    var webView: WKWebView!
    
    func addToolbar() { // Add keyboard's toolbar
        let toolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        // Buttons
        
        ctrlKey = UIBarButtonItem(title: "Ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
        ctrlKey.tag = 1
        
        let escKey = UIBarButtonItem(title: "⎋", style: .done, target: self, action: #selector(insertKey(_:)))
        escKey.setTitleTextAttributes([NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 25)], for: .normal)
        escKey.tag = 6
        
        // ⬅︎⬆︎⬇︎➡︎
        let leftArrow = UIBarButtonItem(title: "⬅︎", style: .done, target: self, action: #selector(insertKey(_:)))
        leftArrow.tag = 2
        let upArrow = UIBarButtonItem(title: "⬆︎", style: .done, target: self, action: #selector(insertKey(_:)))
        upArrow.tag = 3
        let downArrow = UIBarButtonItem(title: "⬇︎", style: .done, target: self, action: #selector(insertKey(_:)))
        downArrow.tag = 4
        let rightArrow = UIBarButtonItem(title: "➡︎", style: .done, target: self, action: #selector(insertKey(_:)))
        rightArrow.tag = 5
        
        
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let items = [ctrlKey, leftArrow, space, upArrow, downArrow, space, rightArrow, escKey] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        self.toolbar = toolbar
    }
    
    override var canBecomeFirstResponder: Bool {
        return (webView != nil)
    }

    override var canResignFirstResponder: Bool {
        let canDoIt = preventKeyboardFronBeeingDismissed.inverted
        preventKeyboardFronBeeingDismissed = true
        return canDoIt
    }
    
    override var inputAccessoryView: UIView? {
        return toolbar
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if isFirstResponder {
            preventKeyboardFronBeeingDismissed = false
            resignFirstResponder()
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.becomeFirstResponder()
        })
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            let newFrame = CGRect(x: 0, y: self.navBarHeight, width: size.width, height: size.height)
            self.webView.frame = newFrame
        })
    }
    
    override var keyCommands: [UIKeyCommand]? {
        // Bluetooth keyboard
        
        var commands =  [
            UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Up Arrow"),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Down Arrow"),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Left Arrow"),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Right Arrow"),
            UIKeyCommand(input: UIKeyInputEscape, modifierFlags: .init(rawValue: 0), action: #selector(write(fromCommand:)), discoverabilityTitle: "Send Esc key")
        ]
        
        let ctrlKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_"] // All CTRL keys
        for ctrlKey in ctrlKeys {
            commands.append(UIKeyCommand(input: ctrlKey, modifierFlags: .control, action: #selector(write(fromCommand:)), discoverabilityTitle: "Send ^\(ctrlKey)"))
        }
        
        return commands
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize webView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if console.isEmpty {
            
            ConnectionManager.shared.session?.channel.closeShell()
            try? ConnectionManager.shared.session?.channel.startShell()
            
            // Show commands history
            let history = UIBarButtonItem(image: #imageLiteral(resourceName: "history"), style: .plain, target: self, action: #selector(showHistory(_:)))
            navigationItem.setRightBarButtonItems([history], animated: true)
            
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .never
            }
            
            addToolbar()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create WebView
        webView = WKWebView(frame: CGRect(x: 0, y: navBarHeight, width: view.frame.width, height: view.frame.height))
        view.addSubview(webView)
        webView.backgroundColor = .black
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        if !readOnly {
            becomeFirstResponder()
        } else {
            preventKeyboardFronBeeingDismissed = false
        }
        webView.loadFileURL(Bundle.main.bundleURL.appendingPathComponent("terminal.html"), allowingReadAccessTo: Bundle.main.bundleURL)
    }
    
    @objc func showHistory(_ sender: UIBarButtonItem) { // Show commands history
        
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
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            
            webView.frame.size.height -= keyboardSize.height+inputAccessoryView!.frame.height
            webView.reload()
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            
            webView.frame.size.height += keyboardSize.height+inputAccessoryView!.frame.height
            webView.reload()
        }
    }
    
    func changeSize(completion: (() -> Void)?) { // Change terminal size to page size
        
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
    
    // Insert special key
    @objc func insertKey(_ sender: UIBarButtonItem) {
        
        guard let channel = ConnectionManager.shared.session?.channel else { return }
        
        if sender.tag == 1 { // ctrl
            ctrl = ctrl.inverted
        } else if sender.tag == 6 { // Esc
            try? channel.write(Keys.esc)
        } else if sender.tag == 2 { // Left arrow
            try? channel.write(Keys.arrowLeft)
        } else if sender.tag == 3 { // Up arrow
            try? channel.write(Keys.arrowUp)
        } else if sender.tag == 4 { // Down arrow
            try? channel.write(Keys.arrowDown)
        } else if sender.tag == 5 { // Right arrow
            try? channel.write(Keys.arrowRight)
        }
    }
    
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
    
    // MARK: NMSSHChannelDelegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            
            if self.console.contains(TerminalViewController.close) { // Close shell
                self.preventKeyboardFronBeeingDismissed = false
                self.console = self.console.replacingOccurrences(of: TerminalViewController.close, with: "")
                self.resignFirstResponder()
            }
            
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
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: UIKeyInput
    
    func insertText(_ text: String) {
        do {
            if !ctrl {
                try ConnectionManager.shared.session?.channel.write(text)
            } else {
                try ConnectionManager.shared.session?.channel.write(Keys.ctrlKey(from: text))
                ctrl = false
            }
        } catch {}
    }
    
    func deleteBackward() {
        do {
            try ConnectionManager.shared.session?.channel.write(Keys.delete)
        } catch {}
    }
    
    var hasText: Bool {
        return true
    }
    
    // MARK: UITextInputTraits
    
    var keyboardAppearance: UIKeyboardAppearance = .dark
    var autocorrectionType: UITextAutocorrectionType = .no
    
    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { // Get colored output
        
        if UserDefaults.standard.bool(forKey: "blink") {
            webView.evaluateJavaScript("term.setOption('cursorBlink', true)", completionHandler: nil)
        }
        
        if console.isEmpty {
            
            // Session
            guard let session = ConnectionManager.shared.session else {
                navigationController?.popViewController(animated: true)
                return
            }
            
            do {
                
                session.channel.delegate = self
                
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
                
                changeSize(completion: nil)
            } catch {
            }
        } else {
            webView.evaluateJavaScript("writeText(\(self.console.javaScriptEscapedString))", completionHandler: nil)
            changeSize(completion: nil)
        }
    }
}
