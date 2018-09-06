//
//  ObjectUserDefaults.swift
//  ObjectUserDefaults
//
//  Created by Adrian Labbe on 9/5/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import Foundation

/// An object oriented wrapper `UserDefaults`. Initialize it like an `UserDefaults`. See `ObjectUserDefaults.item(forKey:)` for getting and setting values.
public class ObjectUserDefaults: NSObject {
    
    /// The standard object for `UserDefaults.standard`
    public static let standard = ObjectUserDefaults()
    
    /// The `UserDefaults` instance associated with this object.
    private(set) public var userDefaults: UserDefaults
    
    /// Initialize for `UserDefaults.standard`.
    ///
    /// - Returns: `ObjectUserDefaults.standard`.
    public override init() {
        userDefaults = UserDefaults.standard
    }
    
    /// Initialize `UserDefaults` with given suite name.
    ///
    /// - Parameters:
    ///     - suiteName: The suite name passed to `UserDefaults(suiteName:)`.
    ///
    /// - Returns: An `ObjectUserDefaults` to be used with the `UserDefaults` initialized with given suite name. If `suiteName` is `nil`, it will return `ObjectUserDefaults.standard`
    public init?(suiteName: String? = nil) {
        if let suiteName = suiteName, let userDefaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = userDefaults
        } else if suiteName == nil {
            userDefaults = .standard
        } else {
            return nil
        }
    }
    
    // MARK: - Getters
    
    /// Use this method to get a representation of the item for the given key.
    ///
    /// - Parameters:
    ///     - key: Key used to set and get values.
    ///
    /// - Returns: A representation of the item for the given key. See `ObjectUserDefaultsItem` to set and get values.
    public func item(forKey key: String) -> ObjectUserDefaultsItem {
        return ObjectUserDefaultsItem(key: key, fromUserDefaults: userDefaults)
    }
    
    /// Returns all items stored.
    public var arrayRepresentation: [ObjectUserDefaultsItem] {
        var items = [ObjectUserDefaultsItem]()
        for (key, _) in userDefaults.dictionaryRepresentation() {
            items.append(ObjectUserDefaultsItem(key: key, fromUserDefaults: userDefaults))
        }
        return items
    }
}
