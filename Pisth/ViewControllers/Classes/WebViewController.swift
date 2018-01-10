// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate  {
    
    var webView: WKWebView!
    @IBOutlet weak var goBackButton: UIBarButtonItem!
    @IBOutlet weak var goForwardButton: UIBarButtonItem!
    
    var file: URL?
    
    var navBarHeight: CGFloat {
        return AppDelegate.shared.navigationController.navigationBar.frame.height+UIApplication.shared.statusBarFrame.height
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        let newFrame = CGRect(x: 0, y: navBarHeight, width: size.width, height: size.height-50-navBarHeight)
        webView.frame = newFrame
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
            title = file.lastPathComponent
        }
        
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
    }
    
    @IBAction func goBack(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        webView.goForward()
    }
    
    // Mark: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        goBackButton.isEnabled = webView.canGoBack
        goForwardButton.isEnabled = webView.canGoForward
    }
}
