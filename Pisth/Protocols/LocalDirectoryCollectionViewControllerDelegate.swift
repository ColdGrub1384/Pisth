// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Delegate used by `LocalDirectoryCollectionViewController`s.
protocol LocalDirectoryCollectionViewControllerDelegate {
    
    /// Called when opening a local file with `LocalDirectoryCollectionViewController`
    /// ## Note
    /// If the `LocalDirectoryCollectionViewController`'s delegate is set, this function will override the default handler.
    ///
    /// Use: `LocalDirectoryCollectionViewController.openFile(_:, from:, in:, navigationController:, showActivityViewControllerInside:)` to call the default handler.
    ///
    ///
    /// - Parameters:
    ///     - localDirectoryCollectionViewController: Source `LocalDirectoryCollectionViewController`.
    ///     - file: File opened.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenFile file: URL)
    
    /// Called when opening a local directory with `LocalDirectoryCollectionViewController`
    /// ## Note
    /// If the `LocalDirectoryCollectionViewController`'s delegate is set, this function will override the default handler.
    /// If you want to present the directory, present `LocalDirectoryCollectionViewController`,
    /// LocalDirectoryCollectionViewController is not the source controller, but the controller to be opened.
    ///
    ///
    /// - Parameters:
    ///     - localDirectoryCollectionViewController: Source `LocalDirectoryCollectionViewController`.
    ///     - directory: File opened.
    func localDirectoryCollectionViewController(_ localDirectoryCollectionViewController: LocalDirectoryCollectionViewController, didOpenDirectory directory: URL)
}
