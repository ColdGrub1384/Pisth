// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import NMSSH
import Pisth_Shared

private let sharedInstance = ConnectionManager()
private let importInstance = ConnectionManager()

/// A class that manages SSH connections.
class ConnectionManager {
    
    /// Shared instance of `ConnectionManager`. Different instance is returned for importing file with the api.
    static var shared: ConnectionManager {
        if AppDelegate.shared.action != nil {
            return importInstance
        } else {
            return sharedInstance
        }
    }
    
    /// Initialize a `ConnectionManager` for managing given connection.
    ///
    /// - Parameters:
    ///     - connection: Connection used to connect.
    init(connection: RemoteConnection? = nil) {
        self.connection = connection
    }
    
    /// Background task to keep the session active.
    var backgroundTask: UIBackgroundTaskIdentifier?
    
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
    func files(inDirectory directory: String, showHiddenFiles: Bool = false) -> [NMSFTPFile]?  {
        guard let session = filesSession else { return nil }
        
        guard var files = session.sftp.contentsOfDirectory(atPath: directory) else {
            return nil
        }
        
        if !showHiddenFiles { // Remove hidden files if is necessary
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
            if let privKey = connection.privateKey {
                session?.authenticateBy(inMemoryPublicKey: connection.publicKey, privateKey: privKey, andPassword: connection.password)
            } else {
                session?.authenticate(byPassword: connection.password)
            }
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
                if let privKey = connection.privateKey {
                    filesSession?.authenticateBy(inMemoryPublicKey: connection.publicKey, privateKey: privKey, andPassword: connection.password)
                } else {
                    filesSession?.authenticate(byPassword: connection.password)
                }
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
                    
                    backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
            } catch {
                result = .notConnected
            }
        }
    }
}
