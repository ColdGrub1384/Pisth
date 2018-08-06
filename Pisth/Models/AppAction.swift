// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

/// Action to do when opening the app with an URL scheme.
enum AppAction {
    
    /// Export file to an app with the API.
    case apiImport
    
    /// Upload opened file.
    case upload
}
