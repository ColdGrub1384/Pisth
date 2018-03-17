// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import MessageUI

/// View controller to invite people to participate in the beta testing.
class BetaViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendRequest(_ sender: Any) {
        
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = self
        vc.setToRecipients(["adri_labbe@hotmail.com"])
        vc.setSubject("Pisth Beta Testing")
        vc.setMessageBody("""
        
        Device Model: \(UIDevice.current.modelName)
        iOS Version: \(UIDevice.current.systemVersion)
        
        """, isHTML: false)
        
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Mail compose view controller delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
