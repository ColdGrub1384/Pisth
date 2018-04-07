
import UIKit

extension UIWindow {
    
    /// Get the top view controller on this window.
    ///
    /// - Returns: The top view controller, the visible view controller of a navigation controller or the selected view controller of a tab bar controller.
    func topViewController() -> UIViewController? {
        var top = self.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
        return top
    }
}
