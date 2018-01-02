// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

class TerminalTextView: UITextView {
        
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.width = 10
        
        return rect
    }
    
        
    func scrollToBotom() {
        let range = NSMakeRange(text.nsString.length - 1, 1)
        scrollRangeToVisible(range)
    }
    

    
}
