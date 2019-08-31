// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import BiometricAuthentication
import Pisth_Shared
import SafariServices

/// Table view controller for displaying and changing settings.
class SettingsTableViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, Storyboard {
    
    /// Index of each setting.
    class IndexPaths {
        private init() {}
        
        /// Toggle biometric auth.
        static let biometricAuth = IndexPath(row: 0, section: 3)
        
        /// Show hidden files.
        static let showHiddenFiles = IndexPath(row: 0, section: 1)
        
        /// Show snippets.
        static let showSnippets = IndexPath(row: 0, section: 1)
        
        /// Show folders at top.
        static let showFoldersAtTop = IndexPath(row: 0, section: 1)
        
        /// Toggle blinking cursor.
        static let blinkCursor = IndexPath(row: 0, section: 2)
        
        /// Set text size.
        static let textSize = IndexPath(row: 1, section: 2)
        
        /// Manage plugins.
        static let plugins = IndexPath(row: 2, section: 2)
        
        /// Set terminal theme.
        static let terminalTheme = IndexPath(row: 0, section: 3)
                
        /// Show source code.
        static let sourceCode = IndexPath(row: 0, section: 4)
        
        /// Show Twitter account.
        static let licenses = IndexPath(row: 1, section: 5)
        
        /// Show licenses.
        static let twitter = IndexPath(row: 0, section: 5)
    }
    
    /// Close this view controller.
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    /// MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        initBiometricAuthenticationSetting()
        initShowHiddenFilesSetting()
        initBlinkCursorSetting()
        initTextSizeSetting()
        initShowFoldersAtTop()
        initShowSnippets()
    }
    
    // MARK: - Blink cursor
    
    /// Switch to toggle blinking cursor.
    @IBOutlet weak var blinkCursorSwitch: UISwitch!
    
    /// Toogle blinking cursor.
    @IBAction func toggleBlinkCursor(_ sender: UISwitch) {
        UserKeys.blink.boolValue = sender.isOn
    }
    
    /// Display current blinking cursor setting
    func initBlinkCursorSetting() {
        blinkCursorSwitch.isOn = UserKeys.blink.boolValue
    }
    
    // MARK: - Show hidden files
    
    /// Switch to toggle showing hidden files.
    @IBOutlet weak var showHiddenFilesSwitch: UISwitch!
    
    /// Toogle showing hidden files.
    @IBAction func toggleHiddenFiles(_ sender: UISwitch) {
        UserKeys.shouldHiddenFilesBeShown.boolValue = sender.isOn
    }
    
    /// Display current blinking cursor setting.
    func initShowHiddenFilesSetting() {
        showHiddenFilesSwitch.isOn = UserKeys.shouldHiddenFilesBeShown.boolValue
    }
    
    // MARK: - Show snippets
    
    /// Displays current setting for hidding snippets.
    func initShowSnippets() {
        showSnippetsSwitch.isOn = !UserKeys.shouldHideSnippets.boolValue
    }
    
    /// Switch to toggle snippets panel.
    @IBOutlet weak var showSnippetsSwitch: UISwitch!
    
    /// Toggles snippets panel.
    @IBAction func toggleSnippets(_ sender: UISwitch) {
        UserKeys.shouldHideSnippets.boolValue = !sender.isOn
    }
    
    // MARK: - Show folders at top
    
    /// Displays current setting for showing folders at top.
    func initShowFoldersAtTop() {
        showFoldersAtTopSwitch.isOn = UserKeys.shouldShowFoldersAtTop.boolValue
    }
    
    /// Switch to toggle showing folders at top.
    @IBOutlet weak var showFoldersAtTopSwitch: UISwitch!
    
    /// Toggles showing folers at top.
    @IBAction func toggleFoldersAtTop(_ sender: UISwitch) {
        UserKeys.shouldShowFoldersAtTop.boolValue = sender.isOn
    }
    
    // MARK: - Biometric authentication
    
    /// Switch to toggle biometric authentication.
    @IBOutlet weak var biometricAuthSwitch: UISwitch!
    
    /// Label for setting's title.
    @IBOutlet weak var biometricAuthLabel: UILabel!
    
    /// Toogle biometric authentication.
    @IBAction func toggleBiometricAuth(_ sender: UISwitch) {
        
        guard BioMetricAuthenticator.canAuthenticate() else { return }
        
        if !UserKeys.isBiometricAuthenticationEnabled.boolValue {
            UserKeys.isBiometricAuthenticationEnabled.boolValue = true
        } else { // If biometric auth is enabled, authenticate before setting
            sender.isOn = true
            
            BioMetricAuthenticator.authenticateWithPasscode(reason: Localizable.Settings.authenticateToTurnOffAuthentication, success: {
                UserKeys.isBiometricAuthenticationEnabled.boolValue = false
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
        biometricAuthSwitch.isOn = UserKeys.isBiometricAuthenticationEnabled.boolValue
        
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
    @IBAction func setTextSize(_ sender: UIButton) {
        
        UserKeys.terminalTextSize.value = sender.titleLabel?.font.pointSize
        
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
            
            if Int(size) == UserKeys.terminalTextSize.integerValue {
                
                button?.isEnabled = false
                
            }
        }
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath == IndexPaths.licenses {
            
            // Open Licenses
            let safari = SFSafariViewController(url: URL(string: "https://pisth.github.io/Licenses")!)
            present(safari, animated: true)

        } else if indexPath == IndexPaths.plugins {
            
            // Manage plugins
            let pluginsVC = PluginsLocalDirectoryCollectionViewController()
            navigationController?.pushViewController(pluginsVC, animated: true)
            
        } else if indexPath == IndexPaths.sourceCode {
                
            // View the source code
            UIApplication.shared.open(URL(string: "https://github.com/ColdGrub1384/Pisth")!, options: [:], completionHandler: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if indexPath == IndexPaths.twitter {
            
            // Show Twitter account
            UIApplication.shared.open(URL(string:"https://twitter.com/develobile")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else {
            return cell
        }
        
        if title.text == UserKeys.terminalTheme.stringValue {
            cell.viewWithTag(2)?.isHidden = false
        } else {
            cell.viewWithTag(2)?.isHidden = true
        }
        
        return cell
    }
    
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else {
            return
        }
        
        UserKeys.terminalTheme.stringValue = title.text
        
        NotificationCenter.default.post(name: .init("TerminalThemeDidChange"), object: TerminalTheme.themes[title.text!])
        
        collectionView.reloadData()
    }
    
    // MARK: - Storyboard
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(name: "Settings", bundle: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
