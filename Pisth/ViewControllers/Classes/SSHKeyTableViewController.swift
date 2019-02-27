// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import MobileCoreServices

/// A View controller for typing an SSH key.
class SSHKeyTableViewController: UITableViewController, UIDocumentPickerDelegate, Storyboard {
    
    /// Text view containing key.
    @IBOutlet weak var textView: UITextView!
    
    /// Imports file.
    @IBAction func importFile(_ sender: Any) {
        let picker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
        picker.delegate = self
        if #available(iOS 11.0, *) {
            picker.allowsMultipleSelection = false
        }
        present(picker, animated: true, completion: nil)
    }

    /// Saves key.
    @IBAction func save(_ sender: Any) {
        if keyType == .public {
            if !textView.text.isEmpty {
                setPublicKeyHandler?(textView.text)
            } else {
                setPublicKeyHandler?(nil)
            }
        } else if keyType == .private {
            if !textView.text.isEmpty {
                setPrivateKeyHandler?(textView.text)
            } else {
                setPrivateKeyHandler?(nil)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    /// Dismisses.
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /// Code called when a public key is set. Passed string is the key.
    var setPublicKeyHandler: ((String?) -> Void)?
    
    /// Code called when a private key is set. Passed string is the key.
    var setPrivateKeyHandler: ((String?) -> Void)?
    
    /// Type of SSH Key.
    enum SSHKeyType {
        
        /// Private key.
        case `private`
        
        /// Public key.
        case `public`
    }
    
    /// Key type.
    var keyType: SSHKeyType? {
        didSet {
            if keyType == .public {
                title = Localizable.ConnectionInformationViewController.changePublicKey
            } else if keyType == .private {
                title = Localizable.ConnectionInformationViewController.changePrivateKey
            }
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = ""
    }
    
    // MARK: - Document picker delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            textView.text = try String(contentsOf: url)
        } catch {
            let alert = UIAlertController(title: Localizable.EditTextViewController.errorOpeningFile, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "SSHKey", bundle: nil)
    }
}
