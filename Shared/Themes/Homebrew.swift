// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

/// Homebrew theme for the terminal.
class HomebrewTheme: TerminalTheme {
    
    /// Returns black.
    override var backgroundColor: Color? {
        return .black
    }
    
    /// Returns green.
    override var foregroundColor: Color? {
        return Color(red: 40/255, green: 254/255, blue: 20/255, alpha: 1)
    }
    
    /// Returns a sort of red.
    override var cursorColor: Color? {
        return Color(red: 56/255, green: 254/255, blue: 39/255, alpha: 1)
    }
}

