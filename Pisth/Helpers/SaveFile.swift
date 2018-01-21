// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Representation of file to upload.
/// This is used did edit a text file,
///
/// `localFile` is the local file edited,
/// and `remoteFile` is the remote path where send file after saving.
struct SaveFile {
    
    /// The local file edited.
    var localFile: String
    
    /// The remote path where send file after saving.
    var remoteFile: String
}
