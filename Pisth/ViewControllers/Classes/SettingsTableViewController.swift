// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import BiometricAuthentication
import Pisth_Shared

/// Table view controller for displaying and changing settings.
class SettingsTableViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /// Index of each setting.
    class IndexPaths {
        private init() {}
        
        /// Toggle biometric auth.
        static let biometricAuth = IndexPath(row: 0, section: 3)
        
        /// Show hidden files.
        static let showHiddenFiles = IndexPath(row: 0, section: 1)
        
        /// Toggle blinking cursor.
        static let blinkCursor = IndexPath(row: 0, section: 2)
        
        /// Set text size.
        static let textSize = IndexPath(row: 1, section: 2)
        
        /// Manage plugins.
        static let plugins = IndexPath(row: 2, section: 2)
        
        /// Set terminal theme.
        static let terminalTheme = IndexPath(row: 0, section: 3)
        
        /// Send beta testing request.
        static let beta = IndexPath(row: 0, section: 4)
        
        /// Show source code.
        static let sourceCode = IndexPath(row: 1, section: 4)
        
        /// Promote Pisth Viewer.
        static let pisthViewer = IndexPath(row: 0, section: 5)
        
        /// Show Twitter account.
        static let licenses = IndexPath(row: 2, section: 5)
        
        /// Show licenses.
        static let twitter = IndexPath(row: 1, section: 5)
    }
    
    /// Close this view controller.
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    /// MARK: - View controller
    
    /// Display current settings.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        initBiometricAuthenticationSetting()
        initShowHiddenFilesSetting()
        initBlinkCursorSetting()
        initTextSizeSetting()
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
    
    /// Display current blinking cursor setting.
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
            
            BioMetricAuthenticator.authenticateWithPasscode(reason: Localizable.Settings.authenticateToTurnOffAuthentication, success: {
                UserDefaults.standard.set(false, forKey: "biometricAuth")
                UserDefaults.standard.synchronize()
                sender.isOn = false
            }, failure: { (error) in
                
                if error != .fallback && error != .canceledBySystem && error != .canceledByUser {
                    let failureAlert = UIAlertController(title: Localizable.Settings.cannotTurnOffAuthentication, message: error.message(), preferredStyle: .alert)
                    failureAlert.addAction(UIAlertAction(title: Localizable.cancel, style: .default, handler: nil))
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
                biometricAuthLabel.text = Localizable.Settings.useFaceID
            } else { // If is Touch ID:
                biometricAuthLabel.text = Localizable.Settings.useTouchID
            }
        }
    }
    
    
    // MARK: - Text size
    
    /// Button to set the text size to 18px.
    @IBOutlet weak var px18: UIButton!
    
    /// Button to set the text size to 17px.
    @IBOutlet weak var px17: UIButton!
    
    /// Button to set the text size to 16px.
    @IBOutlet weak var px16: UIButton!
    
    /// Button to set the text size to 15px.
    @IBOutlet weak var px15: UIButton!
    
    /// Button to set the text size to 14px.
    @IBOutlet weak var px14: UIButton!
    
    /// Button to set the text size to 13px.
    @IBOutlet weak var px13: UIButton!
    
    /// Button to set the text size to 12px.
    @IBOutlet weak var px12: UIButton!
    
    /// Set text size as the sender's button text size.
    ///
    /// - Parameters:
    ///     - sender: Sender button.
    @IBAction func setTextSize(_ sender: UIButton) {
        
        UserDefaults.standard.set(sender.titleLabel?.font.pointSize, forKey: "terminalTextSize")
        UserDefaults.standard.synchronize()
        
        let buttons = [px18, px17, px16, px15, px14, px13, px12]
        
        for button in buttons {
            button?.isEnabled = true
        }
        
        sender.isEnabled = false
    }
    
    /// Display current text size setting.
    func initTextSizeSetting() {
        let buttons = [px18, px17, px16, px15, px14, px13, px12]
        
        for button in buttons {
            
            guard let size = button?.titleLabel?.font.pointSize else {
                return
            }
            
            if Int(size) == UserDefaults.standard.integer(forKey: "terminalTextSize") {
                
                button?.isEnabled = false
                
            }
        }
    }
    
    // MARK: Table view delegate
    
    /// Open licenses or deselect selected row.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath == IndexPaths.licenses {
            
            // Open Licenses
            let webVC = UIViewController.webViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            webVC.navigationItem.leftBarButtonItem = nil
            navigationController?.pushViewController(webVC, animated: true)

        } else if indexPath == IndexPaths.plugins {
            
            // Manage plugins
            let pluginsVC = PluginsLocalDirectoryCollectionViewController()
            navigationController?.pushViewController(pluginsVC, animated: true)
            
        } else if indexPath == IndexPaths.beta {
            
            // Send beta test request
            present(UIViewController.beta, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if indexPath == IndexPaths.sourceCode {
                
            // View the source code
            present(UIViewController.contribute, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if indexPath == IndexPaths.twitter {
            
            // Show Twitter account
            UIApplication.shared.open(URL(string:"https://twitter.com/pisthapp")!, options: [:], completionHandler: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    // MARK: - Collection view data source
    
    /// - Returns: `12`.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    /// - Returns: the cell corresponding to the index path.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else {
            return cell
        }
        
        if title.text == UserDefaults.standard.string(forKey: "terminalTheme") {
            cell.viewWithTag(2)?.isHidden = false
        } else {
            cell.viewWithTag(2)?.isHidden = true
        }
        
        return cell
    }
    
    
    // MARK: - Collection view delegate
    
    /// Set theme for selected item.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else {
            return
        }
        
        guard let theme = TerminalTheme.themes[title.text!] else {
            return
        }
        
        UserDefaults.standard.set(title.text, forKey: "terminalTheme")
        UserDefaults.standard.synchronize()
        
        let termVC = (AppDelegate.shared.navigationController.visibleViewController as? TerminalViewController) ?? ContentViewController.shared?.terminalPanel?.contentViewController as? TerminalViewController
        termVC?.keyboardAppearance = theme.keyboardAppearance
        termVC?.toolbar.barStyle = theme.toolbarStyle
        (termVC?.panelNavigationController ?? termVC?.navigationController)?.navigationBar.barStyle = theme.toolbarStyle
        
        collectionView.reloadData()
    }
}
