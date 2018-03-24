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
public struct RemoteConnection {
    
    /// Hostname or IP address used to connect.
    public var host: String
    
    /// Username used to login.
    public var username: String
    
    /// Password used to authenticate.
    public var password: String
    
    /// Name that appears in bookmarks.
    public var name: String
    
    /// Path where start.
    public var path: String
    
    /// Port used to connect.
    public var port: UInt64
    
    /// Use SFTP
    public var useSFTP: Bool
    
    /// OS name.
    public var os: String?
    
    /// Init from given info.
    public init(host: String, username: String, password: String, name: String, path: String, port: UInt64, useSFTP: Bool, os: String?) {
        self.host = host
        self.username = username
        self.password = password
        self.name = name
        self.path = path
        self.port = port
        self.useSFTP = useSFTP
        self.os = os
    }
}

