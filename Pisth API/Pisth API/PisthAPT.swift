// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// The class for interacting with Pisth APT.
open class PisthAPT {
    
    /// This app URL scheme.
    open var urlScheme: URL
    
    /// Tint color of Pisth APT. Default is the tint color of the key window.
    open var tintColor: UIColor?
    
    var pisthAPTurlScheme: URL {
        
        var urlString = "pisthapt://?scheme=\(urlScheme.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"
        
        if let color = tintColor {
            urlString += "&tintColor=\(color.hexString.replacingOccurrences(of:"#", with:"%23"))"
        }
        
        return URL(string: urlString)!
    }
    
    /// Init the object.
    ///
    /// - Parameters:
    ///     - urlScheme: This app URL scheme.
    public init(urlScheme: URL) {
        tintColor = UIApplication.shared.keyWindow?.tintColor
        self.urlScheme = urlScheme
    }
    
    /// Returns `true` if current application can open Pisth Pisth APT URL scheme.
    open var canOpen: Bool {
        return UIApplication.shared.canOpenURL(pisthAPTurlScheme)
    }
    
    /// Open Pisth APT.
    ///
    /// - Parameters:
    ///     - connection: Connection to open.
    open func open(connection: RemoteConnection) {
        UIPasteboard.general.setData(NSKeyedArchiver.archivedData(withRootObject: connection), forPasteboardType: "public.data")
        UIApplication.shared.open(pisthAPTurlScheme, options: [:], completionHandler: nil)
    }
    
}
