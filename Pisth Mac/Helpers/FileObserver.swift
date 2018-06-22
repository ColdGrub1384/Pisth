// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// A class for observing changes in a file.
class FileObserver {
    private let file: URL
    private var continue_ = true
    private var lastData: Data!
    
    private static var currentObserver: FileObserver?
    
    /// Initialize for observing with given file.
    ///
    /// - Parameters:
    ///     - file: File to observe.
    init(file: URL) {
        self.file = file
    }
    
    /// Start observing file.
    ///
    /// - Parameters:
    ///     - closure: Code to execute when a change is observed.
    func start(closure: @escaping () -> Void) throws {
        FileObserver.currentObserver?.stop()
        FileObserver.currentObserver = self
        continue_ = true
        do {
            lastData = try Data(contentsOf: file)
        } catch {
            throw error
        }
        DispatchQueue.global(qos: .background).async {
            while FileManager.default.fileExists(atPath: self.file.path) && self.continue_ {
                if let currentData = try? Data(contentsOf: self.file), currentData != self.lastData {
                    self.lastData = currentData
                    closure()
                }
            }
        }
    }
    
    /// Stop observing file.
    func stop() {
        continue_ = false
    }
}
