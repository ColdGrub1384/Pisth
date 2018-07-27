// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Highlightr
import ActionSheetPicker_3_0
import Firebase
import Pisth_Shared

/// View controller used to edit text files.
class EditTextViewController: UIViewController, UITextViewDelegate {
    
    /// Dismiss this View controller.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /// View created from IB managing size of `textView`.
    @IBOutlet weak var placeholderView: UIView!
    
    /// Text view containing opened text.
    var textView: UITextView!
    
    /// File opened.
    var file: URL!
    
    /// Text storage managing syntax highlighting.
    var textStorage = CodeAttributedString()
    
    /// Highlightr managing syntax highlighting.
    var highlightr: Highlightr!
    
    /// Returns recommended languages for current file.
    var recommendedLanguages: [String] {
        let languages = NSDictionary(contentsOf: Bundle.main.bundleURL.appendingPathComponent("langs.plist"))! as! [String:[String]] // List of languages associated by file extensions
        
        return languages[file.pathExtension.lowercased()] ?? []
    }
    
    /// Langauge used to highlight code.
    private var language_: String?
    
    /// Langauge used to highlight code but with correct format.
    var language: String? {
        get {
            return language_
        }
        
        set {
            textStorage.language = newValue
            language_ = newValue
            
            if newValue == nil {
                textStorage.language = nil
           
                setTextColor()
                
                textStorage.setAttributes([.font:highlightr.theme.codeFont, .foregroundColor:textView.textColor ?? .white], range: NSRange(location: 0, length: textStorage.length))
            }
        }
    }
    
