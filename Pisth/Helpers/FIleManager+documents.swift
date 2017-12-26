//
//  FIleManager+documents.swift
//  Pisth
//
//  Created by Adrian on 26.12.17.
//  Copyright © 2017 ADA. All rights reserved.
//

import Foundation

extension FileManager {
    var documents: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
    }
}
