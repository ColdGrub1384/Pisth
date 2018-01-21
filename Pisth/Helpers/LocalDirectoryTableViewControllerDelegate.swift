// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Delegate used by `LocalDirectoryTableViewController`s
protocol LocalDirectoryTableViewControllerDelegate {
    
    /// Called did open a local file with `LocalDirectoryTableViewController`
    /// ## Note
    /// If the `LocalDirectoryTableViewController`'s delegate is set, this function will override the default handler.
    ///
    /// Use: `LocalDirectoryViewController.openFile(_:, from:, in:, navigationController:, showActivityViewControllerInside:)` to call the default handler.
    ///
    ///
    /// - Parameters:
    ///     - localDirectoryTableViewController: Source `LocalDirectoryTableViewController`.
    ///     - file: File opened.
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL)
}
