// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit
import SwiftyStoreKit
import Pisth_Shared
import Firebase
import Pisth_Terminal

/// View controller used to buy themes iap.
class ThemesStoreViewController: UIViewController, WKNavigationDelegate {
    
    /// Themes associated with each Web view.
    var themes = [WKWebView:TerminalTheme]()
    
    /// Themes name associated with each Web view.
    var themesName = [WKWebView:String]()
    
    /// Scroll view used to display previews
    @IBOutlet weak var scrollView: UIScrollView!
    
    /// Button used to buy iap.
    @IBOutlet weak var buyButton: UIButton!
    
    /// Button used to restore iaps.
    @IBOutlet weak var restoreButton: UIButton!
    
    /// Buy iap.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func buy(_ sender: Any) {
        Product.terminalThemes.purchase { (result) in
            
            if let alert = Product.alert(withPurchaseResult: result, completion: {
                UserDefaults.standard.set(true, forKey: "terminalThemesPurchased")
                UserDefaults.standard.synchronize()
                
                self.dismiss(animated: true, completion: {
                    if let settings = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.topViewController as? SettingsTableViewController {
                        settings.themesStore.isHidden = true
                    }
                })
            }) {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /// Restore iaps.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func restore(_ sender: Any) {
        Product.restorePurchases { (results) in
            for purchase in results.restoredPurchases {
                if purchase.productId == ProductsID.themes.rawValue {
                    UserDefaults.standard.set(true, forKey: "terminalThemesPurchased")
                    UserDefaults.standard.synchronize()
                    
                    self.dismiss(animated: true, completion: {
                        if let settings = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.topViewController as? SettingsTableViewController {
                            settings.themesStore.isHidden = true
                        }
                    })
                }
            }
        }
    }
    
    /// Cancel.
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    /// Setup previews.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-ThemesStore", AnalyticsParameterItemName : "Themes Store"])
        
        restoreButton.layer.cornerRadius = 16
        buyButton.layer.cornerRadius = 16
        buyButton.setTitle(Product.terminalThemes.price ?? "Buy", for: .normal)
        view.backgroundColor = .clear
        
        var i = 0
        for (name, theme) in TerminalTheme.themes {
            let webView = WKWebView(frame: scrollView.frame)
            
            scrollView.addSubview(webView)
            
            webView.frame.origin = CGPoint.zero
            
            webView.frame.size.width -= 50
            webView.navigationDelegate = self
            scrollView.contentSize.width += webView.frame.width
            
            webView.frame.origin.x = CGFloat(i)*(scrollView.frame.width-50)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            themes[webView] = theme
            themesName[webView] = name
            
            webView.loadFileURL(Bundle.terminal.url(forResource: "terminal", withExtension: "html")!, allowingReadAccessTo: Bundle.main.bundleURL)
            webView.isUserInteractionEnabled = false
            
            i += 1
        }
    }
    
    // MARK: - Web kit navigation delegate
    
    /// Display theme preview.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        guard let theme = themes[webView] else {
            return
        }
        
        guard let name = themesName[webView] else {
            return
        }
        
        webView.evaluateJavaScript("term.setOption('theme', \(theme.javascriptValue))", completionHandler: nil)
        webView.evaluateJavaScript("fit(term)", completionHandler: nil)
        webView.evaluateJavaScript("term.writeln('\(Keys.esc)[7m \(name) Theme \(Keys.esc)[0m')", completionHandler: nil)
        webView.evaluateJavaScript("term.writeln('')", completionHandler: nil)
        webView.evaluateJavaScript("term.writeln('')", completionHandler: nil)
        webView.evaluateJavaScript("term.write('Pisth:~ pisth$ ')", completionHandler: nil)
        webView.evaluateJavaScript("document.body.style.backgroundColor = '\(theme.backgroundColor?.hexString ?? "#000000")'", completionHandler: nil)
    }
    
}
