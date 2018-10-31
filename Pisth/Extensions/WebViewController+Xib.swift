// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

extension WebViewController {
    
    static func makeViewController() -> WebViewController {
        return UINib(nibName: "Web", bundle: nil).instantiate(withOwner: nil, options: nil).first! as! WebViewController
    }
}
