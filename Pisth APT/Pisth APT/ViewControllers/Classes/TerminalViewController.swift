// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit
import Pisth_Terminal
import Pisth_Shared
import NMSSH
import BiometricAuthentication

/// View controller for displaying the terminal.
class TerminalViewController: UIViewController, WKNavigationDelegate, NMSSHChannelDelegate {
    
    /// Activity indicator shown before showing data from the server.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /// Web view displaying the terminal
    @IBOutlet weak var webView: WKWebView!
    
    /// Button to close this view controller.
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    /// Close this view controller.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: {
            
            let activityVC = ActivityViewController(message: "Loading...")
            UIApplication.shared.keyWindow?.topViewController()?.present(activityVC, animated: true) {
                AppDelegate.shared.searchForUpdates()
                activityVC.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    /// Content of the terminal.
    var console = ""
    
    /// Command to execute.
    var command: String?
    
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
            AppDelegate.shared.shellSession?.channel.requestSizeWidth(cols, height: rows)
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
    
    /// Send the user password.
    func sendPassword() {
        
        guard let connection = AppDelegate.shared.connection else {
            return
        }
        
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "Authenticate to send '\(connection.username)' password.", fallbackTitle: "Enter password", cancelTitle: "Cancel", success: {
            
            try? AppDelegate.shared.shellSession?.channel.write(connection.password+"\n")
            
        }, failure: { (error) in
            
            if error == .biometryNotEnrolled || error == .passcodeNotSet || error == .biometryNotAvailable {
                try? AppDelegate.shared.shellSession?.channel.write(connection.password+"\n")
            }
            
            if error == .canceledByUser || error == .canceledBySystem {
                self.done(self)
            }
            
            if error == .fallback {
                let alert = UIAlertController(title: "Enter password", message: "Enter sudo password for '\(connection.username)'.", preferredStyle: .alert)
                
                alert.addTextField(configurationHandler: { (textField) in
                    textField.isSecureTextEntry = true
                    textField.placeholder = "Password"
                })
                
                alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (_) in
                    try? AppDelegate.shared.shellSession?.channel.write((alert.textFields?[0].text ?? "")+"\n")
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    self.done(self)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - View controller
    
    /// Reload web view.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        webView.reload()
    }
    
    /// Setup the terminal
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.backgroundColor = .clear
        
        guard let session = AppDelegate.shared.shellSession else {
            self.dismiss(animated: true, completion: nil)
            return
        }

         session.channel.closeShell()
        
        do {
            try session.channel.startShell()
            session.channel.delegate = self
        } catch {
            let alert = UIAlertController(title: "Cannot initialize the shell!", message: "Check for your internet connection and the your selected connection information.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            present(alert, animated: true, completion: nil)
        }
        
        if let terminal = Bundle.terminal.url(forResource: "terminal", withExtension: "html") {
            webView.navigationDelegate = self
            webView.loadFileURL(terminal, allowingReadAccessTo: URL(string: "file:///")!)
        }
    }
    
    // MARK: - Navigation delegate
    
    /// Setup the terminal and send commands.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("fit(term)") { (_, _) in
            self.changeSize {
                self.webView.evaluateJavaScript("term.write(\(self.console.components(separatedBy: TerminalViewController.close)[0].javaScriptEscapedString))", completionHandler: {_, _ in
                    
                    if let cmd = self.command {
                        self.command = nil
                        try? AppDelegate.shared.shellSession?.channel.write(cmd+"\n")
                    }
                    
                    self.activityIndicator.isHidden = true
                })
            }
        }
    }
    
    // MARK: - Channel delegate
    
    /// Show received data.
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console += message
            
            if message.contains("[sudo] password") {
                self.sendPassword()
            }
        
            if self.console.contains(TerminalViewController.close) {
                self.doneButton.isEnabled = true
                self.title = "FInished!"
            }
            
            if self.webView != nil && !self.webView.isLoading {
                self.webView.evaluateJavaScript("term.write(\(message.components(separatedBy: TerminalViewController.close)[0].javaScriptEscapedString))", completionHandler: nil)
            }
        }
    }
    
    // MARK: - Static
    
    /// Print this to dismiss the keyboard (from SSH).
    static let close = "\(Keys.esc)[CLOSE"
}
