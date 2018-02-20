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
class SilverAerogelTheme: TerminalTheme {
    
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
    
    /// Returns gray.
    override var backgroundColor: Color? {
        return Color(red: 146/255, green: 146/255, blue: 146/255, alpha: 1)
    }
    
    /// Returns black.
    override var foregroundColor: Color? {
        return .black
    }
    
    /// Returns white.
    override var cursorColor: Color? {
        return Color(red: 217/255, green: 217/255, blue: 217/255, alpha: 1)
    }
}

