// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

extension UIView {
    
    /// Returns the cell used for displaying files from nib.
    static var filesTableViewCell: FileTableViewCell {
        return (Bundle.main.loadNibNamed("File Cell", owner: nil, options: nil)?[0] as? FileTableViewCell) ?? FileTableViewCell()
    }
    
    /// Returns the white toolbar used with the terminal from nib.
    static var whiteTerminalToolbar: UIToolbar {
        return (Bundle.main.loadNibNamed("Terminal Toolbar-White", owner: nil, options: nil)?[0] as? UIToolbar) ?? UIToolbar()
    }
    
    /// Returns the black toolbar used with the terminal from nib.
    static var blackTerminalToolbar: UIToolbar {
        return (Bundle.main.loadNibNamed("Terminal Toolbar-Black", owner: nil, options: nil)?[0] as? UIToolbar) ?? UIToolbar()
    }
    
    /// Returns the view used to resume a connection.
    static var disconnected: UIView {
        return (Bundle.main.loadNibNamed("Disconnected", owner: nil, options: nil)?[0] as? UIView) ?? UIView()
    }
}
