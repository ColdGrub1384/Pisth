//
//  ConnectionManager.swift
//  Pisth
//
//  Created by Adrian on 25.12.17.
//

import NMSSH

class ConnectionManager {
    
    static let shared = ConnectionManager()
    private init() {}
    
    var session: NMSSHSession?
    var helpSession: NMSSHSession?
    var saveFile: SaveFile?
    var connection: RemoteConnection?
    
    func files(inDirectory directory: String) -> [String]? {
        guard let session = session else { return nil }
        
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
        
        helpSession = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
        helpSession?.connect()
        if helpSession!.isConnected {
            helpSession?.authenticate(byPassword: connection.password)
        }
        
        if helpSession!.isConnected && helpSession!.isAuthorized {
            helpSession?.sftp.connect()
        }
        
        return (session!.isConnected && session!.isAuthorized && session!.sftp.isConnected)
    }
}
