// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import WebKit

/// Web view used to display the content for the terminal.
class TerminalWebView: WKWebView, UIGestureRecognizerDelegate, UIContextMenuInteractionDelegate {
    
    /// Show menu. Called from a gesture recognizer.
    var showMenu: ((UILongPressGestureRecognizer) -> Void)?
    
    /// Toggle keyboard. Called from a gesture recognizer.
    var toggleKeyboard: (() -> Void)?
    
    /// The terminal containing the terminal.
    var terminal: TerminalViewController?
    
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
        
        if #available(iOS 13.0, *) {
            addInteraction(UIContextMenuInteraction(delegate: self))
        } else {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(showMenu_(_:)))
            addGestureRecognizer(longPress)
        }
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
    
    // MARK: - Context menu interaction delegate
    
    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            
            func imageWithView(view: UIView) -> UIImage? {
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
                defer { UIGraphicsEndImageContext() }
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                return UIGraphicsGetImageFromCurrentImageContext()
            }
            
            let vc = UIViewController()
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.image = imageWithView(view: self)
            vc.view = imageView
            
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = self.terminal?.theme.foregroundColor?.cgColor
            imageView.layer.cornerRadius = 16
            
            vc.preferredContentSize = CGSize(width: 400, height: 200)
            return vc
        }) { (_) -> UIMenu? in
            
            let arrowsState: UIMenuElement.State
            if self.terminal?.arrows == true {
                arrowsState = .on
            } else {
                arrowsState = .off
            }
            
            let items = [
                UIAction(title: Localizable.TerminalViewController.paste, image: UIImage(systemName: "doc.on.clipboard"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { (_) in
                    self.terminal?.pasteText()
                }),
                
                UIAction(title: Localizable.TerminalViewController.selectionMode, image: UIImage(systemName: "selection.pin.in.out"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { (_) in
                    self.terminal?.selectionMode()
                }),
                
                UIAction(title: Localizable.ArrowsViewControllers.helpTextArrows.replacingOccurrences(of: "\n", with: " "), image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: arrowsState, handler: { (_) in
                    self.terminal?.arrows = !self.terminal!.arrows
                    self.terminal?.toggleSendArrows(self.terminal!.arrows)
                }),
                
                UIAction(title: Localizable.UIMenuItem.toggleTopBar, image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { (_) in
                    self.terminal?.showNavBar()
                })
            ]
            
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }
}
