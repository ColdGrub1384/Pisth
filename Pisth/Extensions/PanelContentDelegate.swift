// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import PanelKit

fileprivate var gestureRecognizerTimer: Timer?

extension PanelContentDelegate {
    
    /// Disable `AppDelegate.shared.splitViewController`'s gesture while dragging.
    func panelDragGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        AppDelegate.shared.splitViewController.presentsWithGesture = false
        
        gestureRecognizerTimer?.invalidate()
        
        gestureRecognizerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            AppDelegate.shared.splitViewController.presentsWithGesture = true
        })
        
        return true
    }
}
