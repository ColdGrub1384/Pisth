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
    
    func files(inDirectory directory: String) -> [String]? {
        guard let session = session else { return nil }
        
        do {
            let ls = try session.channel.execute("ls -1 -d '\(directory)'/*")
            var result = ls.components(separatedBy: "\n")
            result.removeLast()
            return result
        } catch {}
        
        return nil
    }
    
    func isDirectory(path: String) -> Bool? {
        
        guard let session = session else { return nil }
        
        var absolutePath: String {
            if path != "~" {
                return path
            } else {
                do {
                    return try session.channel.execute("echo $HOME").replacingOccurrences(of: "\n", with: "")
                } catch {
                    return path
                }
            }
        }
        
        do {
            let isDir = try session.channel.execute("if [[ -d '\(absolutePath)' ]]; then echo \"dir\"; else echo \"file\"; fi").replacingOccurrences(of: "\n", with: "")
            return (isDir == "dir")
        } catch {}
        
        return nil
        
    }
    
    func connect(to remote: RemoteConnection) -> Bool {
        session = NMSSHSession(host: remote.host, port: Int(remote.port), andUsername: remote.username)
        session?.connect()
        if session!.isConnected {
            session?.authenticate(byPassword: remote.password)
        }
        
        return (session!.isConnected && session!.isAuthorized)
    }
}
