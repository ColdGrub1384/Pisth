// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

let pasteboard = UIPasteboard(name: .init("pisth-import"), create: true)

/// The class for interacting with Pisth.
open class Pisth {
    
    var pisthURLScheme: URL {
        var string = "pisth-import://?scheme=\(urlScheme.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
        
        if let message = message {
            string += "&message=\(message.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
        }
        
        return URL(string: string)!
    }
    
    /// Init from given message and URL scheme.
    ///
    /// - Parameters:
    ///     - message: Message to show in the Pisth navigation bar.
    ///     - urlScheme: This app URL scheme.
    public init(message: String?, urlScheme: URL) {
        self.message = message
        self.urlScheme = urlScheme
    }
    
    /// Imported file data.
    open var dataReceived: Data? {
        return pasteboard?.data(forPasteboardType: "public.data")
    }
    
    /// Message to show in the Pisth navigation bar.
    open var message: String?
    
    /// This app URL scheme.
    open var urlScheme: URL
    
    /// Returns `true` if current application can open Pisth URL scheme.
    open var canOpen: Bool {
        return UIApplication.shared.canOpenURL(pisthURLScheme)
    }
    
    /// Open Pisth and import file.
    ///
    /// This function takes a screenshot of key window and use it as blurred background for Pisth.
    open func importFile() {
        
        // Take screenshot
        
        if let window = UIApplication.shared.keyWindow {
            let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
            
            let screenshot = renderer.image(actions: { context in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            })
            
            pasteboard?.image = screenshot
        }
        
        UIApplication.shared.open(pisthURLScheme, options: [:], completionHandler: nil)
    }
    
    /// Get filename from opened URL.
    open func filename(fromURL url: URL) -> String? {
        
        return url.queryParameters?["filename"]?.removingPercentEncoding
    }
}
