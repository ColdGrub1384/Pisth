// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Pisth_Shared

/// A snippet.
struct Snippet: Codable, Equatable {
    
    /// The title of the snippet.
    var title: String
    
    /// The content of the snippet.
    var content: String
    
    /// The connection corresponding to the snippet.
    var connection: String
    
    /// Initialize from given information
    ///
    /// - Parameters:
    ///     - title: The title of the snippet.
    ///     - content: The content of the snippet.
    ///     - connection: The connection corresponding to the snippet.
    init(title: String, content: String, connection: String) {
        self.title = title
        self.content = content
        self.connection = connection
    }
}

