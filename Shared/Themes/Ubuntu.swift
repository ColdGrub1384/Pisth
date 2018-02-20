// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

/// Ubuntu theme for the terminal.
class UbuntuTheme: TerminalTheme {
    
    /// Returns purple.
    override var backgroundColor: Color? {
        return Color(red: 48/255, green: 10/255, blue: 36/255, alpha: 1)
    }
    
    /// Returns white.
    override var foregroundColor: Color? {
        return Color(red: 255/255, green: 253/255, blue: 244/255, alpha: 1)
    }
    
    /// Returns white.
    override var cursorColor: Color? {
        return Color(red: 251/255, green: 251/255, blue: 251/255, alpha: 1)
    }
}


