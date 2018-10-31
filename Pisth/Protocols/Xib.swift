//
//  Xib.swift
//  Pisth
//
//  Created by Adrian Labbe on 10/31/18.
//  Copyright © 2018 ADA. All rights reserved.
//

import UIKit

/// A protocol for View controllers to be instantiated from Xib.
protocol Xib: ViewControllerFactory {
    
    /// The nib name where the View controller will be instantiated from.
    static var nibName: String { get }
}

extension Xib {
    
    /// The bundle where the nib is located. If set to `nil`, the main bundle will be used.
    static var nibBundle: Bundle? {
        return nil
    }
    
    static func makeViewController() -> Self {
        let vc = self.init(nibName: nibName, bundle: nibBundle)
        configure(viewController: vc)
        return vc
    }
}
