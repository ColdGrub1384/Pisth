// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
import UIKit
#endif
    
/// Pisth default theme for the terminal.
open class PisthTheme: TerminalTheme {
    
    #if os(iOS)
    open override var keyboardAppearance: UIKeyboardAppearance {
        #if os(iOS)
        if backgroundColor != .white {
            return .dark
        }
        #endif
        return .light
    }
    
    open override var toolbarStyle: UIBarStyle {
        
        #if os(iOS)
        if backgroundColor != .white {
            return .black
        }
        #endif
        
        return .default
    }
    #endif
    
    open override var backgroundColor: Color? {
        #if os(iOS)
        if #available(iOS 11.0, *) {
            if let background = Color(named: "ShellBackground"), (Bundle.main.infoDictionary?["Is Shell"] as? Bool) == true {
                return background
            }
        }
        #endif
        return .white
    }
    
    open override var foregroundColor: Color? {
        if backgroundColor == .white {
            return Color(red: 120/255, green: 32/255, blue: 157/255, alpha: 1)
        } else {
            return .white
        }
    }
    
    open override var cursorColor: Color? {
        return foregroundColor
    }
}

