//
//  isPDF.swift
//  Pisth
//
//  Created by Adrian on 28.12.17.
//

import Foundation

func isFilePDF(_ file: URL) -> Bool {
    
    guard let assetData = try? Data(contentsOf: file) else { return false }
    
    if assetData.count >= 1024 {
        var pdfBytes = [UInt8]()
        pdfBytes = [ 0x25, 0x50, 0x44, 0x46]
        let pdfHeader = Data.init(bytes: pdfBytes, count: 4)
        guard let foundRange = assetData.range(of: pdfHeader, options: [], in: Range(NSRange(location: 0, length: 1024))) else { return false }
        if foundRange.count > 0 {
            return true
        }
    }
    
    return false
}

