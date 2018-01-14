// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Highlightr

class EditTextViewController: UIViewController, UITextViewDelegate {
        
    @IBOutlet weak var textView: UITextView!
    
    var file: URL!
    
    // Syntax coloring variables
    var highlightr = Highlightr()
    var timer: Timer?
    var range: NSRange?
    var cursorPos: UITextRange?
    var pauseColoring = false
    private var language_: String?
    var language: String? {
        get {
            
            if language_ == nil {
                return nil
            }
            
            if highlightr!.supportedLanguages().contains(language_!) {
                return language_
            } else {
                return nil
            }
        }
        
        set {
            language_ = newValue
        }
    }
    
    // Setup textView
    func setupTextView() {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        let dismissKeyboard = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard(_:)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let tab = UIBarButtonItem(title: "↹", style: .plain, target: self, action: #selector(insertTab))
        
        let items = [tab, flexSpace, dismissKeyboard] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        textView.inputAccessoryView = toolbar
        textView.keyboardAppearance = .dark
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextView()
        
        // Theme
        highlightr?.setTheme(to: "paraiso-dark")
        textView.backgroundColor = highlightr?.theme.themeBackgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if timer == nil {
            title = file.lastPathComponent
            
            textView.delegate = self
            
            let languages = NSDictionary(contentsOf: Bundle.main.bundleURL.appendingPathComponent("langs.plist"))! as! [String:[String]] // List of languages associated by file extensions
            
            // Open file
            do {
                textView.text = try String(contentsOfFile: file.path)
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
            
            DispatchQueue.main.async {
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { (_) in
                    if self.textView.isFirstResponder {
                        self.highlight()
                    }
                })
            }
            
            if let languagesForFile = languages[file.pathExtension.lowercased()] {
                if languagesForFile.count == 1 {
                    language = languagesForFile[0]
                    self.highlight()
                } else if languagesForFile.count == 0 {
                    textView.backgroundColor = .clear
                    textView.textColor = .white
                    timer?.invalidate()
                } else {
                    let chooseAlert = UIAlertController(title: "Choose language", message: "Highlight this file as: ", preferredStyle: .alert)
                    
                    for language in languagesForFile {
                        if highlightr!.supportedLanguages().contains(language) {
                            chooseAlert.addAction(UIAlertAction(title: language, style: .default, handler: { (_) in
                                self.language = language.replacingOccurrences(of: "-", with: "")
                                self.highlight()
                            }))
                        }
                    }
                    
                    chooseAlert.addAction(UIAlertAction(title: "None", style: .cancel, handler: { (_) in
                        self.textView.backgroundColor = .clear
                        self.textView.textColor = .white
                        self.timer?.invalidate()
                    }))
                    
                    _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                        self.present(chooseAlert, animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        func close() {
            if ConnectionManager.shared.saveFile != nil {
                ConnectionManager.shared.saveFile = nil
            }
            
            timer?.invalidate()
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
                })
            }
        }))
        
        do {
            // Check if file was modified
            let fileContent = try String.init(contentsOf: file)
            if textView.text != fileContent {
               UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            } else {
                close()
            }
        } catch _ {
            close()
        }
    }
    
    func highlight() {
        
        if language == nil {
            return
        }
        
        if !self.pauseColoring {
            self.range = self.textView.selectedRange
            self.cursorPos = self.textView.selectedTextRange
            
            self.textView.attributedText = self.highlightr?.highlight(textView.text, as: language, fastRender: true)
            self.textView.selectedTextRange = self.cursorPos
            self.textView.scrollRangeToVisible(self.range!)
        } else {
            self.pauseColoring = false
        }
    }
    
    @IBAction func save(_ sender: Any) { // Save file
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
    
    @objc func insertTab() { // Insert tab into textView
        textView.replace(textView.selectedTextRange!, withText: "\t")
    }
    
    // MARK: Keyboard
    
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
    }
    
    // Resize textView
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
    
    
    // MARK: UITextViewDelegate
    
    // Pause coloring when write or change selection to prevent the editor from lagging
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.isFirstResponder {
            self.pauseColoring = true
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.isFirstResponder {
            self.pauseColoring = true
        }
    }
}
