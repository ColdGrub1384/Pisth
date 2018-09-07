// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Header view for file browsers.
class HeaderToolbar: UIToolbar {
    
    /// All instances displayed.
    static var all = [HeaderToolbar]()
    
    /// Code ran for creating a new folder.
    var createNewFolder: ((UIButton) -> ())?
    
    /// Code ran for switching layout.
    var switchLayout: ((UIButton) -> ())?
    
    /// `true` if list is enabled. Set before calling `switchLayout`.
    @objc var isListEnabled: Bool {
        return UserKeys.areListViewsEnabled.boolValue
    }
    
    /// `true` if the view is already setup.
    var isReady = false
    
    @IBOutlet weak private var listButton: UIButton!
    
    @IBAction private func createNewFolder_(_ sender: UIButton) {
        createNewFolder?(sender)
    }
    
    @IBAction private func switchLayout_(_ sender: UIButton) {
        UserKeys.areListViewsEnabled.boolValue = !isListEnabled
        
        for header in HeaderToolbar.all {
            header.switchLayoutState()
            header.switchLayout?(sender)
        }
    }
    
    private func switchLayoutState() {
        if isListEnabled {
            listButton.backgroundColor = UIApplication.shared.keyWindow?.tintColor
            listButton.tintColor = .white
        } else {
            listButton.backgroundColor = .clear
            listButton.tintColor = UIApplication.shared.keyWindow?.tintColor
        }
    }
    
    // MARK: - Toolbar
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if !isReady {
            HeaderToolbar.all.append(self)
            listButton.layer.cornerRadius = 5
            switchLayoutState()
            isReady = true
        }
    }
}
