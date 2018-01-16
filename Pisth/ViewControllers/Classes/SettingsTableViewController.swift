// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import BiometricAuthentication

class SettingsTableViewController: UITableViewController {
    
    enum Index: Int {
        case biometricAuth = 0
        case licenses = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        initBiometricAuthenticationSetting()
    }
    
    // MARK: - Biometric authentication
    
    @IBOutlet weak var biometricAuthSwitch: UISwitch!
    @IBOutlet weak var biometricAuthLabel: UILabel!
    
    @IBAction func toggleBiometricAuth(_ sender: UISwitch) { // Turn on or off Touch ID
        
        guard BioMetricAuthenticator.canAuthenticate() else { return }
        
        if !UserDefaults.standard.bool(forKey: "biometricAuth") {
            UserDefaults.standard.set(true, forKey: "biometricAuth")
            UserDefaults.standard.synchronize()
        } else { // If biometric auth is enabled, authenticate before setting
            sender.isOn = true
            
            BioMetricAuthenticator.authenticateWithPasscode(reason: "Authenticate to turn off authentication", success: {
                UserDefaults.standard.set(false, forKey: "biometricAuth")
                UserDefaults.standard.synchronize()
                sender.isOn = false
            }, failure: { (error) in
                
                if error != .fallback && error != .canceledBySystem && error != .canceledByUser {
                    let failureAlert = UIAlertController(title: "Cannot turn off authentication", message: error.message(), preferredStyle: .alert)
                    failureAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(failureAlert, animated: true, completion: nil)
                }
                
            })
        }
    }
    
    func initBiometricAuthenticationSetting() {
        biometricAuthSwitch.isOn = UserDefaults.standard.bool(forKey: "biometricAuth")
        
        if !BioMetricAuthenticator.canAuthenticate() { // Only enable this setting if Biometric authentication is enabled
            biometricAuthSwitch.isEnabled = false
            biometricAuthSwitch.isOn = false
            biometricAuthLabel.isEnabled = false
        } else {
            if BioMetricAuthenticator.shared.faceIDAvailable() { // If is Face ID:
                biometricAuthLabel.text = "Use Face ID"
            } else { // If is Touch ID:
                biometricAuthLabel.text = "Use Touch ID"
            }
        }
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case Index.licenses.rawValue:
            
            // Open Licenses
            let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            navigationController?.pushViewController(webVC, animated: true)
            
        case Index.biometricAuth.rawValue:
            
            tableView.deselectRow(at: indexPath, animated: true)
            
        default:
            break
        }
    }
}
