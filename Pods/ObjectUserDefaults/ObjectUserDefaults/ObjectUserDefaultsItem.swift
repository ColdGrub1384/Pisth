//
//  ObjectUserDefaultsItem.swift
//  ObjectUserDefaults
//
//  Created by Adrian Labbe on 9/5/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import Foundation

/// A class representing a value stored in `UserDefaults` or `ObjectUserDefaults`. The item can exist or not.
public class ObjectUserDefaultsItem: NSObject {
    
    public override var description: String {
        return String(describing: value ?? key)
    }
    
    /// The key of the object in `UserDefaults`.
    private(set) public var key: String
    
    private var userDefaults: UserDefaults
    
    internal init(key: String, fromUserDefaults userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    // MARK: - Getters and Setters
    
    private func set(_ value: Any?) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }
    
    /// Returns or sets the object associated with the specified key.
    ///
    /// - Returns: The object associated with the specified key, or `nil` if the key was not found.
    public var value: Any? {
        get {
            return userDefaults.value(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the URL associated with the specified key.
    ///
    /// Wraps `UserDefaults.url(forKey:)`.
    ///
    /// - Returns: The URL associated with the specified key. If the key doesn’t exist, this method returns `nil`.
    public var urlValue: URL? {
        get {
            return userDefaults.url(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the array associated with the specified key.
    ///
    /// Wraps `UserDefaults.array(forKey:)`.
    ///
    /// - Returns: The array associated with the specified key, or `nil` if the key does not exist or its value is not an array.
    public var arrayValue: [Any]? {
        get {
            return userDefaults.array(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the dictionary object associated with the specified key.
    ///
    /// Wraps `UserDefaults.dictionary(forKey:)`.
    ///
    /// - Returns: The dictionary object associated with the specified key, or `nil` if the key does not exist or its value is not a dictionary.
    public var dictionaryValue: [String:Any]? {
        get {
            return userDefaults.dictionary(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the string associated with the specified key.
    ///
    /// Wraps `UserDefaults.string(forKey:)`.
    ///
    /// - Returns: For string values, the string associated with the specified key; for number values, the string value of the number. Returns `nil` if the default does not exist or is not a string or number value.
    public var stringValue: String? {
        get {
            return userDefaults.string(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the array of strings associated with the specified key.
    ///
    /// Wraps `UserDefaults.stringArray(forKey:)`.
    ///
    /// - Returns: The array of string objects, or `nil` if the specified default does not exist, the default does not contain an array, or the array does not contain strings.
    public var stringArray: [String]? {
        get {
            return userDefaults.stringArray(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the data object associated with the specified key.
    ///
    /// Wraps `UserDefaults.data(forKey:)`.
    ///
    /// - Returns: The data object associated with the specified key, or `nil` if the key does not exist or its value is not a data object.
    public var dataValue: Data? {
        get {
            return userDefaults.data(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the Boolean value associated with the specified key.
    ///
    /// Wraps `UserDefaults.bool(forKey:)`.
    ///
    /// - Returns: The Boolean value associated with the specified key. If the specified key doesn‘t exist, this method returns `false`.
    public var boolValue: Bool {
        get {
            return userDefaults.bool(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the integer value associated with the specified key.
    ///
    /// Wraps `UserDefaults.integer(forKey:)`.
    ///
    /// - Returns: The integer value associated with the specified key. If the specified key doesn‘t exist, this method returns 0.
    public var integerValue: Int {
        get {
            return userDefaults.integer(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    
    /// Returns or sets the float value associated with the specified key.
    ///
    /// Wraps `UserDefaults.float(forKey:)`.
    ///
    /// - Returns: The float value associated with the specified key. If the key doesn‘t exist, this method returns 0.
    public var floatValue: Float {
        get {
            return userDefaults.float(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }
    /// Returns or sets the double value associated with the specified key.
    ///
    /// Wraps `UserDefaults.double(forKey:)`.
    ///
    /// - Returns: The double value associated with the specified key. If the key doesn‘t exist, this method returns 0.
    public var doubleValue: Double {
        get {
            return userDefaults.double(forKey: key)
        }
        
        set {
            set(newValue)
        }
    }

}
