// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Highlightr
import ActionSheetPicker_3_0

/// View controller used to edit text files.
class EditTextViewController: UIViewController, UITextViewDelegate {
    
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
    
    /// Langauge used to highlight code.
    private var language_: String?
    
    /// Langauge used to highlight code but with correct format.
    var language: String? {
        get {
            
            if language_ == nil {
                return nil
            }
            
            if language_ == "html" {
                return "htmlbars"
            }
            
            let supportedLanguages = highlightr!.supportedLanguages()
            if supportedLanguages.contains(language_!) {
                return language_?.replacingOccurrences(of: "-", with: "")
            } else {
                return nil
            }
        }
        
        set {
            language_ = newValue
        }
    }
    
    /// Setup textView.
    func setupTextView() {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: view.bounds.width, height: 50))
        toolbar.barStyle = .black
        
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
        textView.keyboardAppearance = .dark
        textView.inputAccessoryView = toolbar
        textView.font = textStorage.highlightr.theme.codeFont
        setTextColor()
        placeholderView.addSubview(textView)
    }
    
    
    /// MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupTextView()
    }

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
            let errorAlert = UIAlertController(title: "Error opening file!", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        // Resize textView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Syntax coloring
        
        if let languagesForFile = languages[file.pathExtension.lowercased()] {
            if languagesForFile.count == 1 {
                language = languagesForFile[0]
                textStorage.language = language
            } else if languagesForFile.count > 1 {
                let chooseAlert = UIAlertController(title: "Choose language", message: "Highlight this file as: ", preferredStyle: .alert)
                
                for language in languagesForFile {
                    if highlightr!.supportedLanguages().contains(language) {
                        chooseAlert.addAction(UIAlertAction(title: language, style: .default, handler: { (_) in
                            self.language = language
                            self.textStorage.language = self.language
                        }))
                    }
                }
                
                chooseAlert.addAction(UIAlertAction(title: "None", style: .cancel, handler: nil))
                
                present(chooseAlert, animated: true, completion: nil)
            } else {
                textStorage.language = "swift"
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        func close() {
            if ConnectionManager.shared.saveFile != nil {
                ConnectionManager.shared.saveFile = nil
            }
            
        }
        
        // Ask for save the file
        let alert = UIAlertController(title: "Save changes?", message: "If you select Don't Save, all your changes will be erased!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Don't Save", style: .destructive, handler: { (_) in
            close()
        }))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (_) in
            if let navVC = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                navVC.pushViewController(self, animated: true, completion: {
                    self.save(true)
                    if ConnectionManager.shared.saveFile?.localFile == self.file.path {
                        try? FileManager.default.removeItem(at: self.file)
                    }
                })
            }
        }))
        
        do {
            // Check if file was modified
            let fileContent = try String.init(contentsOf: file)
            if textView.text != fileContent {
               UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
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
                        let activityVC = ActivityViewController(message: "Uploading")
                        self.present(activityVC, animated: true, completion: {
                            ConnectionManager.shared.filesSession?.sftp.writeContents(data, toFileAtPath: saveFile.remoteFile)
                            activityVC.dismiss(animated: true, completion: {
                                if let close = sender as? Bool {
                                    if close {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            })
                        })
                    } else {
                        if let close = sender as? Bool {
                            if close {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                    
                } else {
                    if let close = sender as? Bool {
                        if close {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
                
            } catch let error {
                let errorAlert = UIAlertController(title: "Error saving file!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }

    /// Insert tab into textView.
    @objc func insertTab() {
        textView.replace(textView.selectedTextRange!, withText: "\t")
    }
    
    /// Change editor's theme.
    @IBAction func changeTheme(_ sender: Any) {
        
        let wasFirstResponder = textView.isFirstResponder
        
        textView.resignFirstResponder()
        
        ActionSheetStringPicker.show(withTitle: "Select a theme", rows: textStorage.highlightr.availableThemes(), initialSelection: textStorage.highlightr.availableThemes().index(of: UserDefaults.standard.string(forKey: "editorTheme")!) ?? 0, doneBlock: { (_, _, theme) in
            
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
    
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
    }
    
    /// Resize `textView` will show keyboard.
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    /// Resize `textView` will hide keyboard.
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}
