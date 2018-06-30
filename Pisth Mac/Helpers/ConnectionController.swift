// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import Pisth_Shared

/// A class for representing actibe remote sessions.
class ConnectionController {
    
    private func closeMainScreen() {
        for window in NSApp.windows {
            if window.contentViewController is BookmarksViewController {
                window.close()
            }
        }
    }
    
    /// Show hidden files.
    static var showHiddenFiles: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "showHiddenFiles")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "showHiddenFiles")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Info for the current connection.
    let connection: RemoteConnection
    
    /// Session used for SFTP.
    let session: NMSSHSession
    
    /// Session used for the shell.
    let shellSession: NMSSHSession
    
    /// Home of the current user.
    var home: String?
    
    /// Copied file paths for this connection.
    var selectedFilePaths = [String]()
    
    /// Present the terminal.
    ///
    /// - Parameters:
    ///     - path: CWD.
    func presentTerminal(path: String? = nil) {
        guard let wc = NSStoryboard(name: "Connection", bundle: Bundle.main).instantiateController(withIdentifier: "terminal") as? NSWindowController, let termVC = wc.contentViewController as? TerminalViewController else {
            return
        }
        
        shellSession.channel.closeShell()
        
        wc.window?.title = connection.username+"@"+connection.host
        
        termVC.pwd = path
        termVC.controller = self
        termVC.window = wc.window
        
        wc.showWindow(nil)
        closeMainScreen()
    }
    
    /// Present the given directory.
    ///
    /// - Parameters:
    ///     - path: Directory to open.
    func presentBrowser(atPath path: String) {
        
        let parsedPath = path.replacingFirstOccurrence(of: "~", with: home ?? "~")
        
        guard let wc = NSStoryboard(name: "Connection", bundle: Bundle.main).instantiateController(withIdentifier: "directory") as? NSWindowController else {
            return
        }
        
        guard let dirVC = wc.contentViewController as? DirectoryViewController else {
            return
        }
        
        dirVC.localPath = NSTemporaryDirectory().nsString.appendingPathComponent(parsedPath)
        dirVC.directory = parsedPath
        dirVC.window = wc.window
        dirVC.controller = self
        
        for toolbarItem in wc.window?.toolbar?.items ?? [] {
            if toolbarItem.itemIdentifier.rawValue == "path" {
                (toolbarItem.view as? NSTextField)?.stringValue = parsedPath
                (toolbarItem.view as? NSTextField)?.delegate = dirVC
            } else if toolbarItem.itemIdentifier.rawValue == "goBack" {
                toolbarItem.action = #selector(dirVC.goBack)
                toolbarItem.isEnabled = (parsedPath != "/")
            } else if toolbarItem.itemIdentifier.rawValue == "refresh" {
                toolbarItem.action = #selector(dirVC.refresh)
            }
        }
        
        try? FileManager.default.createDirectory(atPath: dirVC.localPath!, withIntermediateDirectories: true, attributes: nil)
        wc.window?.setTitleWithRepresentedFilename(dirVC.localPath!)
        
        wc.showWindow(nil)
        closeMainScreen()
    }
    
    /// Initialize from given remote connection.
    init(connection: RemoteConnection) throws {
        self.connection = connection
        if connection.useSFTP {
            session = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username)
        } else {
            session = NMSSHSession(host: connection.host, port: Int(connection.port), andUsername: connection.username)
        }
        shellSession = NMSSHSession.connect(toHost: connection.host, port: Int(connection.port), withUsername: connection.username)
        
        func openShell() throws {
            if shellSession.isConnected {
                shellSession.authenticate(byPassword: connection.password)
                if shellSession.isAuthorized {
                    home = try? shellSession.channel.execute("echo ~").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                    shellSession.channel.requestPty = true
                    shellSession.channel.ptyTerminalType = .xterm
                } else {
                    throw NSError(domain:"", code:1, userInfo:[ NSLocalizedDescriptionKey: "Cannot connect to the session. Check for the hostname and, the port and the username."])
                }
            } else {
                throw NSError(domain:"", code:1, userInfo:[ NSLocalizedDescriptionKey: "Cannot connect to the session. Check for the hostname and, the port and the username."])
            }
        }
        
        if connection.useSFTP {
            if session.isConnected {
                session.authenticate(byPassword: connection.password)
                if session.isAuthorized {
                    session.sftp.connect()
                    
                    do {
                        try openShell()
                    } catch {
                        throw error
                    }
                } else {
                    throw NSError(domain:"", code:2, userInfo:[ NSLocalizedDescriptionKey: "Cannot authenticate. Check for the username and the password."])
                }
            } else {
                throw NSError(domain:"", code:1, userInfo:[ NSLocalizedDescriptionKey: "Cannot connect to the session. Check for the hostname and, the port and the username."])
            }
        } else {
            do {
                try openShell()
            } catch {
                throw error
            }
        }
    }
}
