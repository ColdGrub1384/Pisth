// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

/// Grass theme for the terminal.
class GrassTheme: TerminalTheme {
    
    #if os(iOS)
        /// Returns light.
        override var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        /// Returns default.
        override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    /// Returns red.
    override var selectionColor: Color? {
        return Color(red: 182/255, green: 73/255, blue: 38/255, alpha: 0.5)
    }
    
    /// Returns green.
    override var backgroundColor: Color? {
        return Color(red: 19/255, green: 129/255, blue: 61/255, alpha: 1)
    }
 
    /// Returns a sort of yellow.
    override var foregroundColor: Color? {
        return Color(red: 255/255, green: 240/255, blue: 165/255, alpha: 1)
    }
    
    /// Returns a sort of red.
    override var cursorColor: Color? {
        return Color(red: 142/255, green: 40/255, blue: 0, alpha: 1)
    }
}
