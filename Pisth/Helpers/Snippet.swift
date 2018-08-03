// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// A class representing a shell snippet.
class Snippet: NSObject, NSCoding {
    
    /// The name of the snippet.
    var name: String
    
    /// The content of the snippet.
    var content: String
    
    /// Initialize with given info.
    ///
    /// - Parameters:
    ///     - name: The name of the snippet.
    ///     - content: The content of the snippet.
    init(name: String, content: String) {
        self.name = name
        self.content = content
    }
    
    // MARK: - Coding
    
    /// Encode data.
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(content, forKey: "content")
    }
    
    /// Decode data.
    required init?(coder aDecoder: NSCoder) {
        
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            return nil
        }
        
        guard let content = aDecoder.decodeObject(forKey: "content") as? String else {
            return nil
        }
        
        self.name = name
        self.content = content
    }
}
