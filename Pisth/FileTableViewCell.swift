// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

class FileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var filename: UILabel!
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(renameFile(_:)))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func renameFile(_ sender: Any) {
        if let directoryTableViewController = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
            
            let fileToRename = directoryTableViewController.files![directoryTableViewController.tableView.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: "Write new file name", message: "Write new name for \(fileToRename.nsString.lastPathComponent).", preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
                textField.text = fileToRename.nsString.lastPathComponent
            })
            
            renameAlert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (_) in
                guard let newFileName = renameAlert.textFields?[0].text else { return }
                guard let session = ConnectionManager.shared.filesSession else { return }
                
                guard let response = try? session.channel.execute("mv '\(fileToRename)' '\(fileToRename.nsString.deletingLastPathComponent.nsString.appendingPathComponent(newFileName))'") else { return }
                
                if !response.replacingOccurrences(of: "\n", with: "").isEmpty {
                    let errorAlert = UIAlertController(title: nil, message: response, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    directoryTableViewController.present(errorAlert, animated: true, completion: nil)
                } else {
                    directoryTableViewController.reload()
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            directoryTableViewController.present(renameAlert, animated: true, completion: nil)
        }
    }
    
    @objc func moveFile(_ sender: Any) {
        if let directoryTableViewController = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
            Pasteboard.local.filePath = directoryTableViewController.files![directoryTableViewController.tableView.indexPath(for: self)!.row]
            
            let dirVC = DirectoryTableViewController(connection: directoryTableViewController.connection, directory: directoryTableViewController.directory)
            dirVC.navigationItem.prompt = "Select a directory where move file"
            dirVC.delegate = dirVC
            DirectoryTableViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            directoryTableViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
}
