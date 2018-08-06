// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

fileprivate var source: UIViewController?

extension UIDragItem {
    
    /// The view controller where the item is from.
    var sourceViewController: UIViewController? {
        get {
            return source
        }
        
        set {
            source = newValue
        }
    }
}

