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
open class OceanTheme: TerminalTheme {
    
    #if os(iOS)
        open override var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        open override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    open override var selectionColor: Color? {
        return Color(red: 33/255, green: 109/255, blue: 255/255, alpha: 0.5)
    }
    
    open override var backgroundColor: Color? {
        return Color(red: 34/255, green: 79/255, blue: 188/255, alpha: 1)
    }
    
    open override var foregroundColor: Color? {
        return .white
    }
    
    open override var cursorColor: Color? {
        return Color(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
    }
}

