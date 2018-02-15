// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import BiometricAuthentication


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
        
        /// Set terminal theme.
        static let terminalTheme = IndexPath(row: 0, section: 3)
        
        /// Promote Pisth Viewer.
        static let pisthViewer = IndexPath(row: 0, section: 4)
        
        /// Show licenses.
        static let licenses = IndexPath(row: 1, section: 4)
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
        initTextSizeSetting()
        initThemesIAPSetting()
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
    
    
    // MARK: - Unlock themes
    
    /// View blocking access to themes if they are not purchased.
    @IBOutlet weak var themesStore: UIVisualEffectView!
    
    /// Button used to buy themes iap.
    @IBOutlet weak var buyThemesButton: UIButton!
    
    /// Button used to restore themes iap.
    @IBOutlet weak var restoreThemesButton: UIButton!
    
    /// Buy themes iap.
    ///
    /// - Parameters:
    ///     - sender: Sender button.
    @IBAction func buyThemes(_ sender: UIButton) {
        guard let vc = Bundle.main.loadNibNamed("ThemesStoreViewController", owner: nil, options: nil)?[0] as? UIViewController else {
            return
        }
        
        vc.modalPresentationStyle = .overCurrentContext
        
        present(vc, animated: true, completion: nil)
    }
    
    /// Restore themes iap.
    ///
    /// - Parameters:
    ///     - sender: Sender button.
    @IBAction func restoreThemes(_ sender: UIButton) {
        Product.restorePurchases { (results) in
            for purchase in results.restoredPurchases {
                if purchase.productId == ProductsID.themes.rawValue {
                    UserDefaults.standard.set(true, forKey: "terminalThemesPurchased")
                    UserDefaults.standard.synchronize()
                    self.themesStore.isHidden = true
                }
            }
        }
    }
    
    func initThemesIAPSetting() {
        buyThemesButton.layer.cornerRadius = 16
        restoreThemesButton.layer.cornerRadius = 16
        buyThemesButton.setTitle(Product.terminalThemes.price ?? "Buy", for: .normal)
        themesStore.isHidden = UserDefaults.standard.bool(forKey: "terminalThemesPurchased")
    }
    
    
    // MARK: Table view delegate
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// Open licenses or deselect selected row.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath == IndexPaths.licenses {
            
            // Open Licenses
            let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
            webVC.file = Bundle.main.url(forResource: "Licenses", withExtension: "html")
            navigationController?.pushViewController(webVC, animated: true)

        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    // MARK: - Collection view data source
    
    /// `UICollectionViewDataSource`'s `collectionView(_:, numberOfItemsInSection:)` function.
    ///
    /// - Returns: `9`.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    /// `UICollectionViewDataSource`'s `collectionView(_:, cellForItemAt:)` function.
    ///
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
    
    /// `UICollectionViewDelegate`'s `collectionView(_:, didSelectItemAt:)` function.
    ///
    /// Set theme for selected item.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else {
            return
        }
        
        guard TerminalTheme.themes.keys.contains(title.text!) else {
            return
        }
        
        UserDefaults.standard.set(title.text, forKey: "terminalTheme")
        UserDefaults.standard.synchronize()
        
        collectionView.reloadData()
    }
}
