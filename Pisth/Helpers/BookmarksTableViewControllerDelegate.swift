//
//  BookmarksTableViewControllerDelegate.swift
//  Pisth
//
//  Created by Adrian on 31.12.17.
//

import Foundation

protocol BookmarksTableViewControllerDelegate {
    func bookmarksTableViewController(_ bookmarksTableViewController: BookmarksTableViewController, didOpenConnection: RemoteConnection, inDirectoryTableViewController directoryTableViewController: DirectoryTableViewController)
}
