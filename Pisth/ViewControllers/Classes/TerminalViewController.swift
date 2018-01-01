//
//  TerminalViewController.swift
//  Pisth
//
//  Created by Adrian on 28.12.17.
//

import UIKit
import NMSSH
import WebKit

class TerminalViewController: UIViewController, NMSSHChannelDelegate, UITextViewDelegate, WKNavigationDelegate {
    
    static let clear = "\(Keys.esc)[H\(Keys.esc)[J" // Echo this to clear the screen
    
    @IBOutlet weak var textView: TerminalTextView!
    var pwd: String?
    var console = ""
    var command: String?
    var consoleANSI = ""
    var consoleHTML = ""
    var logout = false
    var ctrlKey: UIBarButtonItem!
    var ctrl = false
    var webView = WKWebView()
    
    func htmlTerminal(withOutput output: String) -> String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!).replacingOccurrences(of: "$_ANSIOUTPUT_", with: output.javaScriptEscapedString)
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
           
            // textView's toolbar
            let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            toolbar.barStyle = .black
                
            ctrlKey = UIBarButtonItem(title: "ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
            ctrlKey.tag = 1
            
            // ⬅︎⬆︎⬇︎➡︎
            /*let leftArrow = UIBarButtonItem(title: "⬅︎", style: .done, target: self, action: #selector(insertKey(_:)))
            leftArrow.tag = 2
            let upArrow = UIBarButtonItem(title: "⬆︎", style: .done, target: self, action: #selector(insertKey(_:)))
            upArrow.tag = 3
            let downArrow = UIBarButtonItem(title: "⬇︎", style: .done, target: self, action: #selector(insertKey(_:)))
            downArrow.tag = 4
            let rightArrow = UIBarButtonItem(title: "➡︎", style: .done, target: self, action: #selector(insertKey(_:)))
            rightArrow.tag = 5*/
            
            let items = [ctrlKey, /*leftArrow, upArrow, downArrow, rightArrow*/] as [UIBarButtonItem]
            toolbar.items = items
            toolbar.sizeToFit()
            
            // textView
            textView.inputAccessoryView = toolbar
            textView.text = "\n\n\n"
            textView.keyboardAppearance = .dark
            textView.autocorrectionType = .no
            textView.autocapitalizationType = .none
            textView.delegate = self
            textView.tintColor = .white
            textView.isEditable = false
            
            webView.navigationDelegate = self
            
            // Resize textView
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            
            // Session
            session.channel.delegate = self
            do {
                session.channel.requestPty = true
                session.channel.ptyTerminalType = .ansi
                try session.channel.startShell()
                if let pwd = pwd {
                    try session.channel.write("cd '\(pwd)'\n")
                }
                
                
                for command in ShellStartup.commands {
                    try session.channel.write("\(command)\n")
                }
                
                try session.channel.write("clear\n")
                
                if let command = command {
                    try session.channel.write("\(command)\n")
                }
                
                textView.isEditable = true
                textView.becomeFirstResponder()
            } catch let error {
                textView.text = error.localizedDescription
            }
        }
        
        logout = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ConnectionManager.shared.session?.channel.closeShell()
    }
    
    @objc func writeText(_ text: String) { // Write command without writing it in the textView
        do {
            try ConnectionManager.shared.session?.channel.write(text)
        } catch {
            textView.text = error.localizedDescription
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
    
    // MARK: Keyboard
    
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
    }
    
    // Insert special key
    @objc func insertKey(_ sender: UIBarButtonItem) {
        if sender.tag == 1 { // ctrl
            ctrl = true
            sender.isEnabled = false
        } else if sender.tag == 2 { // Left arrow
            textView.text = consoleHTML
            writeText(Keys.arrowLeft)
        } else if sender.tag == 3 { // Up arrow
            textView.text = consoleHTML
            writeText(Keys.arrowUp)
        } else if sender.tag == 4 { // Down arrow
            textView.text = consoleHTML
            writeText(Keys.arrowDown)
        } else if sender.tag == 5 { // Right arrow
            textView.text = consoleHTML
            writeText(Keys.arrowRight)
        }
    }
    
    // Resize textView
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
    
    // MARK: NMSSHChannelDelegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            
            self.console = self.textView.text+message
            self.consoleANSI = self.consoleANSI+message
                        
            print("ANSI OUTPUT: \n"+self.consoleANSI)
            print("PLAIN OUTPUT: \n"+self.console)
            
            if self.consoleANSI.contains(TerminalViewController.clear) { // Clear shell
                self.consoleANSI = self.consoleANSI.components(separatedBy: TerminalViewController.clear)[1]
                self.console = self.console.components(separatedBy: TerminalViewController.clear)[1]
            }
            
            self.webView.loadHTMLString(self.htmlTerminal(withOutput: self.consoleANSI), baseURL: Bundle.main.bundleURL)
        }
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            self.textView.resignFirstResponder()
            
            DirectoryTableViewController.disconnected = true
            
            self.navigationController?.popToRootViewController(animated: true, completion: {
                self.logout = true
                AppDelegate.shared.navigationController.pushViewController(self, animated: true)
            })
            
            self.textView.isEditable = false
        }
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if ctrl { // CTRL key
            
            ctrlKey.isEnabled = true
            
            print("CTRL KEY: "+text)
            
            writeText(Keys.ctrlKey(from: text))
            
            ctrl = false
            return ctrl
        }
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).count >= console.count {
            if text.contains("\n") {
                let newConsole = textView.text+text
                let console = self.console
                print("newConsole: \(newConsole)")
                let cmd = newConsole.replacingOccurrences(of: console, with: "")
                print("Command: { \(cmd) }")
                do {
                    let range = newConsole.range(of: cmd)
                    textView.text = newConsole.replacingCharacters(in: range!, with: "")
                    
                    try ConnectionManager.shared.session?.channel.write(cmd)
                    return false
                } catch {}
            }
            
            
            return true
        }
        
        return false
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { // Get colored output
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html, error) in
            if let html = html as? String {
                print(html)
                self.textView.text = html.html2String
                self.textView.attributedText = html.html2AttributedString
                self.console = self.textView.text
                self.consoleHTML = html.html2String
                self.textView.scrollToBotom()
                print("HTML OUTPUT: \n"+html)
            }
        }
    }
}
