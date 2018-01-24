// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Representation of a remote connection.
/// - Parameters:
///     - host: Hostname or IP address used to connect.
///     - username: Username used to login.
///     - password: Password used to authenticate.
///     - name: Name that appears in bookmarks.
///     - path: Path where start.
///     - port: Port used to connect.
struct RemoteConnection {
    
    /// Hostname or IP address used to connect.
    var host: String
    
    /// Username used to login.
    var username: String
    
    /// Password used to authenticate.
    var password: String
    
    /// Name that appears in bookmarks.
    var name: String
    
    /// Path where start.
    var path: String
    
    /// Port used to connect.
    var port: UInt64
    
    /// Use SFTP
    var useSFTP: Bool
}

