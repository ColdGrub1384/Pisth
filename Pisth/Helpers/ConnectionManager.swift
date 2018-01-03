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
    
    var timer: Timer?
    
    func files(inDirectory directory: String) -> [String]? {
        guard let session = filesSession else { return nil }
        
        do {
            let ls = try session.channel.execute("for file in \"\(directory)\"/*; do if [[ -d $file ]]; then printf \"$file/\n\"; elif [[ -x $file ]]; then  printf \"./$file\n\"; else printf \"$file\n\"; fi; done")
            var result = ls.components(separatedBy: "\n")
            result.removeLast()
            return result
        } catch {}
        
        return nil
    }
    
    func connect() -> Bool {
        
        guard let connection = connection else { return false }
        
        session = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
        session?.connect()
        if session!.isConnected {
            session?.authenticate(byPassword: connection.password)
        }
        
        if session!.isConnected && session!.isAuthorized {
            session?.sftp.connect()
        }
        
        filesSession = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
        filesSession?.connect()
        if filesSession!.isConnected {
            filesSession?.authenticate(byPassword: connection.password)
        }
        
        if filesSession!.isConnected && filesSession!.isAuthorized {
            filesSession?.sftp.connect()
        }
        
        session!.channel.requestPty = true
        session!.channel.ptyTerminalType = .ansi
        
        do {
            // Start the shell to not close the connection when enter in background
            try session?.channel.startShell()
            try filesSession?.channel.startShell()
        } catch {
            return false
        }
        
        do {
            for command in ShellStartup.commands {
                try session!.channel.write("\(command); sleep 0.1; history -d $(history 1)\n")
            }
        } catch {
            return false
        }
        
        return (session!.isConnected && session!.isAuthorized && session!.sftp.isConnected && filesSession!.isConnected && filesSession!.isAuthorized && filesSession!.sftp.isConnected)
    }
}
