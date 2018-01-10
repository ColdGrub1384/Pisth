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
    
    var webView: WKWebView!
    
    var pwd: String?
    var console = ""
    var command: String?
    var ctrlKey: UIBarButtonItem!
    private var ctrl_ = false
    var ctrl: Bool {
        set {
            ctrl_ = newValue
            if ctrl_ {
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
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var canResignFirstResponder: Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? { // Keyboard's toolbar
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        // Buttons
        
        ctrlKey = UIBarButtonItem(title: "ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
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
        
        return toolbar
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if isFirstResponder {
            resignFirstResponder()
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.becomeFirstResponder()
        })
        
        let newFrame = CGRect(x: 0, y: navBarHeight, width: size.width, height: size.height)
        webView.frame = newFrame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize webView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Create WebView
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        view.addSubview(webView)
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
            
            becomeFirstResponder()
            webView.backgroundColor = .black
            webView.navigationDelegate = self
            webView.scrollView.isScrollEnabled = false
            webView.loadFileURL(Bundle.main.bundleURL.appendingPathComponent("terminal.html"), allowingReadAccessTo: Bundle.main.bundleURL)
        }
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
            
            webView.frame.size.height -= keyboardSize.height
            webView.reload()
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            
            webView.frame.size.height += keyboardSize.height
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
    
    // MARK: NMSSHChannelDelegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            self.webView.evaluateJavaScript("writeText(\(message.javaScriptEscapedString))", completionHandler: nil)
        }
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            DirectoryTableViewController.disconnected = true
            
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
            try ConnectionManager.shared.session?.channel.write(Keys.ctrlH)
        } catch {}
    }
    
    var hasText: Bool {
        return true
    }
    
    // MARK: UITextInputTraits
    
    var keyboardAppearance: UIKeyboardAppearance = .dark
    var autocorrectionType: UITextAutocorrectionType = .no
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
