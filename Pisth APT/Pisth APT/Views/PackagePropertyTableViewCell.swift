// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Table view cell for displaying a property of a package.
class PackagePropertyTableViewCell: UITableViewCell {
 
    /// The label containing the property name.
    @IBOutlet weak var nameLabel: UILabel!
    
    /// The text view containing the property value.
    @IBOutlet weak var contentTextView: UITextView!
    
    /// The height constraint for `contentTextView`.
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
}
