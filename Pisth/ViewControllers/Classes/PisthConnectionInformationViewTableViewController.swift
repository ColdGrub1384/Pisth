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
class PisthConnectionInformationTableViewController: ConnectionInformationTableViewController, UIDocumentPickerDelegate {
    
    private let publicKeyPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .open)
    private let privateKeyPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .open)
    
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
        publicKeyPicker.allowsMultipleSelection = false
        publicKeyPicker.delegate = self
        present(publicKeyPicker, animated: true, completion: nil)
    }
    
    /// Import private key.
    @IBAction func importPrivateKey(_ sender: Any) {
        privateKeyPicker.allowsMultipleSelection = false
        privateKeyPicker.delegate = self
        present(privateKeyPicker, animated: true, completion: nil)
    }
    
    // MARK: - Connection information table view controller
    
    /// Setup views.
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
    
    // MARK: - Document picker delegate
    
    /// Import private or public key.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller === publicKeyPicker {
            publicKey = (try? String(contentsOf: urls[0]))
            importPublicKeyBtn.setTitle(urls[0].lastPathComponent, for: .normal)
        } else if controller === privateKeyPicker {
            privateKey = (try? String(contentsOf: urls[0]))
            importPrivateKeyBtn.setTitle(urls[0].lastPathComponent, for: .normal)
            importPrivateKeyBtn.tintColor = view.tintColor
            
            password?.placeholder = Localizable.ConnectionInformationViewController.passphrase
        }
    }
    
    /// Reset values.
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
}
