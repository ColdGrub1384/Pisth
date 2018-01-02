//
//  FileTableViewCell.swift
//  Pisth
//
//  Created by Adrian on 26.12.17.
//

import UIKit

class FileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var filename: UILabel!
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
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
