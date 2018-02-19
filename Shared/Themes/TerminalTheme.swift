// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Ansi colors used by terminal.
///
/// If nil is provided for a color, the default color will be used.
struct AnsiColors {
    
    /// Black color.
    var black: Color?
    
    /// Red color.
    var red: Color?
    
    /// Green color.
    var green: Color?
    
    /// Yellow color.
    var yellow: Color?
    
    /// Blue color.
    var blue: Color?
    
    /// Magenta color.
    var magenta: Color?
    
    /// Cyan color.
    var cyan: Color?
    
    /// White color.
    var white: Color?
    
    
    /// Bright black color.
    var brightBlack: Color?
    
    /// Bright red color.
    var brightRed: Color?
    
    /// Bright green color.
    var brightGreen: Color?
    
    /// Bright yellow color.
    var brightYellow: Color?
    
    /// Bright blue color.
    var brightBlue: Color?
    
    /// Bright magenta color.
    var brightMagenta: Color?
    
    /// Bright cyan color.
    var brightCyan: Color?
    
    /// Bright white color.
    var brightWhite: Color?
}

/// Template class for doing a theme for the terminal.
class TerminalTheme {
    
    /// Get theme by name.
    static let themes = ["Basic":BasicTheme(), "Grass":GrassTheme(), "Homebrew":HomebrewTheme(), "Man Page":ManPageTheme(), "Novel":NovelTheme(), "Ocean":OceanTheme(), "Pro":ProTheme(), "Red Sands":RedSandsTheme(), "Silver Aerogel":SilverAerogelTheme(), "Ubuntu":UbuntuTheme()] as [String:TerminalTheme]
    
    /// Cursor colors.
    var cursorColor: Color? {
        return nil
    }
    
    /// Default text color.
    var foregroundColor: Color? {
        return nil
    }
    
    /// Background color.
    var backgroundColor: Color? {
        return nil
    }
    
    /// ANSI colors.
    var ansiColors: AnsiColors? {
        return nil
    }
    
    /// JavaScript value to be used with `xterm.js`.
    var javascriptValue: String {
        
        var theme = "{"
        
        if foregroundColor != nil {
            theme += "foreground: '\(foregroundColor!.toHexString())'"
        }
        
        if backgroundColor != nil {
            theme += ", background: '\(backgroundColor!.toHexString())'"
        }
        
        if cursorColor != nil {
            theme += ", cursor: '\(cursorColor!.toHexString())'"
        }
        
        if self.ansiColors != nil {
            if self.ansiColors?.black != nil {
                theme += ", black: '\(self.ansiColors!.black!.toHexString())'"
            }
            
            if self.ansiColors?.red != nil {
                theme += ", red: '\(self.ansiColors!.red!.toHexString())'"
            }
            
            if self.ansiColors?.green != nil {
                theme += ", green: '\(self.ansiColors!.green!.toHexString())'"
            }
            
            if self.ansiColors?.yellow != nil {
                theme += ", yellow: '\(self.ansiColors!.yellow!.toHexString())'"
            }
            
            if self.ansiColors?.blue != nil {
                theme += ", blue: '\(self.ansiColors!.blue!.toHexString())'"
            }
            
            if self.ansiColors?.magenta != nil {
                theme += ", magenta: '\(self.ansiColors!.magenta!.toHexString())'"
            }
            
            if self.ansiColors?.cyan != nil {
                theme += ", cyan: '\(self.ansiColors!.cyan!.toHexString())'"
            }
            
            if self.ansiColors?.white != nil {
                theme += ", white: '\(self.ansiColors!.white!.toHexString())'"
            }
            
            
            if self.ansiColors?.brightBlack != nil {
                theme += ", brightBlack: '\(self.ansiColors!.brightBlack!.toHexString())'"
            }
            
            if self.ansiColors?.brightRed != nil {
                theme += ", brightRed: '\(self.ansiColors!.brightRed!.toHexString())'"
            }
            
            if self.ansiColors?.brightGreen != nil {
                theme += ", brightGreen: '\(self.ansiColors!.brightGreen!.toHexString())'"
            }
            
            if self.ansiColors?.brightYellow != nil {
                theme += ", brightYellow: '\(self.ansiColors!.brightYellow!.toHexString())'"
            }
            
            if self.ansiColors?.brightBlue != nil {
                theme += ", brightBlue: '\(self.ansiColors!.blue!.toHexString())'"
            }
            
            if self.ansiColors?.brightMagenta != nil {
                theme += ", brightMagenta: '\(self.ansiColors!.brightMagenta!.toHexString())'"
            }
            
            if self.ansiColors?.brightCyan != nil {
                theme += ", brightCyan: '\(self.ansiColors!.brightCyan!.toHexString())'"
            }
            
            if self.ansiColors?.brightWhite != nil {
                theme += ", brightWhite: '\(self.ansiColors!.brightWhite!.toHexString())'"
            }
            
        }
        
        return theme+"}"
    }
}
