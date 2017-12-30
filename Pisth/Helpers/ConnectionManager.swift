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
    
    var saveFile: SaveFile?
    
    func files(inDirectory directory: String) -> [String]? {
        guard let session = session else { return nil }
        
        do {
            let ls = try session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.session.channel.execute("for file in \"\(directory)\"/*; do if [[ -d $file ]]; then printf \"$file/\n\"; else printf \"$file\n\"; fi; done")
            var result = ls.components(separatedBy: "\n")
            result.removeLast()
            return result
        } catch {}
        
        return nil
    }
    
    func connect(to remote: RemoteConnection) -> Bool {
        session = NMSSHSession(host: remote.host, port: Int(remote.port), andUsername: remote.username)
        session?.connect()
        if session!.isConnected {
            session?.authenticate(byPassword: remote.password)
        }
        
        if session!.isConnected && session!.isAuthorized {
            session?.sftp.connect()
        }
        
        return (session!.isConnected && session!.isAuthorized && session!.sftp.isConnected)
    }
}
