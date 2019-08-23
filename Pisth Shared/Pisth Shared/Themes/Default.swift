// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2019 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

#if os(iOS)
    import UIKit
#endif

#if os(macOS)
    import Cocoa
#endif

/// Default theme for the terminal. Uses system appearance.
open class DefaultTheme: TerminalTheme {
    
    #if os(iOS)
        open override var keyboardAppearance: UIKeyboardAppearance {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return .dark
                } else {
                    return .default
                }
            } else {
                return .default
            }
        }
    
        open override var toolbarStyle: UIBarStyle {
            return .default
        }
    #endif
    
    open override var selectionColor: Color? {
        #if os(macOS)
            return Color.selectedControlColor
        #else
            if #available(iOS 11.0, *) {
                return UIColor(named: "Purple") ?? Color.systemPurple
            } else {
                return Color.systemPurple
            }
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
            if #available(iOS 13.0, *) {
                return Color.systemBackground
            } else {
                return Color.white
            }
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
            if #available(iOS 13.0, *) {
                return Color.label
            } else {
                return Color.black
            }
        #endif
    }
    
    open override var cursorColor: Color? {
        return foregroundColor
    }
}
