// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Delegate used by `DirectoryCollectionViewController`s.
protocol DirectoryCollectionViewControllerDelegate {
    
    /// Called when opening a remote directoty with `DirectoryCollectionViewController`.
    ///
    /// ## Note
    /// This will override the default handler.
    /// If you want to present the directory, present `directoryCollectionViewController`,
    /// directoryCollectionViewController is not the source controller, but the controller to be opened.
    ///
    /// - Parameters:
    ///     - directoryCollectionViewController: The DirectoryCollectionViewController to be opened.
    ///     - directory: The remote path to the directory to be opened.
    func directoryCollectionViewController(_ directoryCollectionViewController: DirectoryCollectionViewController, didOpenDirectory directory: String)
}


