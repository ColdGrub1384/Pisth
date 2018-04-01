// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
import UIKit
import WebKit

/// View controller displaying web content.
open class WebViewController: UIViewController, WKNavigationDelegate  {
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /// Web view used to display content.
    open var webView: WKWebView!
    
    var isLoaded = false
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var goBackButton: UIBarButtonItem!
    
    @IBOutlet weak var goForwardButton: UIBarButtonItem!
    
    /// Local file to open.
    open var file: URL?

    // MARK: - View controller
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            let newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height-self.toolbar.frame.height)
            self.webView.frame = newFrame
        })
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
    }
    
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        if !isLoaded {
            isLoaded = true
            
            webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height-toolbar.frame.height))
            view.addSubview(webView)
            
            if let file = file { // Open file
                webView.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
            }
            
            webView.allowsBackForwardNavigationGestures = true
            webView.navigationDelegate = self
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func goBack(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        webView.goForward()
    }
    
    // MARK: - Web kit navigation delegate
    
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        goBackButton.isEnabled = webView.canGoBack
        goForwardButton.isEnabled = webView.canGoForward
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.title") { (title, _) in
            if let title = title as? String {
                self.title = title
            }
        }
    }
}
#endif
