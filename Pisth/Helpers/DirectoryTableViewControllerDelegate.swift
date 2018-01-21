// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Delegate used by `DirectoryTableViewController`s
protocol DirectoryTableViewControllerDelegate {
    
    /// Called did open a remote directoty with `DirectoryTableViewController`.
    ///
    /// ## Note
    /// This will override the default handler.
    /// If you want to present the directory, present `directoryTableViewController`,
    /// directoryTableViewController is not the source controller, but the controller to be opened.
    ///
    /// - Parameters:
    ///     - directoryTableViewController: The DirectoryTableViewController to be opened.
    ///     - directory: The remote path to the directory to be opened.
    func directoryTableViewController(_ directoryTableViewController: DirectoryTableViewController, didOpenDirectory directory: String)
}