    /// Setup textView.
    func setupTextView() {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: view.bounds.width, height: 50))
        
        let dismissKeyboard = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard(_:)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let tab = UIBarButtonItem(title: "↹", style: .plain, target: self, action: #selector(insertTab))
        
        let items = [tab, flexSpace, dismissKeyboard] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: view.bounds.size)
        layoutManager.addTextContainer(textContainer)
                
        textView = UITextView(frame: placeholderView.bounds, textContainer: textContainer)
        textView.isScrollEnabled = false
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textStorage.highlightr.setTheme(to: UserDefaults.standard.string(forKey: "editorTheme")!)
        textView.backgroundColor = textStorage.highlightr.theme.themeBackgroundColor
        textView.autocorrectionType = UITextAutocorrectionType.no
        textView.autocapitalizationType = UITextAutocapitalizationType.none
        textView.inputAccessoryView = toolbar
        textView.font = textStorage.highlightr.theme.codeFont
        textView.smartQuotesType = .no
        setTextColor()
        placeholderView.addSubview(textView)
    }
    
    /// Share current file.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func share(_ sender: UIBarButtonItem) {
        let document = UIDocumentInteractionController(url: file)
        document.presentOpenInMenu(from: sender, animated: true)
    }
    
    
    // MARK: - View controller
    
    /// Call `setupTextView` function and disable large title.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [AnalyticsParameterItemID : "id-Editor", AnalyticsParameterItemName : "Code Editor"])
        
        setupTextView()
        
        navigationItem.largeTitleDisplayMode = .never
    }

    /// Open `file` and highlight it.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        textView.setContentOffset(CGPoint.zero, animated: false)
        
        if highlightr != nil {
            return
        }
        
        highlightr = textStorage.highlightr
        
        title = file.lastPathComponent
        
        textView.delegate = self
        
        let languages = NSDictionary(contentsOf: Bundle.main.bundleURL.appendingPathComponent("langs.plist"))! as! [String:[String]] // List of languages associated by file extensions
        
        // Open file
        do {
            textView.text = try String(contentsOfFile: file.path)
            textView.isScrollEnabled = true
        } catch let error {
            let errorAlert = UIAlertController(title: Localizable.EditTextViewController.errorOpeningFile, message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        // Resize textView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Syntax coloring
        
        if let languagesForFile = languages[file.pathExtension.lowercased()] {
            if languagesForFile.count > 0 {
                language = languagesForFile[0]
            }
        }
    }
    
    /// Save file if is needed.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
                
        func close() {
            if ConnectionManager.shared.saveFile != nil {
                ConnectionManager.shared.saveFile = nil
            }
            
        }
        
        // Ask for save the file
        let alert = UIAlertController(title: Localizable.EditTextViewController.saveChangesTitle, message:Localizable.EditTextViewController.saveChangesMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizable.EditTextViewController.dontSave, style: .destructive, handler: { (_) in
            close()
        }))
        alert.addAction(UIAlertAction(title: Localizable.EditTextViewController.save, style: .default, handler: { (_) in
            AppDelegate.shared.navigationController.visibleViewController?.present(navigationController ?? self, animated: true, completion: {
                self.save(true)
                if ConnectionManager.shared.saveFile?.localFile == self.file.path {
                    try? FileManager.default.removeItem(at: self.file)
                }
            })
        }))
        
        do {
            // Check if file was modified
            let fileContent = try String.init(contentsOf: file)
            if textView.text != fileContent {
               AppDelegate.shared.navigationController.visibleViewController?.present(alert, animated: true, completion: nil)
            } else {
                if ConnectionManager.shared.saveFile?.localFile == file.path {
                    try? FileManager.default.removeItem(at: file)
                }
                close()
            }
        } catch _ {
            close()
        }
    }
    
    // MARK: - Actions
    
    /// Save file locally and upload it if is necessary.
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func save(_ sender: Any) {
        if let data = textView.text.data(using: .utf8) {
            do {
                try data.write(to: file)
                
                // Upload file
                if let saveFile = ConnectionManager.shared.saveFile {
                    
                    if saveFile.localFile == file.path {
                        let activityVC = ActivityViewController(message: Localizable.uploading)
                        self.present(activityVC, animated: true, completion: {
                            ConnectionManager.shared.filesSession?.sftp.writeContents(data, toFileAtPath: saveFile.remoteFile)
                            activityVC.dismiss(animated: true, completion: {
                                if let close = sender as? Bool {
                                    if close {
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                }
                            })
                        })
                    } else {
                        if let close = sender as? Bool {
                            if close {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                    
                } else {
                    if let close = sender as? Bool {
                        if close {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
                
            } catch let error {
                let errorAlert = UIAlertController(title: Localizable.errorSavingFile, message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: Localizable.ok, style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }

    /// Insert tab into textView.
    @objc func insertTab() {
        textView.replace(textView.selectedTextRange!, withText: "\t")
    }
    
    /// Change highlighter language.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func changeLanguage(_ sender: Any) {
        let wasFirstResponder = textView.isFirstResponder
        
        textView.resignFirstResponder()
        
        let languages = [Localizable.EditTextViewController.none]+highlightr.supportedLanguages()
        let initialSelection = languages.index(of: language ?? Localizable.EditTextViewController.none) ?? 0
        
        let picker = ActionSheetStringPicker(title: Localizable.EditTextViewController.selectALanguage, rows: languages, initialSelection: initialSelection, doneBlock: { (picker, row, language) in
            
            if let language = language as? String {
                if language != "None" {
                    self.language = language
                } else {
                    self.language = nil
                }
            }
            
            if wasFirstResponder {
                self.textView.becomeFirstResponder()
            }
            
        }, cancel: { (picker) in
            if wasFirstResponder {
                self.textView.becomeFirstResponder()
            }
        }, origin: sender)
        
        picker?.addCustomButton(withTitle: Localizable.EditTextViewController.default, value: initialSelection)
        
        picker?.show()
    }
    
    /// Change editor's theme.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func changeTheme(_ sender: Any) {
        
        let wasFirstResponder = textView.isFirstResponder
        
        textView.resignFirstResponder()
        
        ActionSheetStringPicker.show(withTitle: Localizable.EditTextViewController.selectATheme, rows: textStorage.highlightr.availableThemes(), initialSelection: textStorage.highlightr.availableThemes().index(of: UserDefaults.standard.string(forKey: "editorTheme")!) ?? 0, doneBlock: { (_, _, theme) in
            
            if let theme = theme as? String {
                self.textStorage.highlightr.setTheme(to: theme)
                self.textView.backgroundColor = self.textStorage.highlightr.theme.themeBackgroundColor
                UserDefaults.standard.set(theme, forKey: "editorTheme")
                UserDefaults.standard.synchronize()
            }
            
            self.setTextColor()
            
            if wasFirstResponder {
                self.textView.becomeFirstResponder()
            }
            
        }, cancel: { (_) in
            
            if wasFirstResponder {
                self.textView.becomeFirstResponder()
            }
            
        }, origin: sender)
    }
    
    /// Set text color for theme
    func setTextColor() {
        let attrs = textStorage.highlightr.highlight("hello", as: "swift", fastRender: true)
        if let color = attrs?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            textView.textColor = color
        }
    }
    
    // MARK: Keyboard
    
    /// Dismiss keyboard.
    ///
    /// - Parameters:
    ///     - sender: Sender Bar button item.
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
    }
    
    /// Resize `textView` when will show keyboard.
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    /// Resize `textView` when will hide keyboard.
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}
