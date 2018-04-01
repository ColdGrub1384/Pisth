// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Pisth default theme for the terminal.
open class PisthTheme: TerminalTheme {
    
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
    
    /// Returns white.
    open override var backgroundColor: Color? {
        return .white
    }
    
    /// Returns purple.
    open override var foregroundColor: Color? {
        return Color(red: 120/255, green: 32/255, blue: 157/255, alpha: 1)
    }
    
    /// Returns purple.
    open override var cursorColor: Color? {
        return Color(red: 120/255, green: 32/255, blue: 157/255, alpha: 1)
    }
}

