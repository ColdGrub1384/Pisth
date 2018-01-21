// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit


/// View controller displaying web content.
class WebViewController: UIViewController, WKNavigationDelegate  {
    
    /// Web view used to display content.
    var webView: WKWebView!
    
    /// Button for going back.
    @IBOutlet weak var goBackButton: UIBarButtonItem!
    
    /// Button for going forward.
    @IBOutlet weak var goForwardButton: UIBarButtonItem!
    
    /// Local file to open.
    var file: URL?
    
    /// Returns navigation bar height.
    var navBarHeight: CGFloat {
        return AppDelegate.shared.navigationController.navigationBar.frame.height+UIApplication.shared.statusBarFrame.height
    }
    
    
    // MARK: - View controller
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            let newFrame = CGRect(x: 0, y: self.navBarHeight, width: size.width, height: size.height-50-self.navBarHeight)
            self.webView.frame = newFrame
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: CGRect(x: 0, y: navBarHeight, width: view.frame.width, height: view.frame.height-50-navBarHeight))
        view.addSubview(webView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        if let file = file { // Open file
            webView.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
        }
        
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
    }
    
    
    // MARK: - Actions
    
    /// Go back.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func goBack(_ sender: Any) {
        webView.goBack()
    }
    
    /// Go forward.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func goForward(_ sender: Any) {
        webView.goForward()
    }
    
    // MARK: - Web kit navigation delegate
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        goBackButton.isEnabled = webView.canGoBack
        goForwardButton.isEnabled = webView.canGoForward
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Get page title
        webView.evaluateJavaScript("document.title") { (title, _) in
            if let title = title as? String {
                self.title = title
            }
        }
    }
}
