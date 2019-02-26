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
class PisthConnectionInformationTableViewController: ConnectionInformationTableViewController, Storyboard {
    
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
        let vc =  SSHKeyTableViewController.makeViewController()
        vc.keyType = .public
        vc.setPublicKeyHandler = { key in
            self.publicKey = key
            
            if key != nil {
                self.importPublicKeyBtn.setTitle(Localizable.ConnectionInformationViewController.changePublicKey, for: .normal)
            } else {
                self.importPublicKeyBtn.setTitle(Localizable.ConnectionInformationViewController.importPublicKey, for: .normal)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        present(navVC, animated: true, completion: {
            vc.textView.text = self.publicKey
        })
    }
    
    /// Import private key.
    @IBAction func importPrivateKey(_ sender: Any) {
        let vc =  SSHKeyTableViewController.makeViewController()
        vc.keyType = .private
        vc.setPrivateKeyHandler = { key in
            self.privateKey = key
            
            if key != nil {
                self.importPrivateKeyBtn.setTitle(Localizable.ConnectionInformationViewController.changePrivateKey, for: .normal)
            } else {
                self.importPrivateKeyBtn.setTitle(Localizable.ConnectionInformationViewController.importPrivateKey, for: .normal)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        present(navVC, animated: true, completion: {
            vc.textView.text = self.privateKey
        })
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
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "Connection Info", bundle: nil)
    }
}
