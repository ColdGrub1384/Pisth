// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation
import StoreKit
import ObjectUserDefaults

/// Helper used to request app review based on app launches.
class ReviewHelper {
    
    /// Request review and reset points.
    func requestReview() {
        
        if minLaunches.value == nil {
            minLaunches.integerValue = 0
        } else if (minLaunches.value as! Int) == 0 {
            minLaunches.integerValue = 3
        } else if launches == 3 {
            minLaunches.integerValue = 5
        } else if launches == 5 {
            minLaunches.integerValue = -1
        }
        
        if launches >= minLaunches.integerValue {
            launches = 0
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(1 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                    print(UIApplication.shared.windows.count)
                    if UIApplication.shared.windows.count > 2 {
                        _ = TerminalViewController.current?.resignFirstResponder()
                    }
                })
            }
        }
    }
    
    // MARK: - Singleton
    
    /// Shared and unique instance.
    static let shared = ReviewHelper()
    private init() {}
    
    // MARK: - Launches tracking
    
    /// App launches incremented in `AppDelegate.application(_:, didFinishLaunchingWithOptions:)`.
    ///
    /// Launches are saved to `UserDefaults`.
    var launches: Int {
        
        get {
            return UserDefaults.standard.integer(forKey: "launches")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "launches")
        }
    }
    
    /// Minimum launches for asking for review.
    var minLaunches = ObjectUserDefaults.standard.item(forKey: "minLaunches")
}
