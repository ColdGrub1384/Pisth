// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

#if os(macOS)
    import Cocoa
#endif

/// Basic theme for the terminal. A dark theme for macOS dark mode.
open class BasicTheme: TerminalTheme {
    
    #if os(iOS)
        open override var keyboardAppearance: UIKeyboardAppearance {
            return .light
        }
    
        open override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    open override var selectionColor: Color? {
        #if os(macOS)
            return Color.selectedControlColor
        #else
            return Color(red: 164/255, green: 205/255, blue: 255/255, alpha: 0.5)
        #endif
    }
    
    open override var backgroundColor: Color? {
        #if os(macOS)
            if #available(OSX 10.14, *) {
                if NSAppearance.current.name == .darkAqua || NSAppearance.current.name == .accessibilityHighContrastDarkAqua {
                    return Color(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
                } else {
                    return .white
                }
            } else {
                return .white
            }
        #else
            return .white
        #endif
    }
    
    open override var foregroundColor: Color? {
        #if os(macOS)
            if #available(OSX 10.14, *) {
                if NSAppearance.current.name == .darkAqua || NSAppearance.current.name == .accessibilityHighContrastDarkAqua {
                    return .white
                } else {
                    return .black
                }
            } else {
                return .black
            }
        #else
            return .black
        #endif
    }
    
    open override var cursorColor: Color? {
        return Color(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
    }
}
