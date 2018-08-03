// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_Shared

/// A View controller for creating or modifiying a snippet.
class SnippetInfoViewController: UIViewController, UITextViewDelegate {
    
    /// The Text field containing the snippet's name.
    @IBOutlet weak var nameTextField: UITextField!
    
    /// The Text view containing the snippet.
    @IBOutlet weak var contentTextView: UITextView!
    
    /// The index of the snippet to edit.
    var index: Int?
    
    /// The list of snippets.
    var snippets: [Snippet] {
        
        get {
            guard let data = UserDefaults.standard.value(forKey: "snippets") as? Data else {
                return []
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Snippet] ?? []
        }
        
        set {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "snippets")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Save snippet and dismiss.
    @objc func save() {
        
        var snippets = self.snippets
        
        if let index = index {
            var i = 0
            for snippet in snippets {
                if i == index {
                    snippet.name = nameTextField.text ?? snippet.name
                    snippet.content = contentTextView.text
                    break
                }
                i += 0
            }
        } else {
            snippets.append(Snippet(name: nameTextField.text ?? "", content: contentTextView.text))
        }
        
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: snippets), forKey: "snippets")
        UserDefaults.standard.synchronize()
        
        dismiss(animated: true, completion: nil)
    }
    
    /// Dismiss.
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    /// Set bar button items and theme.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancel = UIBarButtonItem(title: Localizable.cancel, style: .plain, target: self, action: #selector(close))
        let done = UIBarButtonItem(title: Localizable.EditTextViewController.save, style: .done, target: self, action: #selector(save))
        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = done
        
        let theme = TerminalTheme.themes[UserDefaults.standard.string(forKey: "terminalTheme")!]
        contentTextView.backgroundColor = theme?.backgroundColor
        contentTextView.textColor = theme?.foregroundColor
    }
    
    /// Fill info.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let index = index, let snippetsRaw = UserDefaults.standard.value(forKey: "snippets") as? Data, let snippets = NSKeyedUnarchiver.unarchiveObject(with: snippetsRaw) as? [Snippet], snippets.indices.contains(index) {
            
            nameTextField.text = snippets[index].name
            contentTextView.text = snippets[index].content
            contentTextView.tag = 1
        }
    }
    
    // MARK: - Text view delegate
    
    /// Set `textView` content.
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 0 {
            textView.text = ""
            textView.tag = 1
        }
    }
}
