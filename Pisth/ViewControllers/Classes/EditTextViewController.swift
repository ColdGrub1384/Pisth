//
//  TextViewController.swift
//  Pisth
//
//  Created by Adrian on 26.12.17.
//

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
    var language: String?
    
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
        
        title = file.lastPathComponent
        
        textView.delegate = self
        
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
        
        highlight()
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                self.timer = timer
                if self.textView.isFirstResponder {
                    self.highlight()
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if ConnectionManager.shared.saveFile != nil {
            ConnectionManager.shared.saveFile = nil
        }
        
        timer?.invalidate()
    }
    
    func highlight() {
        
        if let file = file { // If the file is plain text, stop highlighting it
            if file.pathExtension == "txt" || file.pathExtension == "" {
                timer?.invalidate()
                
                textView.backgroundColor = .clear
                textView.textColor = .white
                
                return
            }
        }
        
        if !self.pauseColoring {
            self.range = self.textView.selectedRange
            self.cursorPos = self.textView.selectedTextRange
            
            self.textView.attributedText = self.highlightr?.highlight(self.textView.text, fastRender: true)
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
                            activityVC.dismiss(animated: true, completion: nil)
                        })
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
