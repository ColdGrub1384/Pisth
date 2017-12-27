//
//  DirectoryTableViewControllerDelegate.swift
//  Pisth
//
//  Created by Adrian on 27.12.17.
//

import Foundation

protocol LocalDirectoryTableViewControllerDelegate {
    func localDirectoryTableViewController(_ localDirectoryTableViewController: LocalDirectoryTableViewController, didOpenFile file: URL)
}
