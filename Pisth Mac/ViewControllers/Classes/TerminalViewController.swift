// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import WebKit
import Pisth_Terminal
import Pisth_Shared

/// A terminal running a remote shell.
class TerminalViewController: NSViewController, WKNavigationDelegate, WKUIDelegate, NMSSHChannelDelegate, NSWindowDelegate {
    
    /// The `ConnectionController` that controls the connection for this terminal.
    var controller: ConnectionController!

    /// The root window.
    var window: NSWindow!
    
    /// Theme used by the terminal.
    var theme = TerminalTheme.themes["Basic"]!
    
    /// The text received from the server.
    var console = ""
    
    /// The Web view showing the terminal.
    @IBOutlet weak var webView: WKWebView!
    
    private var terminalCols: UInt?
    private var terminalRows: UInt?
    
    /// Set the window title.
    ///
    /// - Parameters:
    ///     - title: The title of the window. The size of the terminal will be added.
    func setTitle(_ title: String) {
        var title_ = title
        
        if let cols = terminalCols, let rows = terminalRows {
            title_ += " - \(cols)x\(rows)"
        }
        
        self.title = title_
        window.title = title_
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
            terminalCols = cols
            terminalRows = rows
            controller.shellSession.channel.requestSizeWidth(cols, height: rows)
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
    
    // MARK: - View controller
    
    /// Load the terminal.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.setValue(false, forKey: "drawsBackground")
        if let term = Bundle.terminal.url(forResource: "terminal", withExtension: "html") {
            webView.loadFileURL(term, allowingReadAccessTo: Bundle.terminal.bundleURL)
        }
        
        _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { (event) -> NSEvent? in
            guard var character = event.characters else {
                return nil
            }
            
            guard let utf16view = event.charactersIgnoringModifiers?.utf16 else {
                return nil
            }
            
            let key = Int(utf16view[utf16view.startIndex])
            
            switch key {
                
            // Arrow keys
            case NSUpArrowFunctionKey:
                character = Keys.arrowUp
            case NSDownArrowFunctionKey:
                character = Keys.arrowDown
            case NSLeftArrowFunctionKey:
                character = Keys.arrowLeft
            case NSRightArrowFunctionKey:
                character = Keys.arrowRight
                
            // Function Keys
            case NSF1FunctionKey:
                character = Keys.f1
            case NSF2FunctionKey:
                character = Keys.f2
            case NSF3FunctionKey:
                character = Keys.f3
            case NSF4FunctionKey:
                character = Keys.f4
            case NSF5FunctionKey:
                character = Keys.f5
            case NSF6FunctionKey:
                character = Keys.f6
            case NSF7FunctionKey:
                character = Keys.f7
            case NSF8FunctionKey:
                character = Keys.f8
            case NSF2FunctionKey:
                character = Keys.f2
            case NSF9FunctionKey:
                character = Keys.f9
            case NSF10FunctionKey:
                character = Keys.f10
            case NSF11FunctionKey:
                character = Keys.f11
            default:
                break
            }
            
            if event.modifierFlags.rawValue != 1048840 {
                try? self.controller.shellSession.channel.write(character)
            }
            
            return event
        })
    }
    
    // MARK: - SSH channel delegate
    
    /// Show message.
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        console += message
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("term.write(\(message.javaScriptEscapedString))", completionHandler: nil)
        }
    }
    
    /// Print a message.
    func channelShellDidClose(_ channel: NMSSHChannel!) {
    
        let text = "\n\rConnection to \(channel.session.host!) closed."
        console += text
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("term.write(\(text.javaScriptEscapedString))", completionHandler: nil)
        }
    }
    
    // MARK: - Web kit navigation delegate
    
    /// Set theme, set size and start shell.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        window.delegate = self
        
        webView.evaluateJavaScript("term.write(\(console.javaScriptEscapedString))", completionHandler: nil)
        webView.evaluateJavaScript("term.setOption('theme', \(theme.javascriptValue))", completionHandler: nil)
        webView.evaluateJavaScript("document.body.style.backgroundColor = document.getElementsByClassName('xterm-viewport')[0].style.backgroundColor", completionHandler: nil)
        webView.evaluateJavaScript("term.setOption('fontSize', 12)", completionHandler: nil)
        webView.evaluateJavaScript("fit(term)") { (_, _) in
            if self.console == "" {

                let channel = self.controller.shellSession.channel
                
                do {
                    try channel?.startShell()
                    channel?.delegate = self
                } catch {
                    NSApp.presentError(error)
                }
            }
            self.changeSize(completion: nil)
        }
    }
    
    
    // MARK: - Web kit UI delegate
    
    /// Set title.
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        if message.hasPrefix("changeTitle") {
            setTitle(message.replacingFirstOccurrence(of: "changeTitle", with: ""))
        }
        
        completionHandler()
    }
    
    // MARK: - Window controller
    
    /// Reload `webView`.
    func windowDidResize(_ notification: Notification) {
        webView.reload()
    }
}
