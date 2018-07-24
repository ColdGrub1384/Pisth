// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit

/// Web view used to display the content for the terminal.
class TerminalWebView: WKWebView {
    
    /// View for adding gestures.
    var interactionView: UIView
    
    // MARK: - Web view
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        interactionView = UIView(frame: frame)
        interactionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        super.init(frame: frame, configuration: configuration)
        
        addSubview(interactionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Returns: `false.`
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    /// - Returns: `false.`
    override var canBecomeFirstResponder: Bool {
        return false
    }
    
}
