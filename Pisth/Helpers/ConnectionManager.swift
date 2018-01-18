// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import NMSSH

class ConnectionManager {
    
    static let shared = ConnectionManager()
    private init() {}
    
    // NMSSH cannot download files and write to an SSH Shell at same time, so two sessions are used
    var session: NMSSHSession? // Used for SSH Shell
    var filesSession: NMSSHSession? // Used for read and write files
    
    var saveFile: SaveFile?
    var connection: RemoteConnection?
    var result = ConnectionResult.notConnected
        
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
            session?.sftp.connect()
            result = .connectedAndAuthorized
        } else {
            return
        }
        
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
        
        session!.channel.requestPty = true
        session!.channel.ptyTerminalType = .xterm
        
        if result == .connectedAndAuthorized {
            do {
                // Start the shell to not close the connection when enter in background
                try session?.channel.startShell()
                try filesSession?.channel.startShell()
            } catch {
                result = .notConnected
            }
        }
    }
}
