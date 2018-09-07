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
class UserKeys: Static {
    
    // MARK: - Compatibility
    
    /// Passwords are stored to the keychain since the 3.0. This key says if the passwords are already stored to the keychain. Its value should be a boolean.
    static let savedToKeychain = ud.item(forKey: "savedToKeychain")
    
    /// Since the 5.1, the user can enable or disable the SFTP for a connection. This key says if the SFTP attribute is already set in bookmarks. Its value should be a boolean.
    static let isSFTPAttributeAdded = ud.item(forKey: "addedSftpAttribute")
    
    // MARK: - Preferences
    
    /// The name of the selected terminal theme. Its value should be contained in `PisthShared.TerminalTheme.themes`.
    static let terminalTheme = ud.item(forKey: "terminalTheme")
    
    /// This key says if the terminal cursor should blink. Its value should be a boolean.
    static let blink = ud.item(forKey: "blink")
    
    /// The name of the theme used by the code editor.
    static let editorTheme = ud.item(forKey: "editorTheme")
    
    /// Text size used in the terminal. The value should be an integer.
    static let terminalTextSize = ud.item(forKey: "terminalTextSize")
    
    /// This key says if list views are enabled in the browser. Its value should be a boolean.
    static let areListViewsEnabled = ud.item(forKey: "list")
    
    /// This key says if the biometric authentication is enabled. Its value should be a boolean.
    static let isBiometricAuthenticationEnabled = ud.item(forKey: "biometricAuth")
    
    /// This key says if hidden files should be shown. Its value should be a boolean.
    static let shouldHiddenFilesBeShown = ud.item(forKey: "hidden")
}
