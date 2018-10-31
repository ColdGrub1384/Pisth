// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

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
