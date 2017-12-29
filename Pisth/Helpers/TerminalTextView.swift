//
//  TerminalTextView.swift
//  fastSwift
//
//  Created by Adrian on 22.07.17.
//

import UIKit

class TerminalTextView: UITextView {
        
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.width = 10
        
        return rect
    }
    
        
    func scrollToBotom() {
        let range = NSMakeRange((text as NSString).length - 1, 1)
        scrollRangeToVisible(range)
    }
    

    
}
