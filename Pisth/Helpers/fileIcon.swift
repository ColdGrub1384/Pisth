// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Provide file icon by extension.
///
/// - Parameters:
///     - forExtension: Extension used to retrieve file icon.
///
/// - Returns: The file icon associated with the given extension, or the default file icon.
@available(*, deprecated, message: "Use UIImage.icon(forPathExtension:preferredSize:) instead.")
func fileIcon(forExtension extension_: String) -> UIImage {
    
    if let defaultIcon = UIImage(named: "File icons/"+extension_.lowercased()) {
        return defaultIcon
    } else {
        return #imageLiteral(resourceName: "File icons/file")
    }
}

