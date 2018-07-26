// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Dark version of `PisthTheme`.
open class PisthDarkTheme: ProTheme {
    
    /// Returns purple.
    open override var foregroundColor: Color? {
        return Color(red: 120/255, green: 32/255, blue: 157/255, alpha: 1)
    }
    
    /// Returns purple.
    open override var cursorColor: Color? {
        return Color(red: 120/255, green: 32/255, blue: 157/255, alpha: 1)
    }
}
