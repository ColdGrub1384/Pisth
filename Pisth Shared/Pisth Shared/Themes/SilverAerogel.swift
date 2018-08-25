// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

/// Silver Aerogel theme for the terminal.
open class SilverAerogelTheme: TerminalTheme {
    
    #if os(iOS)
        open override var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        open override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    open override var selectionColor: Color? {
        return Color(red: 101/255, green: 102/255, blue: 138/255, alpha: 0.5)
    }
    
    open override var backgroundColor: Color? {
        return Color(red: 146/255, green: 146/255, blue: 146/255, alpha: 1)
    }
    
    open override var foregroundColor: Color? {
        return .black
    }
    
    open override var cursorColor: Color? {
        return Color(red: 217/255, green: 217/255, blue: 217/255, alpha: 1)
    }
}

