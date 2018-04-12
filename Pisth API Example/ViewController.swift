// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Pisth_API
import Pisth_Shared

class ViewController: UIViewController {

    @IBOutlet weak var pisthAPTButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filename: UILabel!
    
    var data: Data?
    
    @IBAction func openPisthAPT(_ sender: Any) {
        
        // Open connection in Pisth APT
        if pisthAPT.canOpen {
            pisthAPT.open(connection: RemoteConnection(host: "coldg.ddns.net", username: "pisthtest", password: "pisth", name: "Pisth Test", path: "~", port: 22, useSFTP: false, os: "Raspbian") /* Connection to open */)
        }
    }
    
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
        pisth.importFile()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable button only if app can import file from Pisth
        importButton.isEnabled = pisth.canOpen
        
        // Enable button only if Pisth APT is installed
        pisthAPTButton.isEnabled = pisthAPT.canOpen
    }

}

