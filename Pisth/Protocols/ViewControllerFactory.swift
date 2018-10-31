// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// A protocol that implements a View controller factory. Used in `Storyboard` and `Xib`.
protocol ViewControllerFactory where Self: UIViewController {
    
    /// Initializes a new View controller.
    ///
    /// - Returns: A newly initialized View controller.
    static func makeViewController() -> Self
}

extension ViewControllerFactory {
    
    /// Configures a View controller just after making it from `makeViewController`.
    ///
    /// - Parameters:
    ///     - viewController: The View controller to configure.
    static func configure(viewController: Self) {}
}
