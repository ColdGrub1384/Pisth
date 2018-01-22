// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// View controller used to send arrow keys.
class ArrowsViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    /// Label indicating arrow to send.
    var arrowLabel: UILabel!
    
    /// Label with help.
    var helpLabel: UILabel!
    
    /// Send arrow to shell with given gesture.
    ///
    /// - Parameters:
    ///     - sender: Sender gesture.
    @objc func sendArrow(_ sender: UISwipeGestureRecognizer) {
        indicateArrow(withDirection: sender.direction)
        sendArrow(withDirection: sender.direction)
    }
    
    /// Show arrow to send in `arrowLabel`.
    ///
    /// - Parameters:
    ///     - direction: Direction where arrow will point.
    func indicateArrow(withDirection direction: UISwipeGestureRecognizerDirection) {
        helpLabel.isHidden = true
        arrowLabel.isHidden = false
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
            switch direction {
            case .up:
                self.arrowLabel.text = "⬆︎"
            case .down:
                self.arrowLabel.text = "⬇︎"
            case .left:
                self.arrowLabel.text = "⬅︎"
            case .right:
                self.arrowLabel.text = "➡︎"
            default:
                self.arrowLabel.isHidden = true
            }
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (_) in
                self.arrowLabel.isHidden = true
            })
        })
    }
    
    /// Send arrow to the shell with given direction.
    ///
    /// - Parameters:
    ///     - direction: Direction where arrow will point.
    func sendArrow(withDirection direction: UISwipeGestureRecognizerDirection) {
        
        switch direction {
        case .up:
            try? ConnectionManager.shared.session?.channel.write(Keys.arrowUp)
        case .down:
            try? ConnectionManager.shared.session?.channel.write(Keys.arrowDown)
        case .left:
            try? ConnectionManager.shared.session?.channel.write(Keys.arrowLeft)
        case .right:
            try? ConnectionManager.shared.session?.channel.write(Keys.arrowRight)
        default:
            arrowLabel.isHidden = true
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ArrowsViewController.current = self
        
        // Help label
        
        helpLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        helpLabel.numberOfLines = 2
        helpLabel.text = "Swipe to send\narrow keys"
        helpLabel.textAlignment = .center
        helpLabel.textColor = .black
        view.addSubview(helpLabel)
        
        // Arrow label
        
        arrowLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        arrowLabel.font = UIFont.boldSystemFont(ofSize: 30)
        arrowLabel.isHidden = true
        arrowLabel.textAlignment = .center
        arrowLabel.textColor = .black
        view.addSubview(arrowLabel)
        
        // Recognize gestures
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(sendArrow(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(sendArrow(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(sendArrow(_:)))
        upSwipe.direction = .up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(sendArrow(_:)))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ArrowsViewController.current = nil
    }
    
    override func viewDidLayoutSubviews() {
        helpLabel.center = view.center
        arrowLabel.center = view.center
    }
    
    // MARK: - Popover presentation controller delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - Static
    
    /// Current Arrows view controller opened.
    static var current: ArrowsViewController?
}
