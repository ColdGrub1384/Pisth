//
//  TextViewController.swift
//  Pisth
//
//  Created by Adrian on 26.12.17.
//

import UIKit
import Highlightr

class EditTextViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - EditTextViewController
    
    @IBOutlet weak var textView: UITextView!
    var dismissKeyboard: UIBarButtonItem!
    
    var file: URL!
    
    // Syntax coloring variables
    var highlightr = Highlightr()
    var timer: Timer?
    var range: NSRange?
    var cursorPos: UITextRange?
    var pauseColoring = false
    var language: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dismissKeyboard = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard(_:)))
        navigationItem.rightBarButtonItem = dismissKeyboard
        
        title = file.lastPathComponent
        
        textView.keyboardAppearance = .dark
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
        
        highlightr?.setTheme(to: "paraiso-dark")
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
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
    }
    
    func highlight() {
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
                            ConnectionManager.shared.session?.sftp.writeContents(data, toFileAtPath: saveFile.remoteFile)
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
    
    
    // MARK: Keyboard
    
    @objc func dismissKeyboard(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        sender.isEnabled = false
    }
    
    
    // Resize textView
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
        
        dismissKeyboard.isEnabled = true
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
        
        dismissKeyboard.isEnabled = false
    }
    
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        self.pauseColoring = true
    }
}
