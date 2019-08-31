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
class FileCollectionViewCell: UICollectionViewCell, UIContextMenuInteractionDelegate {
    
    /// File's icon.
    @IBOutlet weak var iconView: UIImageView!
    
    /// Filename.
    @IBOutlet weak var filename: UILabel!
    
    /// File permissions.
    @available(*, deprecated, message: "Use `more`")
    @IBOutlet weak var permssions: UILabel!
    
    /// More file information. Hidden by default.
    @IBOutlet weak var more: UILabel?
    
    /// `DirectoryCollectionViewController` showing this cell.
    var directoryCollectionViewController: DirectoryCollectionViewController!
    
    /// `LocalDirectoryCollectionViewController` showing this cell.
    var localDirectoryCollectionViewController: LocalDirectoryCollectionViewController!
    
    // MARK: - Collection view cell
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if #available(iOS 13.0, *) {
            var containsMenuInteraction = false
            for interaction in interactions {
                if interaction is UIContextMenuInteraction {
                    containsMenuInteraction = true
                    break
                }
            }
            if !containsMenuInteraction {
                addInteraction(UIContextMenuInteraction(delegate: self))
            }
        }
        
        let view = UIView()
        view.backgroundColor = window?.tintColor
        selectedBackgroundView = view
        
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
            more?.textColor = .secondaryLabel
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                filename.textColor = .white
            } else {
                if #available(iOS 13.0, *) {
                    filename.textColor = .label
                } else {
                    filename.textColor = .black
                }
            }
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if #available(iOS 13.0, *) {
            return false
        }
        
        if let directoryCollectionViewController = directoryCollectionViewController {
            
            if directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)?.row ?? 0].isDirectory {
                
                return (action == #selector(showFileInfo(_:)) || action == #selector(deleteFile(_:)) || action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)) || action == #selector(openInNewPanel(_:)))
            } else {
                return (action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(showFileInfo(_:)) || action == #selector(deleteFile(_:)) || action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)))
            }
        }
        
        return (action == #selector(shareFile(_:)) || action == #selector(deleteFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(renameFile(_:)))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Actions
    
    /// Remove the file represented by the cell.
    @objc func deleteFile(_ sender: Any) {
        // Remove remote file
        if let directoryCollectionViewController = directoryCollectionViewController {
            
            directoryCollectionViewController.checkForConnectionError(errorHandler: {
                directoryCollectionViewController.showError()
            })
            
            let fileToRemove = directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)!.row]
            
            directoryCollectionViewController.checkForConnectionError(errorHandler: {
                directoryCollectionViewController.showError()
            }, successHandler: {
                
                let activityVC = ActivityViewController(message: Localizable.FileCollectionViewCell.removing)
                
                directoryCollectionViewController.present(activityVC, animated: true, completion: {
                    // Remove directory
                    if fileToRemove.isDirectory {
                        
                        guard let sftp = ConnectionManager.shared.filesSession?.sftp else { return }
                        
                        func remove(directoryRecursively directory: String) -> Bool? {
                            while true {
                                guard let files = sftp.contentsOfDirectory(atPath: directory) else { return nil }
                                
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
                        
                        ConnectionManager.shared.queue.async {
                            guard let result = remove(directoryRecursively: directoryCollectionViewController.directory.nsString.appendingPathComponent(fileToRemove.filename)) else {
                                
                                DispatchQueue.main.async {
                                    activityVC.dismiss(animated: true, completion: {
                                        directoryCollectionViewController.showError()
                                    })
                                }
                                
                                return
                            }
                            
                            DispatchQueue.main.async {
                                if !result {
                                    activityVC.dismiss(animated: true, completion: {
                                        let errorAlert = UIAlertController(title: Localizable.FileCollectionViewCell.errorRemovingFile, message: Localizable.DirectoryCollectionViewController.checkForPermssions, preferredStyle: .alert)
                                        errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                                        directoryCollectionViewController.present(errorAlert, animated: true, completion: nil)
                                    })
                                } else {
                                    activityVC.dismiss(animated: true, completion: {
                                        directoryCollectionViewController.reload()
                                    })
                                }
                            }
                        }
                    } else { // Remove file
                        ConnectionManager.shared.queue.async {
                            guard let result = ConnectionManager.shared.filesSession?.sftp.removeFile(atPath: directoryCollectionViewController.directory.nsString.appendingPathComponent(fileToRemove.filename)) else {
                                DispatchQueue.main.async {
                                    activityVC.dismiss(animated: true, completion: {
                                        directoryCollectionViewController.showError()
                                    })
                                }
                                return
                            }
                            
                            DispatchQueue.main.async {
                                if !result {
                                    activityVC.dismiss(animated: true, completion: {
                                        let errorAlert = UIAlertController(title: Localizable.FileCollectionViewCell.errorRemovingFile, message: Localizable.DirectoryCollectionViewController.checkForPermssions, preferredStyle: .alert)
                                        errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: nil))
                                        directoryCollectionViewController.present(errorAlert, animated: true, completion: nil)
                                    })
                                } else {
                                    activityVC.dismiss(animated: true, completion: {
                                        directoryCollectionViewController.reload()
                                    })
                                }
                            }
                        }
                    }
                })
                
            })
            
            // Remove local file
        } else if let localDirectoryCollectionViewController = localDirectoryCollectionViewController {
            
            let fileToRename = localDirectoryCollectionViewController.files[localDirectoryCollectionViewController.collectionView!.indexPath(for: self)!.row]
             
            do {
                try FileManager.default.removeItem(at: fileToRename)
                localDirectoryCollectionViewController.reload()
            } catch {
                let errorAlert = UIAlertController(title: Localizable.FileCollectionViewCell.errorRemovingFile, message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: nil))
                localDirectoryCollectionViewController.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    /// Rename the file represented by the cell.
    @objc func renameFile(_ sender: Any) {
        
        // Rename remote file
        if let directoryCollectionViewController = directoryCollectionViewController {
            
            directoryCollectionViewController.checkForConnectionError(errorHandler: {
                directoryCollectionViewController.showError()
            })
            
            let fileToRename = directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: Localizable.FileCollectionViewCell.renameFileTitle, message: Localizable.FileCollectionViewCell.rename(file: fileToRename.filename), preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.FileCollectionViewCell.newFileName
                
                var name = fileToRename.filename 
                if name.hasSuffix("/") {
                    name.removeLast()
                }
                textField.text = name
            })
            
            renameAlert.addAction(UIAlertAction(title: Localizable.FileCollectionViewCell.rename, style: .default, handler: { (_) in
                guard let newFileName = renameAlert.textFields?[0].text else { return }
                guard let session = ConnectionManager.shared.filesSession else { return }
                
                ConnectionManager.shared.queue.async {
                    if session.sftp.moveItem(atPath: directoryCollectionViewController.directory.nsString.appendingPathComponent(fileToRename.filename), toPath: directoryCollectionViewController.directory.nsString.appendingPathComponent(newFileName)) {
                       
                        DispatchQueue.main.async {
                            directoryCollectionViewController.reload()
                        }
                    } else {
                        DispatchQueue.main.async {
                            let errorAlert = UIAlertController(title: Localizable.FileCollectionViewCell.errorRenaming, message: nil, preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .cancel, handler: nil))
                            directoryCollectionViewController.present(errorAlert, animated: true, completion: nil)
                        }
                    }
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            
            directoryCollectionViewController.present(renameAlert, animated: true, completion: nil)
            
        // Rename local file
        } else if let localDirectoryCollectionViewController = localDirectoryCollectionViewController {
            
            let fileToRename = localDirectoryCollectionViewController.files[localDirectoryCollectionViewController.collectionView!.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: Localizable.FileCollectionViewCell.renameFileTitle, message: Localizable.FileCollectionViewCell.rename(file: fileToRename.lastPathComponent), preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = Localizable.FileCollectionViewCell.newFileName
                textField.text = fileToRename.lastPathComponent
            })
            
            renameAlert.addAction(UIAlertAction(title: Localizable.FileCollectionViewCell.rename, style: .default, handler: { (_) in
                do {
                    try FileManager.default.moveItem(at: fileToRename, to: fileToRename.deletingLastPathComponent().appendingPathComponent(renameAlert.textFields![0].text!))
                    localDirectoryCollectionViewController.reload()
                } catch {
                    let alert = UIAlertController(title: Localizable.FileCollectionViewCell.errorRenaming, message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                    localDirectoryCollectionViewController.present(alert, animated: true, completion: nil)
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            
            localDirectoryCollectionViewController.present(renameAlert, animated: true, completion: nil)
        }
    }
    
    /// Move file represented by the cell.
    @objc func moveFile(_ sender: Any) {
        
        // Move remote file
        if let directoryCollectionViewController = directoryCollectionViewController {
            
            directoryCollectionViewController.checkForConnectionError(errorHandler: {
                directoryCollectionViewController.showError()
            })
            
            Pasteboard.local.filePath = directoryCollectionViewController.directory.nsString.appendingPathComponent(directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)!.row].filename)
            
            let dirVC = DirectoryCollectionViewController(connection: directoryCollectionViewController.connection, directory: directoryCollectionViewController.directory)
            dirVC.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereMoveFile
            dirVC.delegate = dirVC
            DirectoryCollectionViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            directoryCollectionViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.moveHere, style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
            
        // Move local file
        } else if let localDirectoryCollectionViewController = localDirectoryCollectionViewController {
            
            Pasteboard.local.localFilePath = localDirectoryCollectionViewController.directory.appendingPathComponent(localDirectoryCollectionViewController.files[localDirectoryCollectionViewController.collectionView!.indexPath(for: self)!.row].lastPathComponent).path
            
            let dirVC = LocalDirectoryCollectionViewController(directory: FileManager.default.documents)
            dirVC.navigationItem.prompt = Localizable.Browsers.selectDirectoryWhereMoveFile
            dirVC.delegate = dirVC
            
            LocalDirectoryCollectionViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            localDirectoryCollectionViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: Localizable.Browsers.moveHere, style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(barButtonSystemItem: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
    
    /// Open directory in new panel.
    @objc func openInNewPanel(_ sender: Any) {
        
        if let directoryCollectionViewController = directoryCollectionViewController {
            
            let filename = directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)!.row].filename
            let dir = directoryCollectionViewController.directory.nsString
            
            let dirToOpen: String
            
            if self.filename.text == ".." || self.filename.text == "../" {
                dirToOpen = dir.deletingLastPathComponent
            } else {
                dirToOpen = dir.appendingPathComponent(filename)
            }
            
            ContentViewController.shared.presentBrowser(inDirectory: dirToOpen, from: self)
        }
    }
    
    /// Show file info.
    @objc func showFileInfo(_ sender: Any) {
        guard let directoryCollectionViewController = directoryCollectionViewController else {
            return
        }
        
        guard directoryCollectionViewController.files != nil else {
            return
        }
        
        guard let i = directoryCollectionViewController.collectionView?.indexPath(for: self)?.row else {
            return
        }
        
        let fileInfoVC = FileInfoViewController.makeViewController()
        fileInfoVC.file = directoryCollectionViewController.files?[i]
        if i != directoryCollectionViewController.files!.count-1 {
            fileInfoVC.parentDirectory = directoryCollectionViewController.directory
        } else {
            fileInfoVC.parentDirectory = directoryCollectionViewController.directory.nsString.deletingLastPathComponent.nsString.deletingLastPathComponent
        }
        fileInfoVC.modalPresentationStyle = .popover
        fileInfoVC.popoverPresentationController?.sourceView = self
        fileInfoVC.popoverPresentationController?.sourceRect = bounds
        fileInfoVC.popoverPresentationController?.delegate = fileInfoVC
        
        if #available(iOS 13.0, *) {
            fileInfoVC.view.backgroundColor = .systemBackground
        }
        
        directoryCollectionViewController.present(fileInfoVC, animated: true)
    }
    
    private var controller: UIDocumentInteractionController!
    
    /// Share local file.
    @objc func shareFile(_ sender: Any) {
        if let localDirectoryCollectionViewController = localDirectoryCollectionViewController {
            controller = UIDocumentInteractionController(url: localDirectoryCollectionViewController.files[localDirectoryCollectionViewController.collectionView!.indexPath(for: self)!.row])
            controller.presentOptionsMenu(from: bounds, in: self, animated: true)
            print(localDirectoryCollectionViewController.files[localDirectoryCollectionViewController.collectionView!.indexPath(for: self)!.row])
        }
    }
    
    // MARK: - Context menu interaction delegate
    
    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        /*
         if #available(iOS 13.0, *) {
             return false
         }
         
         if let directoryCollectionViewController = directoryCollectionViewController {
             
             if directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)?.row ?? 0].isDirectory {
                 
                 return (action == #selector(showFileInfo(_:)) || action == #selector(deleteFile(_:)) || action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)) || action == #selector(openInNewPanel(_:)))
             } else {
                 return (action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(showFileInfo(_:)) || action == #selector(deleteFile(_:)) || action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)))
             }
         }
         
         return (action == #selector(shareFile(_:)) || action == #selector(deleteFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(renameFile(_:)))
         */
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) -> UIMenu? in
            
            let delete = UIAction(title: Localizable.UIMenuItem.delete, image: UIImage(systemName: "trash.fill"), attributes: [.destructive], handler: { (action) in
                self.deleteFile(action)
            })
            
            let share = UIAction(title: Localizable.UIMenuItem.move, image: UIImage(systemName: "square.and.arrow.up.fill"), handler: { (action) in
                self.shareFile(action)
            })
                        
            let move = UIAction(title: Localizable.UIMenuItem.move, image: UIImage(systemName: "folder.fill"), handler: { (action) in
                self.moveFile(action)
            })
            
            let copy = UIAction(title: Bundle(for: UIApplication.self).localizedString(forKey: "Copy", value: nil, table: nil), image: UIImage(systemName: "doc.on.doc.fill"), handler: { (action) in
                if let directoryCollectionViewController = self.directoryCollectionViewController, let indexPath = directoryCollectionViewController.collectionView!.indexPath(for: self) {
                    directoryCollectionViewController.collectionView(directoryCollectionViewController.collectionView, performAction: #selector(UIResponderStandardEditActions.copy(_:)), forItemAt: indexPath, withSender: action)
                } else if let directoryCollectionViewController = self.localDirectoryCollectionViewController, let indexPath = directoryCollectionViewController.collectionView!.indexPath(for: self) {
                    directoryCollectionViewController.collectionView(directoryCollectionViewController.collectionView, performAction: #selector(UIResponderStandardEditActions.copy(_:)), forItemAt: indexPath, withSender: action)
                }
            })
            
            let rename = UIAction(title: Localizable.UIMenuItem.rename, image: UIImage(systemName: "pencil"), handler: { (action) in
                self.renameFile(action)
            })
            
            let info = UIAction(title: Localizable.UIMenuItem.info, image: UIImage(systemName: "info.circle.fill"), handler: { (action) in
                self.showFileInfo(action)
            })
            
            let newPanel = UIAction(title: Localizable.UIMenuItem.openInNewPanel, image: UIImage(systemName: "uiwindow.split.2x1"), handler: { (action) in
                self.openInNewPanel(action)
            })
            
            let actions: [UIAction]
            
            if let directoryCollectionViewController = self.directoryCollectionViewController {
                if directoryCollectionViewController.files![directoryCollectionViewController.collectionView!.indexPath(for: self)?.row ?? 0].isDirectory {
                    
                    actions = [
                        move,
                        rename,
                        info,
                        newPanel,
                        delete
                    ]
                    
                } else {
                    
                    actions = [
                        copy,
                        move,
                        rename,
                        info,
                        delete
                    ]
                }
            } else {
                actions = [
                    copy,
                    move,
                    rename,
                    share,
                    delete
                ]
            }
                        
            return UIMenu(title: self.filename.text ?? "", children: actions)
        }
    }
}
