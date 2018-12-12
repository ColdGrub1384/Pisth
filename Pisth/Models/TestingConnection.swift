// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// This type contains credentials for tesing connections. Can be used on tests.
struct TestingConnection {
    
    private init() {}
    
    /// The username.
    static let username = "pisthtest"
    
    /// The password corresponding to `username`.
    static let password = "pisth"
    
    /// The host.
    static let host = "raspberrypi.local"
}
