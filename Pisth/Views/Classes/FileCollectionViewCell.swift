// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared
import NMSSH

/// Table View Cell that represents a remote or local file.
class FileCollectionViewCell: UICollectionViewCell {
    
    /// File's icon.
    @IBOutlet weak var iconView: UIImageView!
    
    /// Filename.
    @IBOutlet weak var filename: UILabel!
    
    /// File permissions.
    @available(*, deprecated, message: "Use `more`")
    @IBOutlet weak var permssions: UILabel!
    
    /// More file information. Hidden by default.
    @IBOutlet weak var more: UILabel?
    
    /// `DirectoryTableViewController` showing this cell.
    var directoryTableViewController: DirectoryTableViewController!
    
    /// `LocalDirectoryTableViewController` showing this cell.
    var localDirectoryTableViewController: LocalDirectoryTableViewController!
    
    // MARK: - Collection view cell
    
    /// - Returns: `true` to allow moving and renaming file if this cell represents a remote file.
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let directoryTableViewController = directoryTableViewController {
            
            if directoryTableViewController.files![directoryTableViewController.collectionView!.indexPath(for: self)?.row ?? 0].isDirectory {
                
                return (action == #selector(showFileInfo(_:)) || action == #selector(deleteFile(_:)) || action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)) || action == #selector(openInNewPanel(_:)))
            }
        }
        
        return (action == #selector(shareFile(_:)) || action == #selector(deleteFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(renameFile(_:)))
    }
    
    /// `UIViewController`'s `canBecomeFirstResponder` variable.
    ///
    /// Returnns true to allow actions.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Actions
    
    /// Remove the file represented by the cell.
    @objc func deleteFile(_ sender: Any) {
        // Remove remote file
        if let directoryTableViewController = directoryTableViewController {
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            })
            
            let fileToRemove = directoryTableViewController.files![directoryTableViewController.collectionView!.indexPath(for: self)!.row]
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            }, successHandler: {
                
                let activityVC = ActivityViewController(message: "Removing...")
                
                directoryTableViewController.present(activityVC, animated: true, completion: {
                    // Remove directory
                    if fileToRemove.isDirectory {
                        
                        guard let sftp = ConnectionManager.shared.filesSession?.sftp else { return }
                        
                        func remove(directoryRecursively directory: String) -> Bool? {
                            while true {
                                guard let files = sftp.contentsOfDirectory(atPath: directory) as? [NMSFTPFile] else { return nil }
                                
                                if files.count > 0 {
                                    for file in files {
                                        if !file.isDirectory {
                                            if !sftp.removeFile(atPath: directory.nsString.appendingPathComponent(file.filename)) {
                                                
                                                return false
                                            }
                                        } else if files.count > 0 {
                                            let result = remove(directoryRecursively: directory.nsString.appendingPathComponent(file.filename))
                                            
                                            if result != nil && !result! {
                                                return false
                                            }
                                            
                                            if result == nil {
                                                return nil
                                            }
                                        } else {
                                            if !sftp.removeDirectory(atPath: directory.nsString.appendingPathComponent(file.filename)) {
                                                
                                                return false
                                            }
                                        }
                                    }
                                } else {
                                    return sftp.removeDirectory(atPath: directory)
                                }
                                
                            }
                        }
                        
                        guard let result = remove(directoryRecursively: directoryTableViewController.directory.nsString.appendingPathComponent(fileToRemove.filename)) else {
                            
                            activityVC.dismiss(animated: true, completion: {
                                directoryTableViewController.showError()
                            })
                            
                            return
                        }
                        
                        if !result {
                            activityVC.dismiss(animated: true, completion: {
                                let errorAlert = UIAlertController(title: "Error removing directory!", message: "Check for permissions", preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                directoryTableViewController.present(errorAlert, animated: true, completion: nil)
                            })
                        } else {
                            activityVC.dismiss(animated: true, completion: {
                                directoryTableViewController.reload()
                            })
                        }
                    } else { // Remove file
                        guard let result = ConnectionManager.shared.filesSession?.sftp.removeFile(atPath: directoryTableViewController.directory.nsString.appendingPathComponent(fileToRemove.filename)) else {
                            activityVC.dismiss(animated: true, completion: {
                                directoryTableViewController.showError()
                            })
                            return
                        }
                        
                        if !result {
                            activityVC.dismiss(animated: true, completion: {
                                let errorAlert = UIAlertController(title: "Error removing file!", message: "Check for permissions", preferredStyle: .alert)
                                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                directoryTableViewController.present(errorAlert, animated: true, completion: nil)
                            })
                        } else {
                            activityVC.dismiss(animated: true, completion: {
                                directoryTableViewController.reload()
                            })
                        }
                    }
                })
                
            })
            
