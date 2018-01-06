// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import WebKit

class TerminalViewController: UIViewController, NMSSHChannelDelegate, WKNavigationDelegate, UITextInputTraits, UIKeyInput {
    
    static let clear = "\(Keys.esc)[H\(Keys.esc)[J" // Echo this to clear the screen
    static let backspace = "\(Keys.esc)[H"
    
    @IBOutlet weak var webView: WKWebView!
    var pwd: String?
    var console = ""
    var command: String?
    var consoleANSI = ""
    var consoleHTML = ""
    var logout = false
    var ctrlKey: UIBarButtonItem!
    var ctrl = false
    
    func htmlTerminal(withOutput output: String) -> String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!).replacingOccurrences(of: "$_ANSIOUTPUT_", with: output.javaScriptEscapedString)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        ctrlKey = UIBarButtonItem(title: "ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
        ctrlKey.tag = 1
        
        // ⬅︎⬆︎⬇︎➡︎
        let leftArrow = UIBarButtonItem(title: "⬅︎", style: .done, target: self, action: #selector(insertKey(_:)))
        leftArrow.tag = 2
        let upArrow = UIBarButtonItem(title: "⬆︎", style: .done, target: self, action: #selector(insertKey(_:)))
        upArrow.tag = 3
        let downArrow = UIBarButtonItem(title: "⬇︎", style: .done, target: self, action: #selector(insertKey(_:)))
        downArrow.tag = 4
        let rightArrow = UIBarButtonItem(title: "➡︎", style: .done, target: self, action: #selector(insertKey(_:)))
        rightArrow.tag = 5
        
        let items = [ctrlKey, leftArrow, upArrow, downArrow, rightArrow] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !logout {
            guard let session = ConnectionManager.shared.session else {
                navigationController?.popViewController(animated: true)
                return
            }
            
            // Show commands history
            let history = UIBarButtonItem(image: #imageLiteral(resourceName: "history"), style: .plain, target: self, action: #selector(showHistory(_:)))
            navigationItem.rightBarButtonItem = history
            
            navigationItem.largeTitleDisplayMode = .never
            
            webView.navigationDelegate = self
            
            // Session
            do {
                
                session.channel.delegate = self
                
                let clearLastFromHistory = "history -d $(history 1)"
                
                if let pwd = pwd {
                    try session.channel.write("cd '\(pwd)'; \(clearLastFromHistory)\n")
                }
                
                try session.channel.write("clear; \(clearLastFromHistory)\n")
                
                if let command = self.command {
                    try session.channel.write("\(command); sleep 0.1; \(clearLastFromHistory)\n")
                }
                
                becomeFirstResponder()
            } catch {
            }
        }
        
        logout = false
    }

    @objc func writeText(_ text: String) { // Write command without writing it in the textView
        do {
            try ConnectionManager.shared.session?.channel.write(text)
        } catch {
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
    
    // Insert special key
    @objc func insertKey(_ sender: UIBarButtonItem) {
        if sender.tag == 1 { // ctrl
            ctrl = true
            sender.isEnabled = false
        } else if sender.tag == 2 { // Left arrow
            writeText(Keys.arrowLeft)
        } else if sender.tag == 3 { // Up arrow
            writeText(Keys.arrowUp)
        } else if sender.tag == 4 { // Down arrow
            writeText(Keys.arrowDown)
        } else if sender.tag == 5 { // Right arrow
            writeText(Keys.arrowRight)
        }
    }
    
    // MARK: NMSSHChannelDelegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.consoleANSI = self.consoleANSI+message
            
            print("ANSI OUTPUT: \n"+self.consoleANSI)
            print("PLAIN OUTPUT: \n"+self.console)
            
            /*if self.consoleANSI.contains(TerminalViewController.clear) { // Clear shell
                self.consoleANSI = self.consoleANSI.components(separatedBy: TerminalViewController.clear)[1]
            }
            
            if self.consoleANSI.contains(TerminalViewController.backspace) {
                print("BACKSPACE DETECTED!")
            }*/
            
            self.webView.loadHTMLString(self.htmlTerminal(withOutput: self.consoleANSI), baseURL: Bundle.main.bundleURL)
        }
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            DirectoryTableViewController.disconnected = true
            
            self.navigationController?.popToRootViewController(animated: true, completion: {
                self.logout = true
                AppDelegate.shared.navigationController.pushViewController(self, animated: true)
            })
        }
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { // Get colored output
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html, error) in
            if let html = html as? String {
                print(html)
                self.console = html.html2AttributedString?.string ?? self.console
                self.consoleHTML = html.html2String
            }
        }
    }
    
    // MARK: - UIKeyInput
    
    var hasText: Bool {
        return (consoleANSI.isEmpty == false)
    }
    
    func insertText(_ text: String) {
        do {
            if !ctrl {
                try ConnectionManager.shared.session?.channel.write(text)
            } else { // Insert control key
                ctrlKey.isEnabled = true
                try ConnectionManager.shared.session?.channel.write(Keys.ctrlKey(from: text))
            }
        } catch {}
    }
    
    func deleteBackward() {
        do {
            try ConnectionManager.shared.session?.channel.write(Keys.ctrlH)
        } catch {}
    }
}
