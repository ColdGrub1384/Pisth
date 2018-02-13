// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Grass theme for the terminal.
class ProTheme: TerminalTheme {
    
    /// Returns black.
    override var backgroundColor: Color? {
        return .black
    }
    
    /// Returns white.
    override var foregroundColor: Color? {
        return Color(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
    }
    
    /// Returns white.
    override var cursorColor: Color? {
        return .white
    }
}

