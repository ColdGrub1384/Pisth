// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

#if os(iOS)
    import UIKit
#endif

/// Ansi colors used by terminal.
///
/// If nil is provided for a color, the default color will be used.
public struct AnsiColors {
    
    /// Black color.
    public var black: Color?
    
    /// Red color.
    public var red: Color?
    
    /// Green color.
    public var green: Color?
    
    /// Yellow color.
    public var yellow: Color?
    
    /// Blue color.
    public var blue: Color?
    
    /// Magenta color.
    public var magenta: Color?
    
    /// Cyan color.
    public var cyan: Color?
    
    /// White color.
    public var white: Color?
    
    
    /// Bright black color.
    public var brightBlack: Color?
    
    /// Bright red color.
    public var brightRed: Color?
    
    /// Bright green color.
    public var brightGreen: Color?
    
    /// Bright yellow color.
    public var brightYellow: Color?
    
    /// Bright blue color.
    public var brightBlue: Color?
    
    /// Bright magenta color.
    public var brightMagenta: Color?
    
    /// Bright cyan color.
    public var brightCyan: Color?
    
    /// Bright white color.
    public var brightWhite: Color?
}

/// Template class for doing a theme for the terminal.
///
///
/// # Adding a theme
///
/// - Create a subclass of `TerminalTheme` and override all properties you want.
/// - Register the theme in `themes` variable.
///
///
/// # Default themes
///
/// - `PisthTheme`
/// - `BasicTheme`
/// - `GrassTheme`
/// - `HomebrewTheme`
/// - `ManPageTheme`
/// - `NovelTheme`
/// - `OceanTheme`
/// - `ProTheme`
/// - `RedSandsTheme`
/// - `SilverAerogelTheme`
/// - `UbuntuTheme`
open class TerminalTheme {
    
    public init() {}
    
    /// Get theme by name.
    public static let themes = ["Pisth":PisthTheme(), "Basic":BasicTheme(), "Grass":GrassTheme(), "Homebrew":HomebrewTheme(), "Man Page":ManPageTheme(), "Novel":NovelTheme(), "Ocean":OceanTheme(), "Pro":ProTheme(), "Red Sands":RedSandsTheme(), "Silver Aerogel":SilverAerogelTheme(), "Ubuntu":UbuntuTheme()] as [String:TerminalTheme]
    
    #if os(iOS)
        /// Keyboard appearance used in terminal.
        ///
        /// Default is dark.
        open var keyboardAppearance: UIKeyboardAppearance {
            return .dark
        }
    
        /// Style used in toolbar in terminal.
        ///
        /// Default is black.
        open var toolbarStyle: UIBarStyle {
            return .black
        }
    #endif
    
    /// Selection color
    open var selectionColor: Color? {
        return nil
    }
    
    /// Cursor colors.
    open var cursorColor: Color? {
        return nil
    }
    
    /// Default text color.
    open var foregroundColor: Color? {
        return nil
    }
    
    /// Background color.
    open var backgroundColor: Color? {
        return nil
    }
    
    /// ANSI colors.
    open var ansiColors: AnsiColors? {
        return nil
    }
    
    /// JavaScript value to be used with `xterm.js`.
    open var javascriptValue: String {
        
        var theme = "{"
        
        if foregroundColor != nil {
            theme += "foreground: '\(foregroundColor!.rgbaString)'"
        }
        
        if backgroundColor != nil {
            theme += ", background: '\(backgroundColor!.rgbaString)'"
        }
        
        if cursorColor != nil {
            theme += ", cursor: '\(cursorColor!.rgbaString)'"
        }
        
        #if os(OSX)
            if selectionColor != nil {
                let selection = ", selection: '\(selectionColor!.rgbaString)'"
                theme += selection
            }
        #endif
        
        if self.ansiColors != nil {
            if self.ansiColors?.black != nil {
                theme += ", black: '\(self.ansiColors!.black!.rgbaString)'"
            }
            
            if self.ansiColors?.red != nil {
                theme += ", red: '\(self.ansiColors!.red!.rgbaString)'"
            }
            
            if self.ansiColors?.green != nil {
                theme += ", green: '\(self.ansiColors!.green!.rgbaString)'"
            }
            
            if self.ansiColors?.yellow != nil {
                theme += ", yellow: '\(self.ansiColors!.yellow!.rgbaString)'"
            }
            
            if self.ansiColors?.blue != nil {
                theme += ", blue: '\(self.ansiColors!.blue!.rgbaString)'"
            }
            
            if self.ansiColors?.magenta != nil {
                theme += ", magenta: '\(self.ansiColors!.magenta!.rgbaString)'"
            }
            
            if self.ansiColors?.cyan != nil {
                theme += ", cyan: '\(self.ansiColors!.cyan!.rgbaString)'"
            }
            
            if self.ansiColors?.white != nil {
                theme += ", white: '\(self.ansiColors!.white!.rgbaString)'"
            }
            
            
            if self.ansiColors?.brightBlack != nil {
                theme += ", brightBlack: '\(self.ansiColors!.brightBlack!.rgbaString)'"
            }
            
            if self.ansiColors?.brightRed != nil {
                theme += ", brightRed: '\(self.ansiColors!.brightRed!.rgbaString)'"
            }
            
            if self.ansiColors?.brightGreen != nil {
                theme += ", brightGreen: '\(self.ansiColors!.brightGreen!.rgbaString)'"
            }
            
            if self.ansiColors?.brightYellow != nil {
                theme += ", brightYellow: '\(self.ansiColors!.brightYellow!.rgbaString)'"
            }
            
            if self.ansiColors?.brightBlue != nil {
                theme += ", brightBlue: '\(self.ansiColors!.blue!.rgbaString)'"
            }
            
            if self.ansiColors?.brightMagenta != nil {
                theme += ", brightMagenta: '\(self.ansiColors!.brightMagenta!.rgbaString)'"
            }
            
            if self.ansiColors?.brightCyan != nil {
                theme += ", brightCyan: '\(self.ansiColors!.brightCyan!.rgbaString)'"
            }
            
            if self.ansiColors?.brightWhite != nil {
                theme += ", brightWhite: '\(self.ansiColors!.brightWhite!.rgbaString)'"
            }
            
        }
        
        print(theme+"}")
        
        return theme+"}"
    }
}
