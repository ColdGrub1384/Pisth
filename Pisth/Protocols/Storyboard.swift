//
//  Storyboard.swift
//  Pisth
//
//  Created by Adrian Labbe on 10/31/18.
//  Copyright © 2018 ADA. All rights reserved.
//

import UIKit

/// A protocol for View controllers that are instantiated from Storyboard.
protocol Storyboard: ViewControllerFactory {
    
    /// The storyboard where the View controller will be instantiated from.
    static var storyboard: UIStoryboard { get }
}

extension Storyboard {
    
    /// The storyboard identifier from `storyboard`. If set to `nil`, the initial View controller will be initialised.
    static var storyboardIdentifier: String? {
        return nil
    }
}

extension Storyboard {
    
    static func makeViewController() -> Self {
        if let id = storyboardIdentifier {
            guard let vc = storyboard.instantiateViewController(withIdentifier: id) as? Self else {
                fatalError("Unable to init View controller with identifier '\(id)' from storyboard '\(storyboard)' as '\(self)'")
            }
            configure(viewController: vc)
            return vc
        } else if let vc = storyboard.instantiateInitialViewController() as? Self {
            configure(viewController: vc)
            return vc
        } else {
            fatalError("Unable to init Initial View Controller from storyboard '\(storyboard)' as '\(self)'")
        }
    }
}
