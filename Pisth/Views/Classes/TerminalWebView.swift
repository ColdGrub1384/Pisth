// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit

/// Web view used to display the content for the terminal.
class TerminalWebView: WKWebView, UIGestureRecognizerDelegate {
    
    /// Show menu. Called from a gesture recognizer.
    var showMenu: ((UILongPressGestureRecognizer) -> Void)?
    
    /// Toggle keyboard. Called from a gesture recognizer.
    var toggleKeyboard: (() -> Void)?
    
    @objc private func showMenu_(_ gestureRecognizer: UILongPressGestureRecognizer) {
        showMenu?(gestureRecognizer)
    }
    
    @objc private func toggleKeyboard_() {
        toggleKeyboard?()
    }
    
    private var longPress: UILongPressGestureRecognizer!
    
    private var tap: UITapGestureRecognizer!
    
    // MARK: - Web view
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(showMenu_(_:)))
        addGestureRecognizer(longPress)
        tap = UITapGestureRecognizer(target: self, action: #selector(toggleKeyboard_))
        addGestureRecognizer(tap)
    }
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        super.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.delegate = self
    }
    
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override var canBecomeFirstResponder: Bool {
        return false
    }
    
    // MARK: - Gesture recognizer delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if (gestureRecognizer == tap && otherGestureRecognizer == longPress) || (gestureRecognizer == longPress && otherGestureRecognizer == tap) {
            return false
        }
        
        return true
    }
}
