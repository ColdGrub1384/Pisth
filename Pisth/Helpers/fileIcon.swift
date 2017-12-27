//
//  FileIcon.swift
//  Pisth
//
//  Created by Adrian on 27.12.17.
//

import UIKit

func fileIcon(forExtension extension_: String) -> UIImage {
    if let defaultIcon = UIImage(named: extension_.lowercased()) {
        return defaultIcon
    } else {
        return #imageLiteral(resourceName: "file")
    }
}

