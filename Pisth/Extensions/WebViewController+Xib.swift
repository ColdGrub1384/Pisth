//
//  WebViewController+Xib.swift
//  Pisth
//
//  Created by Adrian Labbe on 10/31/18.
//  Copyright © 2018 ADA. All rights reserved.
//

import UIKit
import Pisth_Shared

extension WebViewController {
    
    static func makeViewController() -> WebViewController {
        return UINib(nibName: "Web", bundle: nil).instantiate(withOwner: nil, options: nil).first! as! WebViewController
    }
}
