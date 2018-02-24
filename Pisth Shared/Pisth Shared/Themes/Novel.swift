// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

/// Novel theme for the terminal.
open class NovelTheme: TerminalTheme {
    
    #if os(iOS)
        /// Returns light.
        override open var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        /// Returns default.
        override open var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    /// Returns gray.
    open override var selectionColor: Color? {
        return Color(red: 116/255, green: 115/255, blue: 80/255, alpha: 0.5)
    }
    
    /// Returns a sort of brown.
    open override var backgroundColor: Color? {
        return Color(red: 223/255, green: 219/255, blue: 195/255, alpha: 1)
    }
    
    /// Returns brown.
    open override var foregroundColor: Color? {
        return Color(red: 59/255, green: 35/255, blue: 34/255, alpha: 1)
    }
    
    /// Returns a transparent brown.
    open override var cursorColor: Color? {
        return Color(red: 58/255, green: 35/255, blue: 34/255, alpha: 0.65)
    }
}

