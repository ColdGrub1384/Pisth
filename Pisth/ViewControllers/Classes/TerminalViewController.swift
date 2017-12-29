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
    
    static let clear = "ClEaRtHeScReEnNoW" // Echo this to clear the screen
    
    @IBOutlet weak var textView: TerminalTextView!
    var pwd: String?
    var console = ""
    var consoleANSI = ""
    
    var webView = WKWebView()
    
    func htmlTerminal(withOutput output: String) -> String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!).replacingOccurrences(of: "$_ANSIOUTPUT_", with: output.javaScriptEscapedString)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let session = ConnectionManager.shared.session else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        navigationItem.largeTitleDisplayMode = .never
        
        textView.text = "\n\n\n"
        textView.keyboardAppearance = .dark
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.delegate = self
        textView.tintColor = .white
        
        webView.navigationDelegate = self
        
        // Resize textView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Session
        session.channel.delegate = self
        do {
            session.channel.requestSizeWidth(UInt(self.view.frame.size.width), height: UInt(self.view.frame.size.height))
            session.channel.requestPty = true
            session.channel.ptyTerminalType = .ansi
            try session.channel.startShell()
            textView.becomeFirstResponder()
            if let pwd = pwd {
                try session.channel.write("cd '\(pwd)'\n")
            }
            try session.channel.write("alias clear='echo Cl\\EaRtHeScReEnNoW'\n")
            try session.channel.write("clear\n")
        } catch let error {
            textView.text = error.localizedDescription
        }
    }
    
    // MARK: Keyboard
    
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
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
        }
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
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
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { // Get colored output
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html, error) in
            if let html = html as? String {
                print(html)
                self.textView.text = html.html2String
                self.textView.attributedText = html.html2AttributedString
                self.console = self.textView.text
                self.textView.scrollToBotom()
            }
        }
    }
}
