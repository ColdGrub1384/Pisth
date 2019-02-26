// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared
import MobileCoreServices

/// `ConnectionInformationTableViewController` that can import keys pair.
class PisthConnectionInformationTableViewController: ConnectionInformationTableViewController, UIDocumentPickerDelegate, Storyboard {
    
    private let publicKeyPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
    private let privateKeyPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
    
    override var isUsernameRequired: Bool {
        return false
    }
    
    /// Button for importing public key. After importing one, its title is the name of the file.
    @IBOutlet weak var importPublicKeyBtn: UIButton!
    
    /// Button for importing private key. After importing one, its title is the name of the file.
    @IBOutlet weak var importPrivateKeyBtn: UIButton!
    
    /// Save connection with keys pair.
    override func save(_ sender: Any) {
        if (privateKey == nil && publicKey == nil) || (publicKey != nil && privateKey != nil) || (privateKey != nil) {
            super.save(sender)
        } else {
            importPrivateKeyBtn.tintColor = .red
        }
    }
    
    /// Import public key.
    @IBAction func importPublicKey(_ sender: Any) {
        if #available(iOS 11.0, *) {
            publicKeyPicker.allowsMultipleSelection = false
        }
        publicKeyPicker.delegate = self
        present(publicKeyPicker, animated: true, completion: nil)
    }
    
    /// Import private key.
    @IBAction func importPrivateKey(_ sender: Any) {
        if #available(iOS 11.0, *) {
            privateKeyPicker.allowsMultipleSelection = false
        }
        privateKeyPicker.delegate = self
        present(privateKeyPicker, animated: true, completion: nil)
    }
    
    // MARK: - Connection information table view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if publicKey != nil {
            importPublicKeyBtn.setTitle(Localizable.ConnectionInformationViewController.changePublicKey, for: .normal)
        }
        
        if privateKey != nil {
            importPrivateKeyBtn.setTitle(Localizable.ConnectionInformationViewController.changePrivateKey, for: .normal)
            password?.placeholder = Localizable.ConnectionInformationViewController.passphrase
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isShell {
            useSFTP?.isOn = false
            navigationController?.navigationBar.barStyle = .black
            if #available(iOS 11.0, *) {
                tableView.backgroundColor = shellBackgroundColor
            }
            for cell in tableView.visibleCells {
                if #available(iOS 11.0, *) {
                    cell.backgroundColor = shellBackgroundColor
                }
                for view in cell.contentView.subviews {
                    if let label = view as? UILabel {
                        label.textColor = .white
                    } else if let textField = view as? UITextField {
                        textField.textColor = .white
                    }
                }
            }
            tableView.tableFooterView?.backgroundColor = tableView.backgroundColor
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isShell && indexPath.row == 5 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    // MARK: - Document picker delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller === publicKeyPicker {
            publicKey = (try? String(contentsOf: url))
            importPublicKeyBtn.setTitle(url.lastPathComponent, for: .normal)
        } else if controller === privateKeyPicker {
            privateKey = (try? String(contentsOf: url))
            importPrivateKeyBtn.setTitle(url.lastPathComponent, for: .normal)
            importPrivateKeyBtn.tintColor = view.tintColor
            
            password?.placeholder = Localizable.ConnectionInformationViewController.passphrase
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if controller === publicKeyPicker {
            publicKey = nil
            importPublicKeyBtn.setTitle(Localizable.ConnectionInformationViewController.importPublicKey, for: .normal)
            importPrivateKeyBtn.tintColor = view.tintColor
        } else if controller === privateKeyPicker {
            password?.placeholder = ""
            privateKey = nil
            importPrivateKeyBtn.setTitle(Localizable.ConnectionInformationViewController.importPrivateKey, for: .normal)
        }
    }
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "Connection Info", bundle: nil)
    }
}
