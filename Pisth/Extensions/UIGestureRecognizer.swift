// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

fileprivate var nameKey = "name"

extension UIGestureRecognizer {
    
    var gestureName: String {
        get {
            guard let value = objc_getAssociatedObject(self, &nameKey) as? String else {
                return ""
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &nameKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
