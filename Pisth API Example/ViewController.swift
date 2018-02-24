// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_API

class ViewController: UIViewController {

    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filename: UILabel!
    
    var data: Data?
    
    @IBAction func share(_ sender: Any) {
        
        // Share file
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(filename.text!)
        _ = FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sender as? UIView
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func importFromPisth(_ sender: Any) {
        
        // Import file
        Pisth.shared.importFile()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable button only if app can import file from Pisth
        importButton.isEnabled = Pisth.shared.canOpen
    }

}

