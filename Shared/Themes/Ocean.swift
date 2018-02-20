// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

/// Ocean theme for the terminal.
class OceanTheme: TerminalTheme {
    
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
    
    /// Returns blue.
    override var backgroundColor: Color? {
        return Color(red: 34/255, green: 79/255, blue: 188/255, alpha: 1)
    }
    
    /// Returns white.
    override var foregroundColor: Color? {
        return .white
    }
    
    /// Returns gray.
    override var cursorColor: Color? {
        return Color(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
    }
}

