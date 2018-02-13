// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Novel theme for the terminal.
class NovelTheme: TerminalTheme {
    
    /// Returns a sort of brown.
    override var backgroundColor: Color? {
        return Color(red: 223/255, green: 219/255, blue: 195/255, alpha: 1)
    }
    
    /// Returns brown.
    override var foregroundColor: Color? {
        return Color(red: 59/255, green: 35/255, blue: 34/255, alpha: 1)
    }
    
    /// Returns a transparent brown.
    override var cursorColor: Color? {
        return Color(red: 58/255, green: 35/255, blue: 34/255, alpha: 0.65)
    }
}

