// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

/// Basic theme for the terminal.
class BasicTheme: TerminalTheme {
    
    /// Returns white.
    override var backgroundColor: Color? {
        return .white
    }
    
    /// Returns black.
    override var foregroundColor: Color? {
        return .black
    }
    
    /// Returns gray.
    override var cursorColor: Color? {
        return Color(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
    }
}
