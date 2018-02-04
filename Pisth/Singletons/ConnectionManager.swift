// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import NMSSH

/// A class that manages SSH connections.
class ConnectionManager {
    
    /// Shared and unique instance of ConnectionManager.
    static let shared = ConnectionManager()
    private init() {}
    
    
    // NMSSH cannot download files and write to an SSH Shell at same time, so two sessions are used.
    
    /// Session used for SSH Shell.
    var session: NMSSHSession?
    
    /// Session used for reading and writing files.
    var filesSession: NMSSHSession?
    
    
    /// Text file to be uploaded after being edited.
    var saveFile: SaveFile?
    
    /// Representation of the connection to use.
    var connection: RemoteConnection?
    
    /// Representation of the result connecting.
    var result = ConnectionResult.notConnected
    
    /// List files in directory.
    /// - Parameters:
    ///     - directory: Directory where list files.
    /// - Returns: Files listed, nil in case of error.
    func files(inDirectory directory: String) -> [NMSFTPFile]?  {
        guard let session = filesSession else { return [] }
        
        guard var files = session.sftp.contentsOfDirectory(atPath: directory) as? [NMSFTPFile] else {
            return nil
        }
        
        if !UserDefaults.standard.bool(forKey: "hidden") { // Remove hidden files if is necessary
            for file in files {
                if file.filename.hasPrefix(".") {
                    guard let i = files.index(of: file) else { break }
                    files.remove(at: i)
                }
            }
        }
        
        return files
        
    }
    
    /// Open SSH sessions for `connection`.
    func connect() {
        
        guard let connection = connection else {
            result = .notConnected
            return
        }
        
        session = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
        session?.connect()
        if session!.isConnected {
            result = .connected
            session?.authenticate(byPassword: connection.password)
        } else {
            result = .notConnected
            return
        }
        
        if session!.isConnected && session!.isAuthorized {
            
            if connection.useSFTP {
                session?.sftp.connect()
            }
            
            result = .connectedAndAuthorized
        } else {
            return
        }
        
        if connection.useSFTP {
            
            filesSession = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
            filesSession?.connect()
            if filesSession!.isConnected {
                result = .connected
                filesSession?.authenticate(byPassword: connection.password)
            } else {
                result = .notConnected
                return
            }
            
            if filesSession!.isConnected && filesSession!.isAuthorized {
                filesSession?.sftp.connect()
                result = .connectedAndAuthorized
            } else {
                return
            }
        }
        
        session!.channel.requestPty = true
        session!.channel.ptyTerminalType = .xterm
        
        if result == .connectedAndAuthorized {
            do {
                // Start the shell to not close the connection when enter in background
                if connection.useSFTP {
                    try session?.channel.startShell()
                    try filesSession?.channel.startShell()
                }
            } catch {
                result = .notConnected
            }
        }
    }
}
