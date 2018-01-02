//
//  Pasteboard.swift
//  Pisth
//
//  Created by Adrian on 01.01.18.
//

import Foundation

class Pasteboard {
    
    static var local = Pasteboard()
    private init() {}
    
    var filePath: String?
}
