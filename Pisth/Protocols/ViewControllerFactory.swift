//
//  ViewControllerFactory.swift
//  Pisth
//
//  Created by Adrian Labbe on 10/31/18.
//  Copyright © 2018 ADA. All rights reserved.
//

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
