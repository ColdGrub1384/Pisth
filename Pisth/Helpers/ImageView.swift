// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Class an Image view that ignores invert colors.
class ImageView: UIImageView {
    
    /// `true`.
    override var accessibilityIgnoresInvertColors: Bool {
        return true
    }
    
}
