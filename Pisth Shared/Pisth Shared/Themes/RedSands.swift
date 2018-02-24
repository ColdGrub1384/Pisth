// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

/// Red Sands theme for the terminal.
open class RedSandsTheme: TerminalTheme {
    
    #if os(iOS)
        /// Returns light.
        open override var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        /// Returns default.
        open override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    /// Returns brown.
    open override var selectionColor: Color? {
        return Color(red: 61/255, green: 25/255, blue: 22/255, alpha: 0.5)
    }
    
    /// Returns a sort of red.
    open override var backgroundColor: Color? {
        return Color(red: 122/255, green: 37/255, blue: 30/255, alpha: 1)
    }
    
    /// Returns a sort of yellow.
    open override var foregroundColor: Color? {
        return Color(red: 215/255, green: 201/255, blue: 167/255, alpha: 1)
    }
    
    /// Returns white.
    open override var cursorColor: Color? {
        return .white
    }
}

