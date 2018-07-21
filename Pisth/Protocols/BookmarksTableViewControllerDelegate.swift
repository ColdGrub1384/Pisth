// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation
import Pisth_Shared

/// Delegate used by `BookmarksTableViewController`s
protocol BookmarksTableViewControllerDelegate {
    
    /// Called did opening a connection with SFTP enabled from `BookmarksTableViewController`.
    /// # Note
    /// If the delegate is set for `BookmarksTableViewController`, you need to present the `directoryCollectionViewController` manually.
    ///
    /// - Parameters:
    ///     - bookmarksTableViewController: Source `BookmarksTableViewController`.
    ///     - connection: Representation of connection to be opened.
    ///     - directoryCollectionViewController: `DirectoryCollectionViewController` to be opened.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inDirectoryCollectionViewController directoryCollectionViewController: DirectoryCollectionViewController)
    
    /// Called did opening a connection with SFTP disabled from `BookmarksTableViewController`.
    /// # Note
    /// If the delegate is set for `BookmarksTableViewController`, you need to present the `directoryCollectionViewController` manually.
    ///
    /// - Parameters:
    ///     - bookmarksTableViewController: Source `BookmarksTableViewController`.
    ///     - connection: Representation of connection to be opened.
    ///     - terminalViewController: `TerminalViewController` to be opened.
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection connection: RemoteConnection, inTerminalViewController terminalViewController: TerminalViewController)
}
