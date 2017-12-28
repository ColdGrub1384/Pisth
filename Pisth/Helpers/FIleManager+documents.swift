//
//  FIleManager+documents.swift
//  Pisth
//
//  Created by Adrian on 26.12.17.
//

import Foundation

extension FileManager {
    var documents: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
    }
}