            // Remove local file
        } else if let localDirectoryTableViewController = localDirectoryTableViewController {
            
            let fileToRename = localDirectoryTableViewController.files[localDirectoryTableViewController.collectionView!.indexPath(for: self)!.row]
             
            do {
                try FileManager.default.removeItem(at: fileToRename)
                localDirectoryTableViewController.reload()
            } catch {
                let errorAlert = UIAlertController(title: "Error removing file!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                directoryTableViewController.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    /// Rename the file represented by the cell.
    @objc func renameFile(_ sender: Any) {
        
        // Rename remote file
        if let directoryTableViewController = directoryTableViewController {
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            })
            
            let fileToRename = directoryTableViewController.files![directoryTableViewController.collectionView!.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: "Write new file name", message: "Write new name for \(fileToRename.filename!).", preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
                textField.text = fileToRename.filename
            })
            
            renameAlert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (_) in
                guard let newFileName = renameAlert.textFields?[0].text else { return }
                guard let session = ConnectionManager.shared.filesSession else { return }
                
                if session.sftp.moveItem(atPath: directoryTableViewController.directory.nsString.appendingPathComponent(fileToRename.filename), toPath: directoryTableViewController.directory.nsString.appendingPathComponent(newFileName)) {
                   
                    directoryTableViewController.reload()
                } else {
                    let errorAlert = UIAlertController(title: "Error renaming file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    directoryTableViewController.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            directoryTableViewController.present(renameAlert, animated: true, completion: nil)
            
        // Rename local file
        } else if let localDirectoryTableViewController = localDirectoryTableViewController {
            
            let fileToRename = localDirectoryTableViewController.files[localDirectoryTableViewController.collectionView!.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: "Write new file name", message: "Write new name for \(fileToRename.lastPathComponent).", preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
                textField.text = fileToRename.lastPathComponent
            })
            
            renameAlert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (_) in
                do {
                    try FileManager.default.moveItem(at: fileToRename, to: fileToRename.deletingLastPathComponent().appendingPathComponent(renameAlert.textFields![0].text!))
                    localDirectoryTableViewController.reload()
                } catch {
                    let alert = UIAlertController(title: "Error renaming file!", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    localDirectoryTableViewController.present(alert, animated: true, completion: nil)
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            localDirectoryTableViewController.present(renameAlert, animated: true, completion: nil)
        }
    }
    
    /// Move file represented by the cell.
    @objc func moveFile(_ sender: Any) {
        
        // Move remote file
        if let directoryTableViewController = directoryTableViewController {
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            })
            
            Pasteboard.local.filePath = directoryTableViewController.directory.nsString.appendingPathComponent(directoryTableViewController.files![directoryTableViewController.collectionView!.indexPath(for: self)!.row].filename)
            
            let dirVC = DirectoryTableViewController(connection: directoryTableViewController.connection, directory: directoryTableViewController.directory)
            dirVC.navigationItem.prompt = "Select a directory where move file"
            dirVC.delegate = dirVC
            DirectoryTableViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            directoryTableViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
            
        // Move local file
        } else if let localDirectoryTableViewController = localDirectoryTableViewController {
            
            Pasteboard.local.localFilePath = localDirectoryTableViewController.directory.appendingPathComponent(localDirectoryTableViewController.files[localDirectoryTableViewController.collectionView!.indexPath(for: self)!.row].lastPathComponent).path
            
            let dirVC = LocalDirectoryTableViewController(directory: FileManager.default.documents)
            dirVC.navigationItem.prompt = "Select a directory where move file"
            dirVC.delegate = dirVC
            
            LocalDirectoryTableViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            localDirectoryTableViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    /// Open directory in new panel.
    @objc func openInNewPanel(_ sender: Any) {
        
        if let directoryTableViewController = directoryTableViewController {
            
            let filename = directoryTableViewController.files![directoryTableViewController.collectionView!.indexPath(for: self)!.row].filename
            let dir = directoryTableViewController.directory.nsString
            
            let dirToOpen: String
            
            if self.filename.text == ".." || self.filename.text == "../" {
                dirToOpen = dir.deletingLastPathComponent
            } else {
                dirToOpen = dir.appendingPathComponent(filename!)
            }
            
            ContentViewController.shared.presentBrowser(inDirectory: dirToOpen, from: self)
        }
    }
    
    /// Show file info.
    @objc func showFileInfo(_ sender: Any) {
        guard let directoryTableViewController = directoryTableViewController else {
            return
        }
        
        guard directoryTableViewController.files != nil else {
            return
        }
        
        guard let i = directoryTableViewController.collectionView?.indexPath(for: self)?.row else {
            return
        }
        
        let fileInfoVC = UIViewController.fileInfo
        fileInfoVC.file = directoryTableViewController.files?[i]
        if i != directoryTableViewController.files!.count-1 {
            fileInfoVC.parentDirectory = directoryTableViewController.directory
        } else {
            fileInfoVC.parentDirectory = directoryTableViewController.directory.nsString.deletingLastPathComponent.nsString.deletingLastPathComponent
        }
        fileInfoVC.modalPresentationStyle = .popover
        fileInfoVC.popoverPresentationController?.sourceView = self
        fileInfoVC.popoverPresentationController?.sourceRect = bounds
        fileInfoVC.popoverPresentationController?.delegate = fileInfoVC
        
        directoryTableViewController.present(fileInfoVC, animated: true)
    }
    
    /// Share local file.
    @objc func shareFile(_ sender: Any) {
        if let localDirectoryTableViewController = localDirectoryTableViewController {
            let controller = UIDocumentInteractionController(url: localDirectoryTableViewController.files[localDirectoryTableViewController.collectionView!.indexPath(for: self)!.row])
            controller.presentOpenInMenu(from: bounds, in: self, animated: true)
        }
    }
}
