// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import BiometricAuthentication


/// Table view controller for displaying and changing settings.
class SettingsTableViewController: UITableViewController {
    
    /// Indexes of each settings
    enum Index: Int {
        case biometricAuth = 0
        case showHiddenFiles = 1
        case blinkCursor = 2
        case licenses = 4
    }
    
    
    /// MARK: - View controller
    
    /// `UIViewController`'s `viewDidLoad` function.
    ///
    /// Display current settings.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        initBiometricAuthenticationSetting()
        initShowHiddenFilesSetting()
        initBlinkCursorSetting()
    }
    
    
    // MARK: - Blink cursor
    
    /// Switch to toggle blinking cursor.
    @IBOutlet weak var blinkCursorSwitch: UISwitch!
    
    /// Toogle blinking cursor.
    ///
    /// - Parameters:
    ///     - sender: Sender switch.
    @IBAction func toggleBlinkCursor(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "blink")
        UserDefaults.standard.synchronize()
    }
    
    /// Display current blinking cursor setting
    func initBlinkCursorSetting() {
        blinkCursorSwitch.isOn = UserDefaults.standard.bool(forKey: "blink")
    }
    
    
    // MARK: - Show hidden files
    
    /// Switch to toggle showing hidden files.
    @IBOutlet weak var showHiddenFilesSwitch: UISwitch!
    
    /// Toogle showing hidden files.
    ///
    /// - Parameters:
    ///     - sender: Sender switch.
    @IBAction func toggleHiddenFiles(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "hidden")
        UserDefaults.standard.synchronize()
    }
    
    /// Display current blinking cursor setting
    func initShowHiddenFilesSetting() {
        showHiddenFilesSwitch.isOn = UserDefaults.standard.bool(forKey: "hidden")
    }
    
    
    // MARK: - Biometric authentication
    
    /// Switch to toggle biometric authentication.
    @IBOutlet weak var biometricAuthSwitch: UISwitch!
    
    /// Label for setting's title.
    @IBOutlet weak var biometricAuthLabel: UILabel!
    
    /// Toogle biometric authentication.
    ///
    /// - Parameters:
    ///     - sender: Sender switch.
    @IBAction func toggleBiometricAuth(_ sender: UISwitch) {
        
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
    
    /// Display current biometric authentication setting.
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
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// Open licenses or deselect selected row.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.row == Index.licenses.rawValue {
            
            // Open Licenses
            let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            navigationController?.pushViewController(webVC, animated: true)

        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
