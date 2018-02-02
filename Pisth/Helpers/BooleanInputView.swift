// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// A view used as input view to write "Yes" or "No" to a Text View with a Switch.
class BooleanInputView: UIView {
    
    /// Called when switch state changes.
    ///
    /// - Bool: If switch is on or off.
    var completion: ((Bool) -> Void)?
    
    /// Subview from nib.
    var view: UIView!
    
    /// Text field where write.
    var textField: UITextField?
    
    /// Title to display.
    @IBOutlet weak var title: UILabel!
    
    /// Switch to use.
    @IBOutlet weak var `switch`: UISwitch!
    
    /// Title to display in `title` label.
    var title_: String
    
    /// Value written when switch is on.
    var on: String?
    
    /// Value written when switch is off.
    var off: String?
    
    /// If switch is on.
    var currentState: Bool {
        get {
            return `switch`.isOn
        }
        
        set {
            `switch`.isOn = newValue
        }
    }
    
    /// Initialize.
    ///
    /// Display title, setup textField and setup views.
    ///
    /// - Parameters:
    ///     - title: Title to display.
    ///     - textField: Text field where write.
    ///     - frame: Frame of view.
    init(title: String, textField: UITextField, on: String?, off: String?, currentState: Bool, frame: CGRect) {
        
        self.title_ = title
        self.textField = textField
        self.on = on
        self.off = off
        
        super.init(frame: frame)
        
        view = Bundle.main.loadNibNamed("BooleanInputView", owner: self, options: nil)![0] as! UIView
        addSubview(view)
        view.frame = bounds
        
        self.title.text = title_
        
        self.currentState = currentState
        
        addObserver(self, forKeyPath: "bounds", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }
    
    /// init(coder:) has not been implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Write "Yes" or "No" to textField.r
    ///
    /// - Parameters:
    ///     - sender: Sender Switch.
    @IBAction func toggle(_ sender: UISwitch) {
        if sender.isOn {
            textField?.text = on
        } else {
            textField?.text = off
        }
        
        if let completion = completion {
            completion(sender.isOn)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "bounds" {
            view.frame = bounds
        }
    }
    
}
