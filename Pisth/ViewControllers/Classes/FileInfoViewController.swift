// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import MobileCoreServices

/// A View controller for displaying remote file info.
class FileInfoViewController: UIViewController, UIPopoverPresentationControllerDelegate, Xib {
    
    /// Close this view controller
    @objc func close() {
        (navigationController ?? self).dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Info
    
    /// File info.
    var file: NMSFTPFile!
    
    /// Parent directory of the file.
    var parentDirectory: String!
    
    // MARK: - UI Info
    
    /// The `UIImageView` showing file icon.
    @IBOutlet weak var iconView: UIImageView!
    
    /// The `UILabel` with the filename.
    @IBOutlet weak var filenameLabel: UILabel!
    
    /// The `UILabel` with the parent directory.
    @IBOutlet weak var parentDirectoryLabel: UILabel!
    
    /// The `UILabel` with the file type.
    @IBOutlet weak var fileTypeLabel: UILabel!
    
    /// The `UILabel` with the permissions.
    @IBOutlet weak var permissionsLabel: UILabel!
    
    /// The `UILabel` with the file size.
    @IBOutlet weak var sizeLabel: UILabel!
    
    /// The `UILabel` with the modification date.
    @IBOutlet weak var modificationLabel: UILabel!
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizable.FileInfoViewController.title
        
        view.isHidden = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.isHidden = false
        
        let pathExtension = file.filename.nsString.pathExtension
        
        if file.isDirectory {
            iconView.image = #imageLiteral(resourceName: "File icons/folder")
        } else {
            iconView.image = UIImage.icon(forPathExtension: pathExtension)
        }
        
        filenameLabel.text = file.filename
        parentDirectoryLabel.text = parentDirectory.nsString.lastPathComponent
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.includesActualByteCount = true
        sizeLabel.text = byteCountFormatter.string(fromByteCount: file.fileSize?.int64Value ?? 0)
        if file.permissions?.hasPrefix("l") == true {
            fileTypeLabel.text = Localizable.FileInfoViewController.symLink
        } else if file.isDirectory {
            fileTypeLabel.text = Localizable.FileInfoViewController.directory
            sizeLabel.text = "--"
        } else if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(), let description = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
            if description.isEmpty {
                fileTypeLabel.text = Localizable.FileInfoViewController.file(withPathExtension: pathExtension.uppercased())
            } else {
                fileTypeLabel.text = description
            }
        } else {
            fileTypeLabel.text = Localizable.FileInfoViewController.file(withPathExtension: pathExtension.uppercased())
        }
        permissionsLabel.text = file.permissions
        modificationLabel.text = DateFormatter().string(from: file.modificationDate ?? Date())
        if modificationLabel.text?.isEmpty == true /* `==` because `text` is optional */ {
            view.viewWithTag(1)?.isHidden = true
        }
    }
    
    // MARK: - Popover presentation controller delegate
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        
        return UINavigationController(rootViewController: self)
    }
    
    // MARK: - Xib
    
    static var nibName: String {
        return "File Info"
    }
}
