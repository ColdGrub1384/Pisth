// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import WebKit
import MultipeerConnectivity

/// Pisth Viewer app for macOS.
/// This app is used to view a terminal opened from Pisth in near iOS device.
/// This app and Pisth use Multipeer connectivity framework.
/// Content received in Pisth for iOS is sent to this app.
@NSApplicationMain
class PisthViewerAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, WKNavigationDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate {
    
    /// Web view used to display licenses.
    @IBOutlet weak var licensesWebView: WKWebView!
    
    // MARK: - Show nearby devices
    
    /// Nearby devices.
    ///
    /// First item is always a peer id with display name `"Devices\n"` to show it as header, this item isn't selectable.
    var devices = [MCPeerID(displayName: "Devices\n")]
    
    /// Main and unique window.
    @IBOutlet weak var window: NSWindow!
    
    /// View displaying near devices.
    @IBOutlet weak var outlineView: NSOutlineView!
    
    /// `NSOutlineViewDataSource`'s `outlineView(_:, numberOfChildrenOfItem:)` function.
    ///
    /// - Returns: Count of `devices`.
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return devices.count
    }
    
    /// `NSOutlineViewDataSource`'s `outlineView(_:, isItemExpandable:)` function.
    ///
    /// - Returns: `false`.
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    /// `NSOutlineViewDataSource`'s `outlineView(_:, child:, ofItem:)` function.
    ///
    /// - Returns device for given index.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return devices[index]
    }
    
    /// `NSOutlineViewDelegate`'s `outlineView(_:, viewFor:?, item:)` function.
    ///
    /// - Returns: The header view if the item is the first or a cell displaying the peer display name.
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let peerID = item as? MCPeerID else {
            return nil
        }
        
        if peerID == devices[0] {
            let header = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: self)
            return header
        } else {
            guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) else {
                return nil
            }
            
            for view in cell.subviews {
                if let textField = view as? NSTextField {
                    textField.stringValue = peerID.displayName
                }
            }
            
            return cell
        }
    }
    
    /// `NSOutlineViewDelegate`'s `outlineViewSelectionDidChange(_:)` function.
    ///
    /// Invite peer for selected row.
    func outlineViewSelectionDidChange(_ notification: Notification) {
        print(outlineView.selectedRow)
        mcNearbyServiceBrowser.invitePeer(devices[outlineView.selectedRow], to: mcSession, withContext: nil, timeout: 10)
    }
    
    /// `NSOutlineViewDelegate`'s `outlineView(_:, shouldSelectItem:)` function.
    ///
    /// Disable selection for header.
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return ((item as? MCPeerID) != devices[0])
    }
    
    
    // MARK: - Connectivity
    
    /// Peer ID used for the Multipeer connectivity session.
    var peerID: MCPeerID!
    
    /// Multipeer connectivity session used to receive and send data to peers.
    var mcSession: MCSession!
    
    /// Multipeer connectivity browser used to browser nearby devices.
    var mcNearbyServiceBrowser: MCNearbyServiceBrowser!
    
    /// `MCSessionDelegate`'s `` function.
    ///
    ///
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Changed state!")
        
        if state == .connected {
            DispatchQueue.main.async {
                self.clearTerminal()
            }
        }
    }
    
    /// `MCSessionDelegate`'s `session(_:, didReceive:, fromPeer:)` function.
    ///
    /// Resize window for received size and display received message.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        NSKeyedUnarchiver.setClass(TerminalInfo.self, forClassName: "TerminalInfo")
        
        if let info = NSKeyedUnarchiver.unarchiveObject(with: data) as? TerminalInfo {
        
            DispatchQueue.main.async {
                
                let width = CGFloat(info.terminalSize[0])
                let height = CGFloat(info.terminalSize[1])+30
                self.webView.frame.size = CGSize(width: width, height: height)
                self.outlineView.superview?.superview?.frame.size.height = self.webView.frame.height
                self.window.setFrame(CGRect(origin: self.window.frame.origin, size: CGSize(width: self.webView.frame.width+self.outlineView.frame.width, height: self.webView.frame.height+20)), display: false)
                self.webView.frame.origin = CGPoint(x: self.outlineView.frame.width, y: 0)
                self.outlineView.superview?.superview?.frame.origin.y = 0
                
                self.webView.evaluateJavaScript("fit(term); writeText(\(info.message.javaScriptEscapedString))", completionHandler: nil)
            }
        }
    }
    
    /// `MCSessionDelegate`'s `session(_:, didReceive:, withName:, fromPeer:)` function.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream")
    }
    
    /// `MCSessionDelegate`'s `session(_:, didStartReceivingResourceWithName:, fromPeer:, with:)` function.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Start receiving resource")
    }
    
    /// `MCSessionDelegate`'s `session(_:, didFinishReceivingResourceWithName:, fromPeer:, at:, withError:)` function.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finish receiving resource")
    }
    
    /// `MCNearbyServiceBrowserDelegate`'s `browser(_:, foundPeer:, withDiscoveryInfo:)` function.
    ///
    /// Display found peer.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        devices.append(peerID)
        outlineView.reloadData()
        print(devices)
    }
    
    /// `MCNearbyServiceBrowserDelegate`'s `browser(_:, lostPeer:)` function.
    ///
    /// Hide lost peer.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = devices.index(of: peerID) {
            devices.remove(at: index)
        }
        outlineView.reloadData()
        print(devices)
    }
    
    
    // MARK: - Terminal
    
    /// Show help message.
    func showHelpMessage() {
        webView.evaluateJavaScript("writeText('Open a terminal from Pisth in your iOS device.')", completionHandler: nil)
    }
    
    /// Clear terminal.
    func clearTerminal() {
        webView.evaluateJavaScript("writeText('\(Keys.esc)[2J\(Keys.esc)[H\')", completionHandler: nil)
    }
    
    /// Web view used to display terminal.
    @IBOutlet weak var webView: WKWebView!
    
    
    /// `WKNavigationDelegate`'s `webView(_:, didFinish:)` function
    ///
    /// Display help message.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showHelpMessage()
    }
    
    
    // MARK: - App delegate
    
    /// `NSApplicationDelegate`'s `applicationDidFinishLaunching(_:)` function.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard let terminal = Bundle.main.url(forResource: "terminal", withExtension: "html") else {
            return
        }
        webView.loadFileURL(terminal, allowingReadAccessTo: terminal.deletingLastPathComponent())
        
        // Connectivity
        peerID = MCPeerID(displayName: Host.current().name ?? "Mac")
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        mcNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "terminal")
        mcNearbyServiceBrowser.delegate = self
        mcNearbyServiceBrowser.startBrowsingForPeers()
        
        // Licenses
        guard let licenses = Bundle.main.url(forResource: "Licenses", withExtension: "html") else {
            return
        }
        licensesWebView.loadFileURL(licenses, allowingReadAccessTo: licenses.deletingLastPathComponent())
        
        
        // Check for new version
        URLSession.shared.dataTask(with: URL(string:"https://pisth.github.io/PisthViewer/NEW_VERSION")!) { (data, _, _) in
            
            guard let data = data else {
                return
            }
            
            if let str = String(data: data, encoding: .utf8) {
                if (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) != str.components(separatedBy: "\n\n")[0] {
                        
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "New version available"
                        alert.informativeText = str
                        
                        alert.addButton(withTitle: "Update")
                        alert.addButton(withTitle: "Don't update")
                        
                        alert.alertStyle = .informational
                        
                        if alert.runModal() == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(URL(string: "https://pisth.github.io/PisthViewer")!)
                        }
                        
                        alert.beginSheetModal(for: self.window, completionHandler: nil)
                    }
                }
            }
        }.resume()
        
        // Keys handling
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) in
            
            guard var character = event.characters else {
                return nil
            }
            
            guard let utf16view = event.charactersIgnoringModifiers?.utf16 else {
                return nil
            }
            
            let key = Int(utf16view[utf16view.startIndex])
            
            switch key {
                
            // Arrow keys
            case NSUpArrowFunctionKey:
                character = Keys.arrowUp
            case NSDownArrowFunctionKey:
                character = Keys.arrowDown
            case NSLeftArrowFunctionKey:
                character = Keys.arrowLeft
            case NSRightArrowFunctionKey:
                character = Keys.arrowRight
            
            // Function Keys
            case NSF1FunctionKey:
                character = Keys.f1
            case NSF2FunctionKey:
                character = Keys.f2
            case NSF3FunctionKey:
                character = Keys.f3
            case NSF4FunctionKey:
                character = Keys.f4
            case NSF5FunctionKey:
                character = Keys.f5
            case NSF6FunctionKey:
                character = Keys.f6
            case NSF7FunctionKey:
                character = Keys.f7
            case NSF8FunctionKey:
                character = Keys.f8
            case NSF2FunctionKey:
                character = Keys.f2
            case NSF9FunctionKey:
                character = Keys.f9
            case NSF10FunctionKey:
                character = Keys.f10
            case NSF11FunctionKey:
                character = Keys.f11
            default:
                break
            }
            
            guard let data = character.data(using: .utf8) else {
                return nil
            }
            
            try? self.mcSession.send(data, toPeers: self.mcSession.connectedPeers, with: .unreliable)
            
            return nil
        }
    }
    
    
    // MARK: - Window delegate
    
    /// `NSWindowDelegate`'s `windowWillClose(_:)` function.
    ///
    /// Exit app.
    func windowWillClose(_ notification: Notification) {
        exit(0)
    }
}

