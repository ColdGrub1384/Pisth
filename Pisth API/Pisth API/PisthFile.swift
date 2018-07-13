// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation
import UIKit

/// Object for representing an imported file.
public class PisthFile: NSObject, NSCoding {
    
    private var data_: Data
    
    /// Returns the data of the file.
    public var data: Data {
        return data_
    }
    
    private var filename_: String
    
    /// Returns the filename.
    public var filename: String {
        return filename_
    }
        
    /// Initialize with given info.
    ///
    /// - Parameters:
    ///     - data: File's data.
    ///     - file: Filename.
    public init(data: Data, filename: String) {
        data_ = data
        filename_ = filename
    }
    
    // MARK: - Coding
    
    /// Encode.
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(data, forKey: "data")
        aCoder.encode(filename, forKey: "filename")
    }
    
    /// Decode.
    public required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: "data") as? Data else {
            return nil
        }
        
        guard let filename = aDecoder.decodeObject(forKey: "filename") as? String else {
            return nil
        }
        
        data_ = data
        filename_ = filename
    }
}
