// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Cocoa
import WebKit

/// Web view used by the terminal.
class TerminalWebView: WKWebView {
    
    /// Write text to the session.
    @objc func paste(_ sender: Any) {
        try? (window?.contentViewController as? TerminalViewController)?.controller.shellSession.channel.write(NSPasteboard.general.string(forType: .string) ?? "")
    }
}
