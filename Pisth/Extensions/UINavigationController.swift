// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

extension UINavigationController {
    
    /// Pushes a view controller onto the receiver’s stack and updates the display.
    /// The object in the viewController parameter becomes the top view controller on the navigation stack. Pushing a view controller causes its view to be embedded in the navigation interface. If the animated parameter is true, the view is animated into position; otherwise, the view is simply displayed in its final location.
    /// In addition to displaying the view associated with the new view controller at the top of the stack, this method also updates the navigation bar and tool bar accordingly.
    ///
    /// This is a function added in an extension adding the possibility to handle the completion.
    ///
    /// - Parameters:
    ///
    ///     - viewController: The view controller to push onto the stack. This object cannot be a tab bar controller. If the view controller is already on the navigation stack, this method throws an exception.
    ///
    ///     - animated: Specify true to animate the transition or false if you do not want the transition to be animated. You might specify false if you are setting up the navigation controller at launch time.
    ///
    ///     - completion: Function to execute after finishing the animation.
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)
        
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
    
    /// Pops view controllers until the specified view controller is at the top of the navigation stack.
    ///
    /// This is a function added in an extension adding the possibility to handle the completion.
    ///
    /// - Parameters:
    ///
    ///     - viewController: The view controller that you want to be at the top of the stack. This view controller must currently be on the navigation stack. controller. If the view controller is already on the navigation stack, this method throws an exception.
    ///
    ///     - animated: Set this value to true to animate the transition. Pass false if you are setting up a navigation controller before its view is displayed.
    ///
    ///     - completion: Function to execute after finishing the animation.
    func popToViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        popToViewController(viewController, animated: animated)
        
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
    
    /// This method removes the top view controller from the stack and makes the new top of the stack the active view controller. If the view controller at the top of the stack is the root view controller, this method does nothing. In other words, you cannot pop the last item on the stack.
    /// In addition to displaying the view associated with the new view controller at the top of the stack, this method also updates the navigation bar and tool bar accordingly. For information on how the navigation bar is updated.
    ///
    /// This is a function added in an extension adding the possibility to handle the completion.
    ///
    /// - Parameters:
    ///
    ///     - animated: Set this value to true to animate the transition. Pass false if you are setting up a navigation controller before its view is displayed.
    ///
    ///     - completion: Function to execute after finishing the animation.
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)
        
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
    
    /// Pops all the view controllers on the stack except the root view controller and updates the display.
    /// The root view controller becomes the top view controller.
    ///
    /// This is a function added in an extension adding the possibility to handle the completion.
    ///
    /// - Parameters:
    ///
    ///     - animated: Set this value to true to animate the transition. Pass false if you are setting up a navigation controller before its view is displayed.
    ///
    ///     - completion: Function to execute after finishing the animation.
    func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
        popToRootViewController(animated: animated)
        
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
