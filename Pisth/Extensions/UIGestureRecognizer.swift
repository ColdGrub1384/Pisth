//
//  UISwipeGestureRecognizer.swift
//  Pisth
//
//  Created by Adrian Labbe on 9/2/18.
//  Copyright © 2018 ADA. All rights reserved.
//

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
