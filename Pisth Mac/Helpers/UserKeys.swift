// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation
import ObjectUserDefaults

fileprivate let ud = ObjectUserDefaults.standard

/// A class containing items stored in `ObjectUserDefaults`.
class UserKeys {
    private init() {}
    
    /// The name of the theme used in the terminal. Its value should be present in `PisthShared.TerminalTheme.themes`.
    static let terminalTheme = ud.item(forKey: "theme")
    
    /// The text size used in the terminal. Should be an integer.
    static let terminalTextSize = ud.item(forKey: "textSize")
    
    /// This key says if the hidden files should be shown. Its value should be a boolean.
    static let shouldHiddenFilesBeShown = ud.item(forKey: "showHiddenFiles")
}
