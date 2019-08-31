// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// View controller used to send arrow keys.
class ArrowsViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    /// Label indicating arrow to send.
    var arrowLabel: UILabel!
    
    /// Label with help.
    var helpLabel: UILabel!
    
    /// Send arrow to shell with given gesture.
    @objc func sendArrow(_ sender: UISwipeGestureRecognizer) {
        indicateArrow(withDirection: sender.direction)
        sendArrow(withDirection: sender.direction)
    }
    
    /// Show arrow to send in `arrowLabel`.
    ///
    /// - Parameters:
    ///     - direction: Direction where arrow will point.
    func indicateArrow(withDirection direction: UISwipeGestureRecognizer.Direction) {
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
    func sendArrow(withDirection direction: UISwipeGestureRecognizer.Direction) {
        
        ConnectionManager.shared.queue.async {
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
                self.arrowLabel.isHidden = true
            }
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ArrowsViewController.current = self
        
        // Help label
        
        helpLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        helpLabel.numberOfLines = 3
        helpLabel.text = Localizable.ArrowsViewControllers.helpTextArrows
        helpLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.heavy)
        helpLabel.textAlignment = .center
        helpLabel.textColor = .black
        helpLabel.backgroundColor = .white
        helpLabel.layer.borderWidth = 4
        helpLabel.layer.cornerRadius = 8
        helpLabel.layer.masksToBounds = true
        helpLabel.layer.borderColor = helpLabel.backgroundColor?.cgColor
        view.addSubview(helpLabel)
        
        // Arrow label
        
        arrowLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        arrowLabel.font = UIFont.boldSystemFont(ofSize: 30)
        arrowLabel.isHidden = true
        arrowLabel.textAlignment = .center
        arrowLabel.textColor = .black
        arrowLabel.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.5)
        arrowLabel.layer.borderWidth = 4
        arrowLabel.layer.cornerRadius = 8
        arrowLabel.layer.masksToBounds = true
        arrowLabel.layer.borderColor = arrowLabel.backgroundColor?.cgColor
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
        
        for gesture in view.gestureRecognizers ?? [] {
            gesture.gestureName = "arrow"
        }
        
        UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut, animations: {
            self.helpLabel.alpha = 0
        }, completion: { _ in
            self.helpLabel.isHidden = true
        })
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
    
    /// Current Arrows view controller visible.
    static var current: ArrowsViewController?
}
