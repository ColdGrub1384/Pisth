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
public class RemoteConnection: NSObject, NSCoding {
    
    /// Hostname or IP address used to connect.
    public var host: String
    
    /// Username used to login.
    public var username: String
    
    /// Password used to authenticate or for private key.
    public var password: String
    
    /// Public key.
    public var publicKey: String?
    
    /// Private key.
    public var privateKey: String?
    
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
    public init(host: String, username: String, password: String, publicKey: String? = nil, privateKey: String? = nil, name: String, path: String, port: UInt64, useSFTP: Bool, os: String?) {
        self.host = host
        self.username = username
        self.password = password
        self.name = name
        self.path = path
        self.port = port
        self.useSFTP = useSFTP
        self.os = os
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    // MARK: - Coding
    
    /// Encode this object.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(host, forKey: "Host")
        aCoder.encode(username, forKey: "Username")
        aCoder.encode(password, forKey: "Password")
        aCoder.encode(name, forKey: "Name")
        aCoder.encode(path, forKey: "Path")
        aCoder.encode(port, forKey: "Port")
        aCoder.encode(useSFTP, forKey: "Use SFTP")
        aCoder.encode(os, forKey: "OS")
    }
    
    /// Decode this object.
    public required init?(coder aDecoder: NSCoder) {
        guard let host = aDecoder.decodeObject(forKey: "Host") as? String else {
            return nil
        }
        
        guard let username = aDecoder.decodeObject(forKey: "Username") as? String else {
            return nil
        }
        
        guard let password = aDecoder.decodeObject(forKey: "Password") as? String else {
            return nil
        }
        
        guard let name = aDecoder.decodeObject(forKey: "Name") as? String else {
            return nil
        }
        
        guard let path = aDecoder.decodeObject(forKey: "Path") as? String else {
            return nil
        }
        
        guard let port = aDecoder.decodeObject(forKey: "Port") as? UInt64 else {
            return nil
        }
        
        self.host = host
        self.username = username
        self.password = password
        self.name = name
        self.path = path
        self.port = port
        useSFTP = aDecoder.decodeBool(forKey: "Use SFTP")
        os = aDecoder.decodeObject(forKey: "OS") as? String
    }
    
    // MARK: - Static
    
    public static func ==(lhs: RemoteConnection, rhs: RemoteConnection) -> Bool {
        return (lhs.host == rhs.host && lhs.username == rhs.username && lhs.password == rhs.password && lhs.name == rhs.name && lhs.path == rhs.path && lhs.port == rhs.port && lhs.useSFTP == rhs.useSFTP)
    }
}

