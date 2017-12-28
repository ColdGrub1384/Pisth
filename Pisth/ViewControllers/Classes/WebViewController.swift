//
//  WebViewController.swift
//  Pisth
//
//  Created by Adrian on 28.12.17.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate  {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var goBackButton: UIBarButtonItem!
    @IBOutlet weak var goForwardButton: UIBarButtonItem!
    
    var file: URL?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
        
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
