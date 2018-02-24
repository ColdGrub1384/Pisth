// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Info sent via Multipeer connectivity.
///
/// ## Contains:
/// - Size of terminal.
/// - Message to show in terminal.
open class TerminalInfo: NSObject, NSCoding {
    
    /// Init from given message and size.
    ///
    /// - Parameters:
    ///     - message: Message to show in terminal.
    ///     - terminalSize: Size of terminal (in Floats, not in cols or rows). This is an Array, so provide two values, the first, width and the second, height.
    public init(message: String, themeName: String, terminalSize: [Float]) {
        self.message = message
        self.themeName = themeName
        
        if terminalSize.count == 1 {
            terminalSize_ = [terminalSize[0], 0]
        } else if terminalSize.count == 0 {
            terminalSize_ =  [0,0]
        } else {
            terminalSize_ = [terminalSize[0], terminalSize[1]]
        }
    }
    
    /// Name of theme for the terminal.
    open var themeName = "Pro"
    
    /// Message to show in terminal.
    var message = ""
    
    /// Size of terminal (in Floats, not in cols or rows).
    ///
    /// The first value is the width, and the second value is the height.
    private var terminalSize_: [Float] = [0,0]
    
    /// Size of terminal (in Floats, not in cols or rows).
    ///
    /// The first value is the width, and the second value is the height.
    /// The setter of this variable put `0` for missing values, or remove extra values.
    open var terminalSize: [Float] {
        set {
            if newValue.count == 1 {
                terminalSize_ = [newValue[0], 0]
            } else if newValue.count == 0 {
                terminalSize_ =  [0,0]
            } else {
                terminalSize_ = [newValue[0], newValue[1]]
            }
        }
        
        get {
            return terminalSize_
        }
    }
    
    
    // MARK: - Coding
    
    /// `NSCoding`'s `encode(with:)` function.
    ///
    /// Encode info.
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(message, forKey: "message")
        aCoder.encode(terminalSize, forKey: "terminalSize")
        aCoder.encode(themeName, forKey: "theme")
    }
    
    /// `NSCoding`'s `init(coder:)` function.
    ///
    /// Decode given `NSCoder` and set variables.
    public required init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        guard let message = aDecoder.decodeObject(forKey: "message") as? String else {
            return
        }
        
        guard let terminalSize = aDecoder.decodeObject(forKey: "terminalSize") as? [Float] else {
            return
        }
        
        guard let terminalTheme = aDecoder.decodeObject(forKey: "theme") as? String else {
            return
        }
        
        self.message = message
        self.terminalSize = terminalSize
        self.themeName = terminalTheme
    }
}
